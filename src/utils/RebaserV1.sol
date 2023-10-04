// Thunderhead: https://github.com/thunderhead-labs


// Author(s)
// Addison Spiegel: https://addison.is
// Pierre Spiegel: https://pierre.wtf

pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../token/stFlip.sol";
import "../utils/BurnerV1.sol";
import "../utils/OutputV1.sol";
import "../utils/MinterV1.sol";
import "../mock/StateChainGateway.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

/**
 * @title Rebaser contract for stFLIP
 * @notice Will be called by an offchain service to set the rebase factor.
 * Has protections so the rebase can't be too large or small. Fees come from
 * rebases, there is a fee claim function to claim fees.
 */
contract RebaserV1 is Initializable, Ownership {

    uint256 constant TIME_IN_YEAR = 31536000;

    uint16 public aprThresholdBps;         // uint16 sufficient
    uint16 public slashThresholdBps;       // uint16 sufficient
    uint32 public lastRebaseTime;          // uint32 sufficient
    uint32 public rebaseInterval;          // uint32 sufficient
    uint80 public servicePendingFee;       // uint80-88 sufficient

    BurnerV1 public wrappedBurnerProxy;
    OutputV1 public wrappedOutputProxy;
    MinterV1 public wrappedMinterProxy;

    IERC20 public flip;
    stFlip public stflip;

    struct Operator {
        uint88 rewards;            // uint88 sufficient 
        uint80 pendingFee;         // uint80 sufficient
        uint88 slashCounter;       // uint88 sufficient
    }

    mapping(uint256 => Operator) public operators;

    event FeeClaim(address feeRecipient, uint256 amount, bool receivedFlip, uint256 operatorId);
    event RebaserRebase(uint256 apr, uint256 feeIncrement, uint256 previousSupply, uint256 newSupply);
    event GovRebase(uint256 apr, uint256 feeIncrement, uint256 previousSupply, uint256 newSupply);

    constructor () {
        _disableInitializers();
    }


    /**
     * @notice Initializes the contract
     * @param addresses The addresses of the contracts to use: flip, burnerProxy, gov, feeRecipient, manager, stflip, outputProxy
     * @param aprThresholdBps_ The amount of bps to set apr threshold to
     * @param rebaseInterval_ The amount of time in seconds between rebases
     */
    function initialize(address[8] calldata addresses, uint256 aprThresholdBps_, uint256 slashThresholdBps_, uint256 rebaseInterval_) initializer public {
        flip = IERC20(addresses[0]);
        wrappedBurnerProxy = BurnerV1(addresses[1]);
        
        __AccessControlDefaultAdminRules_init(0, addresses[2]);
        _grantRole(MANAGER_ROLE, addresses[2]);
        _grantRole(MANAGER_ROLE, addresses[4]);
        _grantRole(FEE_RECIPIENT_ROLE, addresses[3]);

        stflip = stFlip(addresses[5]);
        wrappedOutputProxy = OutputV1(addresses[6]);
        wrappedMinterProxy = MinterV1(addresses[7]);

        slashThresholdBps = SafeCast.toUint16(slashThresholdBps_);
        aprThresholdBps = SafeCast.toUint16(aprThresholdBps_);
        rebaseInterval = SafeCast.toUint32(rebaseInterval_);


        lastRebaseTime = SafeCast.toUint32(block.timestamp);

    }

    /** Sets the APR threshold in bps
     * @param aprThresholdBps_ The amount of bps to set apr threshold to
     * @dev If the rebase exceeds this APR, then the rebase will revert
     */
    function setAprThresholdBps(uint256 aprThresholdBps_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        aprThresholdBps = SafeCast.toUint16(aprThresholdBps_);
    }

    /** Sets slash threshold in bps
     * @param slashThresholdBps_ The number of bps to set slash threshold to
     * @dev If the supply decreases by this threshold, then the rebase will revert
     * @dev This is different from APR threshold because slashes would be much more serious
     */
    function setSlashThresholdBps(uint256 slashThresholdBps_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        slashThresholdBps = SafeCast.toUint16(slashThresholdBps_);
    }

    /** Sets minimum rebase interval
     * @param rebaseInterval_ The minimum unix time between rebases
     * @dev If a rebase occurs before this interval elapses, it will revert
     */
    function setRebaseInterval(uint256 rebaseInterval_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        rebaseInterval = SafeCast.toUint32(rebaseInterval_);
    }

    /** Calculates the new rebase factor based on the stateChainBalance and whether 
     * or not fee will be claimed
     * @param epoch The epoch number of the rebase
     * @param validatorBalances The balances of the state chain validators
     * @param addresses The addresses of the state chain validators
     * @param takeFee Whether or not to claim fee
     * @dev Ideally we could have an oracle report the `stateChainBalance` to the contract
     * but Chainlink and larger oracle networks do not support Chainflip yet. Its also
     * very expensive and still very centralized. So we instead rely on the manager which is 
     * an EOA to perform oracle reports. Manager will call this function with the `stateChainBalance`
     * and the following function will calculate what the new rebase factor will be including the onchain
     * balances in the output addess. If the supply change exceeds the APR or slash threshold, then the
     * rebase will revert, limiting the possible damage the EOA could commmit. We might disable `takeFee`
     * if there is a slash we need to make up for. Its also worth noting how `pendingFee` is a piece of the pool,
     * in the same way that pending burns are. 
     */
    function rebase (uint256 epoch, uint256[] calldata validatorBalances, bytes32[] calldata addresses, bool takeFee) external onlyRole(MANAGER_ROLE) {
        uint256 timeElapsed = block.timestamp - lastRebaseTime;
        require(timeElapsed >= rebaseInterval, "Rebaser: rebase too soon");
        require(validatorBalances.length == addresses.length, "Rebaser: length mismatch");

        (uint256 stateChainBalance, uint256 totalOperatorPendingFee_) = _updateOperators(validatorBalances, addresses, takeFee);
        uint256 currentSupply = stflip.totalSupply();

        uint256 newSupply = stateChainBalance + flip.balanceOf(address(wrappedOutputProxy)) - wrappedBurnerProxy.totalPendingBurns() - servicePendingFee - totalOperatorPendingFee_;
        uint256 apr = _validateSupplyChange(timeElapsed, currentSupply, newSupply);
        uint256 feeIncrement;
        
        // uint256 newRebaseFactor = newSupply * stflip.internalDecimals() / stflip.initSupply();
        stflip.setRebase(epoch, newSupply * stflip.internalDecimals() / stflip.initSupply(), rebaseInterval);
        lastRebaseTime = SafeCast.toUint32(block.timestamp);

        emit RebaserRebase(apr, feeIncrement, currentSupply, newSupply);
    }

    function _updateOperators(uint256[] calldata validatorBalances, bytes32[] calldata addresses, bool takeFee) internal returns (uint256, uint256) {
        uint256 stateChainBalance;
        uint256 totalOperatorPendingFee_;
        uint256 operatorId;

        uint256 operatorCount = wrappedOutputProxy.getOperatorCount();
        uint256[] memory operatorBalances = new uint256[](operatorCount);
        
        require(keccak256(abi.encodePacked(addresses)) == wrappedOutputProxy.validatorAddressHash(), "Rebaser: validator addresses do not match");
        require(validatorBalances.length == addresses.length, "Rebaser: length mismatch");

        for (uint i = 0; i < validatorBalances.length; i++) {            
            (operatorId, ) = wrappedOutputProxy.validators(addresses[i]);
            operatorBalances[operatorId] += validatorBalances[i];
            stateChainBalance += validatorBalances[i];
        }

            
        for (operatorId = 1; operatorId < operatorCount; operatorId++) {
            totalOperatorPendingFee_ += _updateOperator(operatorBalances[operatorId], operatorId, takeFee);
        }  

        return (stateChainBalance, totalOperatorPendingFee_);
    }

    function _updateOperator(uint256 operatorBalance, uint256 operatorId, bool takeFee) internal returns (uint256) {
        uint256 rewardIncrement;
        uint96 staked;
        uint96 unstaked;
        uint16 serviceFeeBps;
        uint16 validatorFeeBps;
        uint256 previousBalance;
        (staked,unstaked,serviceFeeBps, validatorFeeBps) = wrappedOutputProxy.getOperatorInfo(operatorId);

        uint256 slashCounter_ = operators[operatorId].slashCounter;
        // previousBalance = (staked - (unstaked - operators[operatorId].rewards)) - operators[operatorId].slashCounter;
        previousBalance = staked + operators[operatorId].rewards - unstaked - slashCounter_;

        if (operatorBalance >= previousBalance) {
            rewardIncrement = operatorBalance - previousBalance; // is rewards + or - ?
            if (rewardIncrement > slashCounter_) {
                
                if (slashCounter_ != 0) {
                    rewardIncrement -= slashCounter_;
                    operators[operatorId].slashCounter = 0; //consider combining this with the block above. is double writing zero to slashCounter gas efficinet
                }
                operators[operatorId].rewards += SafeCast.toUint80(rewardIncrement);
                if (takeFee == true) {
                    operators[operatorId].pendingFee += SafeCast.toUint80(rewardIncrement * validatorFeeBps  / 10000);
                    servicePendingFee += SafeCast.toUint80(rewardIncrement * serviceFeeBps / 10000);
                }
            } else {
                operators[operatorId].slashCounter -= SafeCast.toUint88(rewardIncrement);
            }
        } else {
            operators[operatorId].slashCounter += SafeCast.toUint88(previousBalance - operatorBalance);
        }
        return operators[operatorId].pendingFee;
    }

    function _validateSupplyChange(uint256 timeElapsed, uint256 currentSupply, uint256 newSupply) internal view returns (uint256) {
        uint256 apr;
        if (newSupply > currentSupply){
            apr = (newSupply * 10**18 / currentSupply - 10**18) * 10**18 / (timeElapsed * 10**18 / TIME_IN_YEAR) / (10**18/10000);
            // increase precision

            require(apr + 1 < aprThresholdBps, "Rebaser: apr too high");
        } else {
            require(10000 - (newSupply * 10000 / currentSupply) < slashThresholdBps, "Rebaser: supply decrease too high");
        }

        return apr;
    }

    /** 
     *  @notice Claims pending fees to the fee recipient in either stflip or flip
     *  @dev `pendingFee` is a piece of the pool. When fee is claimed in FLIP, the
     *  pool's decrease in FLIP aligns with the decrease in `pendingFee`. Similarly,
     *  when stFLIP is claimed, the increase in stFLIP supply corresponds to the decrease
     *  in `pendingFee`. When `max` is true, the entire `pendingFee` is claimed and the
     *  `amount` does not matter. 
     *  @param amount Amount of tokens to burn
     *  @param max Whether or not to claim all pending fees
     *  @param receiveFlip Whether or not to receive the fee in flip or stflip
     */
    function claimFee (uint256 amount, bool max, bool receiveFlip, uint256 operatorId) external {
        address manager;
        address feeRecipient;
        uint256 pendingFee = operators[operatorId].pendingFee;
        (,,,,,manager,feeRecipient,) = wrappedOutputProxy.operators(operatorId);
        
        require(max == true || amount <= pendingFee, "Rebaser: fee claim requested exceeds pending fees");
        require(msg.sender == feeRecipient || msg.sender == manager, "Rebaser: not fee recipient or manager");

        uint256 amountToClaim = max ? pendingFee : amount;

        if (receiveFlip == true) {
            flip.transferFrom(address(wrappedOutputProxy), msg.sender, amountToClaim);
        } else {
            wrappedMinterProxy.mintStflipFee(msg.sender, amountToClaim);
        }

        operators[operatorId].pendingFee -= SafeCast.toUint80(amountToClaim);

        emit FeeClaim(msg.sender, amountToClaim, receiveFlip, operatorId);
    }

    function claimServiceFee(uint256 amount, bool max, bool receiveFlip) external onlyRole(FEE_RECIPIENT_ROLE) {
        require(max == true || amount <= servicePendingFee, "Rebaser: fee claim requested exceeds pending fees");

        uint256 amountToClaim = max ? servicePendingFee : amount;

        if (receiveFlip == true) {
            flip.transferFrom(address(wrappedOutputProxy), msg.sender, amountToClaim);
        } else {
            wrappedMinterProxy.mintStflipFee(msg.sender, amountToClaim);
        }

        servicePendingFee -= SafeCast.toUint80(amountToClaim);

        emit FeeClaim(msg.sender, amountToClaim, receiveFlip, 0); // consider putting service Fee under operator id zero. consider implications though since all validators will have operator id of zero by default. 
    }

    function totalOperatorPendingFee() external view returns (uint256) {

        uint256 operatorCount = wrappedOutputProxy.getOperatorCount();
        uint256 totalOperatorPendingFee_;
        for (uint256 operatorId = 1; operatorId < operatorCount; operatorId++) {
            totalOperatorPendingFee_ += operators[operatorId].pendingFee;
        }

        return totalOperatorPendingFee_;
    }



}









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


/**
 * @title Rebaser contract for stFLIP
 * @notice Will be called by an offchain service to set the rebase factor.
 * Has protections so the rebase can't be too large or small. Fees come from
 * rebases, there is a fee claim function to claim fees.
 */
contract RebaserV1 is Initializable, Ownership {

    uint256 public feeBps;
    uint256 public aprThresholdBps;
    uint256 public lastRebaseTime;
    uint256 public slashThresholdBps;
    uint256 constant TIME_IN_YEAR = 31536000;
    uint256 public rebaseInterval;
    uint256 public servicePendingFee;
    uint256 public totalOperatorPendingFee;

    BurnerV1 public wrappedBurnerProxy;
    OutputV1 public wrappedOutputProxy;
    MinterV1 public wrappedMinterProxy;

    IERC20 public flip;
    stFlip public stflip;

    struct Operator {
        uint256 rewards;
        uint256 pendingFee;
    }

    Operator[] public operators;

    struct OutputOperator {
        string name;
        bool whitelisted;
        address manager;
        address feeRecipient;
        uint256 staked;
        uint256 unstaked;
        uint256 serviceFeeBps;
        uint256 validatorFeeBps;
    }

    event FeeClaim(address feeRecipient, uint256 amount, bool receivedFlip, uint256 operatorId);
    event RebaserRebase(uint256 apr, uint256 feeIncrement, uint256 previousSupply, uint256 newSupply);
    event GovRebase(uint256 apr, uint256 feeIncrement, uint256 previousSupply, uint256 newSupply);

    constructor () {
        _disableInitializers();
    }


    /**
     * @notice Initializes the contract
     * @param addresses The addresses of the contracts to use: flip, burnerProxy, gov, feeRecipient, manager, stflip, outputProxy
     * @param feeBps_ The amount of bps to set the fee to
     * @param aprThresholdBps_ The amount of bps to set apr threshold to
     * @param rebaseInterval_ The amount of time in seconds between rebases
     */
    function initialize(address[8] calldata addresses, uint256 feeBps_, uint256 aprThresholdBps_, uint256 slashThresholdBps_, uint256 rebaseInterval_) initializer public {
        flip = IERC20(addresses[0]);
        wrappedBurnerProxy = BurnerV1(addresses[1]);
        
        __AccessControlDefaultAdminRules_init(0, addresses[2]);
        _grantRole(MANAGER_ROLE, addresses[2]);
        _grantRole(MANAGER_ROLE, addresses[4]);
        _grantRole(FEE_RECIPIENT_ROLE, addresses[3]);

        stflip = stFlip(addresses[5]);
        wrappedOutputProxy = OutputV1(addresses[6]);
        wrappedMinterProxy = MinterV1(addresses[7]);
        
        feeBps = feeBps_;      
        slashThresholdBps = slashThresholdBps_;
        aprThresholdBps = aprThresholdBps_ ;
        rebaseInterval = rebaseInterval_;

        lastRebaseTime = block.timestamp;

    }

    /** Sets reward fee in bps, the percentage of rebase that will go to `pendingFee`
     * @param feeBps_ The amount of bps to set the fee to
     */
    function setFeeBps(uint256 feeBps_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        feeBps = feeBps_;
    }

    /** Sets the APR threshold in bps
     * @param aprThresholdBps_ The amount of bps to set apr threshold to
     * @dev If the rebase exceeds this APR, then the rebase will revert
     */
    function setAprThresholdBps(uint256 aprThresholdBps_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        aprThresholdBps = aprThresholdBps_;
    }

    /** Sets slash threshold in bps
     * @param slashThresholdBps_ The number of bps to set slash threshold to
     * @dev If the supply decreases by this threshold, then the rebase will revert
     * @dev This is different from APR threshold because slashes would be much more serious
     */
    function setSlashThresholdBps(uint256 slashThresholdBps_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        slashThresholdBps = slashThresholdBps_;
    }

    /** Sets minimum rebase interval
     * @param rebaseInterval_ The minimum unix time between rebases
     * @dev If a rebase occurs before this interval elapses, it will revert
     */
    function setRebaseInterval(uint256 rebaseInterval_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        rebaseInterval = rebaseInterval_;
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

        uint256 stateChainBalance = _updateOperator(validatorBalances, addresses, takeFee);

        uint256 currentSupply = stflip.totalSupply();

        uint256 onchainBalance = flip.balanceOf(address(wrappedOutputProxy));
        uint256 newSupply = stateChainBalance + onchainBalance - wrappedBurnerProxy.totalPendingBurns() - servicePendingFee - totalOperatorPendingFee;

        uint256 apr;
        uint256 feeIncrement;

        if (newSupply > currentSupply){
            apr = (newSupply * 10**18 / currentSupply - 10**18) * 10**18 / (timeElapsed * 10**18 / TIME_IN_YEAR) / (10**18/10000);

            require(apr + 1 < aprThresholdBps, "Rebaser: apr too high");
        } else {

            require(10000 - (newSupply * 10000 / currentSupply) < slashThresholdBps, "Rebaser: supply decrease too high");
        }
        
        // uint256 newRebaseFactor = newSupply * stflip.internalDecimals() / stflip.initSupply();
        stflip.setRebase(epoch, newSupply * stflip.internalDecimals() / stflip.initSupply());
        lastRebaseTime = block.timestamp;

        emit RebaserRebase(apr, feeIncrement, currentSupply, newSupply);
    }

    function _updateOperators(uint256[] calldata validatorBalances, bytes32[] calldata addresses, bool takeFee) internal returns (uint256) {
        uint256 stateChainBalance;
        uint256 operatorId;
        uint256 rewardIncrement;
        uint256 staked;
        uint256 unstaked;
        uint256 serviceFeeBps;
        uint256 validatorFeeBps;

        uint256[] memory operatorBalances;

        for (uint i = 0; i < validatorBalances.length; i++) {            
            (operatorId, ) = wrappedOutputProxy.validators(addresses[i]);
            operatorBalances[operatorId] += validatorBalances[i];
        }

        for (operatorId = 1; operatorId < wrappedOutputProxy.getOperatorCount(); operatorId++) {

            (,,,,staked,unstaked,serviceFeeBps, validatorFeeBps) = wrappedOutputProxy.operators(operatorId);

            stateChainBalance += operatorBalances[operatorId];

            rewardIncrement = operatorBalances[operatorId] - (staked - (unstaked - operators[operatorId].rewards)); // is rewards + or - ?
// TODO, add slashing here. add another item in the struct and add that into rewardIncrement calculation. If reward increment < 0 then increment slash instead.
// rewards earned during a rebase interval in which there was a slashing will not reward the operator. if we do want to make operator earn rewards to cover their slashings, then we have rewardincrement decremetn slashcounter until it is zero
            operators[operatorId].rewards += rewardIncrement;

            if (takeFee == true) {
                operators[operatorId].pendingFee += rewardIncrement * validatorFeeBps  / 10000;
                servicePendingFee += rewardIncrement * serviceFeeBps / 10000;
                totalOperatorPendingFee += rewardIncrement * validatorFeeBps / 10000;
            }
        }

        return stateChainBalance;
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
        (,,manager,feeRecipient,,,,) = wrappedOutputProxy.operators(operatorId);
        
        require(max == true || amount <= pendingFee, "Rebaser: fee claim requested exceeds pending fees");
        require(msg.sender == feeRecipient || msg.sender == manager, "Rebaser: not fee recipient or manager");

        uint256 amountToClaim = max ? pendingFee : amount;

        if (receiveFlip == true) {
            flip.transferFrom(address(wrappedOutputProxy), msg.sender, amountToClaim);
        } else {
            wrappedMinterProxy.mintStflipFee(msg.sender, amountToClaim);
        }

        operators[operatorId].pendingFee -= amountToClaim;
        totalOperatorPendingFee -= amountToClaim;

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

        servicePendingFee -= amountToClaim;

        emit FeeClaim(msg.sender, amountToClaim, receiveFlip, 0); // consider putting service Fee under operator id zero. consider implications though since all validators will have operator id of zero by default. 
    }



}









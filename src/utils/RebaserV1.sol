pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../token/stFlip.sol";
import "../utils/BurnerV1.sol";
import "../utils/OutputV1.sol";
import "../utils/MinterV1.sol";
import "../mock/StateChainGateway.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "forge-std/console.sol";


contract RebaserV1 is Initializable {
    using SafeMath for uint256;

    address public gov;
    address public pendingGov;
    address public feeRecipient;
    address public manager;

    uint256 public feeBps;
    uint256 public aprThresholdBps;
    uint256 public lastRebaseTime;
    uint256 public slashThresholdBps;
    uint256 constant TIME_IN_YEAR = 31536000;
    uint256 public rebaseInterval;
    uint256 public pendingFee;

    BurnerV1 public wrappedBurnerProxy;
    OutputV1 public wrappedOutputProxy;
    MinterV1 public wrappedMinterProxy;

    IERC20 public flip;
    stFlip public stflip;

    event FeeClaim(address feeRecipient, uint256 amount, bool receivedFlip);
    event RebaserRebase(uint256 apr, uint256 feeIncrement, uint256 previousSupply, uint256 newSupply);
    event GovRebase(uint256 apr, uint256 feeIncrement, uint256 previousSupply, uint256 newSupply);

    constructor () {
        _disableInitializers();
    }

    function initialize(
                        address[8] calldata addresses,
                        // address flip_,
                        // address burnerProxy_, 
                        // address gov_,  
                        // address feeRecipient_, 
                        // address manager_, 
                        // address stflip_,
                        // address outputProxy_
                        uint256 feeBps_, 
                        uint256 aprThresholdBps_,
                        uint256 slashThresholdBps_,
                        uint256 rebaseInterval_
                        ) initializer public {
        flip = IERC20(addresses[0]);
        wrappedBurnerProxy = BurnerV1(addresses[1]);
        gov = addresses[2];
        feeRecipient = addresses[3];
        manager = addresses[4];
        stflip = stFlip(addresses[5]);
        wrappedOutputProxy = OutputV1(addresses[6]);
        wrappedMinterProxy = MinterV1(addresses[7]);
        
        
        feeBps = feeBps_;      
        slashThresholdBps = slashThresholdBps_;
        aprThresholdBps = aprThresholdBps_ ;
        rebaseInterval = rebaseInterval_;

        lastRebaseTime = block.timestamp;

      

    }

    /**
     * @notice Event emitted when pendingGov is changed
     */
    event NewPendingGov(address oldPendingGov, address newPendingGov);

    /**
     * @notice Event emitted when gov is changed
     */
    event NewGov(address oldGov, address newGov);

    /**
     * @notice Tokens burned event
     */
    event Burn(uint256 amount, uint256 burn_id);

    // Modifiers
    modifier onlyGov() {
        require(msg.sender == gov, "Output: not gov");
        _;
    }

    /** @notice sets the pendingGov
     * @param pendingGov_ The address of the rebaser contract to use for authentication.
     */
    function _setPendingGov(address pendingGov_) external onlyGov {
        address oldPendingGov = pendingGov;
        pendingGov = pendingGov_;
        emit NewPendingGov(oldPendingGov, pendingGov_);
    }

    /** @notice lets msg.sender accept governance
     *
     */
    function _acceptGov() external {
        require(msg.sender == pendingGov, "!pending");
        address oldGov = gov;
        gov = pendingGov;
        pendingGov = address(0);
        emit NewGov(oldGov, gov);
    }

    modifier onlyManager() {
        require(msg.sender == manager || msg.sender == gov, "Rebaser: not manager or gov");
        _;
    }

    function setManager(address manager_) external onlyGov {
        manager = manager_;
    }

    function setFeeRecipient(address feeRecipient_) external onlyGov {
        feeRecipient = feeRecipient_;
    }

    function setFeeBps(uint256 feeBps_) external onlyGov {
        feeBps = feeBps_;
    }

    function setAprThresholdBps(uint256 aprThresholdBps_) external onlyGov {
        aprThresholdBps = aprThresholdBps_;
    }

    function setSlashThresholdBps(uint256 slashThresholdBps_) external onlyGov {
        slashThresholdBps = slashThresholdBps_;
    }

    function rebase (uint256 epoch, uint256 stateChainBalance, bool takeFee) external onlyManager {
        uint256 timeElapsed = block.timestamp - lastRebaseTime;
        require(timeElapsed >= rebaseInterval, "Rebaser: rebase too soon");

        uint256 currentSupply = stflip.totalSupply();
        uint256 pendingBurns = wrappedBurnerProxy.totalPendingBurns();

        uint256 onchainBalance = flip.balanceOf(address(wrappedOutputProxy));
        uint256 newSupply = stateChainBalance + onchainBalance - pendingBurns - pendingFee;

        uint256 apr;
        uint256 feeIncrement;

        if (newSupply > currentSupply){
            apr = (newSupply * 10**18 / currentSupply - 10**18) * 10**18 / (timeElapsed * 10**18 / TIME_IN_YEAR) / (10**18/10000);

            require(apr + 1 < aprThresholdBps, "Rebaser: apr too high");
            if (takeFee == true) {
                feeIncrement = (newSupply - currentSupply) * feeBps / 10000;
                pendingFee += feeIncrement;
                newSupply -= feeIncrement;
            } 
        } else {

            require(10000 - (newSupply * 10000 / currentSupply) < slashThresholdBps, "Rebaser: supply decrease too high");
        }
        
        uint256 newRebaseFactor = newSupply * stflip.internalDecimals() / stflip.initSupply();
        stflip.setRebase(epoch, newRebaseFactor);
        lastRebaseTime = block.timestamp;

        emit RebaserRebase(apr, feeIncrement, currentSupply, newSupply);
    }

    function forceRebase(uint256 epoch, uint256 stateChainBalance, bool takeFee) external onlyGov {
        uint256 timeElapsed = block.timestamp - lastRebaseTime;

        uint256 currentSupply = stflip.totalSupply();
        uint256 pendingBurns = wrappedBurnerProxy.totalPendingBurns();

        uint256 onchainBalance = flip.balanceOf(address(wrappedOutputProxy));
        uint256 newSupply = stateChainBalance + onchainBalance - pendingBurns - pendingFee;

        uint256 apr;
        uint256 feeIncrement;

        if (newSupply > currentSupply){
            apr = (newSupply * 10**18 / currentSupply - 10**18) * 10**18 / (timeElapsed * 10**18 / TIME_IN_YEAR) / (10**18/10000);

            if (takeFee == true) {
                feeIncrement = (newSupply - currentSupply) * feeBps / 10000;
                pendingFee += feeIncrement;
                newSupply -= feeIncrement;
            } 
        } 
        
        uint256 newRebaseFactor = newSupply * stflip.internalDecimals() / stflip.initSupply();
        stflip.setRebase(epoch, newRebaseFactor);
        lastRebaseTime = block.timestamp;

        emit GovRebase(apr, feeIncrement, currentSupply, newSupply);
    }


    function claimFee (uint256 amount, bool max, bool receiveFlip) external onlyManager {
        require (max == true || amount <= pendingFee, "Rebaser: fee claim requested exceeds pending fees");

        uint256 amountToClaim = max ? pendingFee : amount;

        if (receiveFlip == true) {
            flip.transferFrom(address(wrappedOutputProxy), feeRecipient, amountToClaim);
        } else {
            wrappedMinterProxy.mintStflipFee(feeRecipient, amountToClaim);
        }

        pendingFee -= amountToClaim;

        emit FeeClaim(feeRecipient, amountToClaim, receiveFlip);
    }

    function setRebaseInterval(uint256 rebaseInterval_) external onlyGov {
        rebaseInterval = rebaseInterval_;
    }
}









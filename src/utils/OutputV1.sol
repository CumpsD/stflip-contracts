pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../token/stFlip.sol";
import "../utils/BurnerV1.sol";
import "../mock/StateChainGateway.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";


contract OutputV1 is Initializable {
    using SafeMath for uint256;

    address public gov;
    address public pendingGov;
    address public feeRecipient;
    address public manager;
    address public rebaser;

    uint256 public feeBps;

    mapping (bytes32 => uint8) public validators;

    StateChainGateway public stateChainGateway;
    BurnerV1 public wrappedBurnerProxy;
    IERC20 public flip;

    event Sweep(address feeRecipient, uint256 rewards, uint256 fee);

    constructor () {
        _disableInitializers();
    }

    function initialize(address flip_,
                        address burnerProxy_, 
                        address gov_,  
                        address feeRecipient_, 
                        address manager_, 
                        uint256 feeBps_, 
                        address stateChainGateway_,
                        address rebaser_) initializer public {
        flip = IERC20(flip_);
        wrappedBurnerProxy = BurnerV1(burnerProxy_);
        gov = gov_;
        feeRecipient = feeRecipient_;
        manager = manager_;
        feeBps = feeBps_;
        stateChainGateway = StateChainGateway(stateChainGateway_);
        
        flip.approve(address(rebaser_), 2**256-1);
        flip.approve(address(wrappedBurnerProxy), 2**256 - 1);
        flip.approve(address(stateChainGateway), 2**256 - 1);

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
        require(msg.sender == manager || msg.sender == gov, "Output: not manager or gov");
        _;
    }

    function setManager(address manager_) external onlyGov {
        manager = manager_;
    }

    function setFeeRecipient(address feeRecipient_) external onlyGov {
        feeRecipient = feeRecipient_;
    }

    function setFeeBps(uint8 feeBps_) external onlyGov {
        feeBps = feeBps_;
    }

    function addValidators(bytes32[] calldata addresses) external onlyGov {
        for (uint256 i = 0; i < addresses.length; i++) {
            validators[addresses[i]] = 1;
        }
    }

    function removeValidators(bytes32[] calldata addresses) external onlyGov {
        for (uint256 i = 0; i < addresses.length; i++) {
            delete validators[addresses[i]];
        }
    }

    function fundValidators(bytes32[] calldata addresses, uint256[] calldata amounts) external onlyManager{
        require(addresses.length == amounts.length, "lengths must match");
        for (uint i = 0; i < addresses.length; i++) {
            require(validators[addresses[i]] == 1, "Output: address not added");
            stateChainGateway.fundStateChainAccount(addresses[i], amounts[i]);
        }
    }

    function redeemValidators(bytes32[] calldata addresses) external onlyManager {
        for (uint i = 0; i < addresses.length; i++) {
            stateChainGateway.executeRedemption(addresses[i]);
        }
    }

}









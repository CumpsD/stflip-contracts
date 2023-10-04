// Thunderhead: https://github.com/thunderhead-labs


// Author(s)
// Addison Spiegel: https://addison.is
// Pierre Spiegel: https://pierre.wtf

pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../token/stFlip.sol";
import "../utils/BurnerV1.sol";
import "../mock/StateChainGateway.sol";
import "../utils/Ownership.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "forge-std/console.sol";
/**
 * @title Output contract for stFLIP
 * @notice Will hold all unstaked FLIP. Can stake/unstake to
 * whitelisted validators.
 */
contract OutputV1 is Initializable, Ownership {

    StateChainGateway public stateChainGateway;
    BurnerV1 public wrappedBurnerProxy;
    IERC20 public flip;

    struct Validator {
        uint256 operatorId;
        bool whitelisted;
    }

    struct Operator {
        uint256 staked;          // uint88 sufficient
        uint256 unstaked;        // uint88 sufficient
        uint256 serviceFeeBps;   // uint16 sufficient
        uint256 validatorFeeBps; // uint16 sufficient
        string name;
        bool whitelisted;
        address manager;
        address feeRecipient;
    }

    mapping (bytes32 => Validator) public validators;
    bytes32[] public validatorAddresses;
    bytes32 public validatorAddressHash;
    Operator[] public operators;

    constructor () {
        _disableInitializers();
    }


    function initialize(address flip_, address burnerProxy_, address gov_,  address manager_, address stateChainGateway_,address rebaser_) initializer public {
        flip = IERC20(flip_);
        wrappedBurnerProxy = BurnerV1(burnerProxy_);

        __AccessControlDefaultAdminRules_init(0, gov_);
        _grantRole(MANAGER_ROLE, gov_);
        _grantRole(MANAGER_ROLE, manager_);

        stateChainGateway = StateChainGateway(stateChainGateway_);
        
        flip.approve(address(rebaser_), 2**256-1);
        flip.approve(address(wrappedBurnerProxy), 2**256 - 1);
        flip.approve(address(stateChainGateway), 2**256 - 1);
        Operator memory operator = Operator(0, 0, 0, 0,"null", false, gov_, gov_);
        operators.push(operator);
    }

    /** Adds validators so that they can be staked to
     * @param addresses The list of addresses to add to the map
     * @dev it should be ensured prior to adding validators to the map
     * that there was a state chain transaction submitted that sets the
     * withdrawal address to the output address to ensure non-custodial
     */
    function addValidators(bytes32[] calldata addresses, uint256 operatorId) external {
        require(operators[operatorId].manager == msg.sender, "Output: not manager of operator");
        require(operators[operatorId].whitelisted == true, "Output: operator not whitelisted");
        require(operatorId != 0, "Output: cannot add to null operator");
        for (uint256 i = 0; i < addresses.length; i++) {
            require(validators[addresses[i]].operatorId == 0, "Output: validator already added");
            validators[addresses[i]].operatorId = operatorId;
            validators[addresses[i]].whitelisted = false;
            validatorAddresses.push(addresses[i]);
        }

        validatorAddressHash = keccak256(abi.encodePacked(validatorAddresses));
    }

    function setValidatorsWhitelist(bytes32[] calldata addresses, bool status) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < addresses.length; i++) {
            validators[addresses[i]].whitelisted = status;
        }
    }

    function addOperator(address manager, string calldata name, uint256 serviceFeeBps, uint256 validatorFeeBps) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(serviceFeeBps + validatorFeeBps <= 10000, "Output: fees must be less than 100%");
        Operator memory operator = Operator(0, 0, serviceFeeBps, validatorFeeBps,name, true, manager, manager);
        operators.push(operator);
    }

    /** Funds state chain accounts 
     * @param addresses The list of Chainflip validator addresses to fund (hex version)
     * @param amounts The list of amounts to fund each address with
     * @dev Only addresses in the `validators` map can be funded. 
     */
    function fundValidators(bytes32[] calldata addresses, uint256[] calldata amounts) external onlyRole(MANAGER_ROLE) {
        require(addresses.length == amounts.length, "lengths must match");

        Validator memory validator;
        for (uint i = 0; i < addresses.length; i++) {
            validator = validators[addresses[i]];
            require(validator.whitelisted == true, "Output: validator not whitelisted");
            operators[validator.operatorId].staked += amounts[i];
            stateChainGateway.fundStateChainAccount(addresses[i], amounts[i]);
        }
    }

    /** Redeems funds from state chain accounts
     * @param addresses The list of Chainflip validator to redeem
     * @dev The redemptions must be first generated by the validators
     * on the Chainflip side
     */
    function redeemValidators(bytes32[] calldata addresses) external onlyRole(MANAGER_ROLE) {
        uint256 amount;
        for (uint i = 0; i < addresses.length; i++) {
            amount = stateChainGateway.executeRedemption(addresses[i]);
            operators[validators[addresses[i]].operatorId].unstaked += amount;
        }
    }

    function getValidators() external view returns (bytes32[] memory) {
        return validatorAddresses;
    }

    function computeValidatorHash(bytes32[] calldata addresses) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(addresses));
    }

    function getOperatorCount() external view returns (uint256) {
        return operators.length;
    }

}


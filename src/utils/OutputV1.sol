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
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

/**
 * @title Output contract for stFLIP
 * @notice Will hold all unstaked FLIP. Can stake/unstake to
 * whitelisted validators.
 */
contract OutputV1 is Initializable, Ownership {

    StateChainGateway public stateChainGateway; // StateChainGateway where FLIP goes for staking and comes from during unstaking
    IERC20 public flip;

    struct Validator {
        uint8 operatorId;          // the operator id of this validator
        bool whitelisted;          // determines whether staking to this address is allowed
    }

    struct Operator {
        uint96 staked;             // cumulative amount of FLIP staked to this operator
        uint96 unstaked;           // cumulative amount of FLIP unstaked from this operator
        uint16 serviceFeeBps;      // percentage of rewards generated that go to the service
        uint16 validatorFeeBps;    // percentage of rewards generated that go to the operator
        bool whitelisted;          // whether or not this operator is whitelisted
        address manager;           // the operator controlled address that can add validators
        address feeRecipient;      // the address that receives the validator fee. This can be the manager - it is just for additional granularity.
        string name;               // the operators name 
    }   

    mapping (bytes32 => Validator) public validators;  
    bytes32[] public validatorAddresses;
    bytes32 public validatorAddressHash;
    Operator[] public operators;

    constructor () {
        _disableInitializers();
    }

    /**
     * 
     * @param flip_ The FLIP token address
     * @param burnerProxy_ Burner proxy address
     * @param gov_ The gov address
     * @param manager_ The manager address
     * @param stateChainGateway_ Statechain gateway address 
     * @param rebaser_ Rebaser contract address
     */
    function initialize(address flip_, address burnerProxy_, address gov_,  address manager_, address stateChainGateway_,address rebaser_) initializer public {
        flip = IERC20(flip_);

        __AccessControlDefaultAdminRules_init(0, gov_);
        _grantRole(MANAGER_ROLE, gov_);
        _grantRole(MANAGER_ROLE, manager_);

        stateChainGateway = StateChainGateway(stateChainGateway_);
        
        flip.approve(address(rebaser_), 2**256-1);
        flip.approve(address(burnerProxy_), 2**256 - 1);
        flip.approve(address(stateChainGateway), 2**256 - 1);
        Operator memory operator = Operator(0, 0, 0, 0,false, gov_, gov_,"null");
        operators.push(operator);
    }

    /** Adds validators so that they can be staked to
     * @param addresses The list of addresses to add to the map
     * @param operatorId the operator they should be added for
     * @dev Operators can add addresses to their list of validators
     * from their manager address. These addresses will not be stakeable initially.
     */
    function addValidators(bytes32[] calldata addresses, uint256 operatorId) external {
        require(operators[operatorId].manager == msg.sender, "Output: not manager of operator");
        require(operators[operatorId].whitelisted == true, "Output: operator not whitelisted");
        require(operatorId != 0, "Output: cannot add to null operator");
        for (uint256 i = 0; i < addresses.length; i++) {
            require(validators[addresses[i]].operatorId == 0, "Output: validator already added");
            validators[addresses[i]].operatorId = SafeCast.toUint8(operatorId);
            validators[addresses[i]].whitelisted = false;
            validatorAddresses.push(addresses[i]);
        }

        validatorAddressHash = keccak256(abi.encodePacked(validatorAddresses));
    }

    /**
     * Whitelists specified validator addresses
     * @param addresses The list of addresses to whitelist
     * @param status The whitelist status to set
     * @dev We don't automatically whitelist validators when operators add
     * them. After they have been added, governance ensures that the withdrawal
     * address for those addresses has been locked to this output contract. Once
     * that has been confirmed then they can be whitelisted. 
     */
    function setValidatorsWhitelist(bytes32[] calldata addresses, bool status) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < addresses.length; i++) {
            validators[addresses[i]].whitelisted = status;
        }
    }

    /**
     * Adds an operator to the list of operators
     * @param manager The manager address
     * @param name The operator name
     * @param serviceFeeBps The percentage of rewards generated that will go to the service
     * @param validatorFeeBps The percentage of the rewards generated that will go to the validator
     * @dev Initially this will just be Thunderhead team-ran validators, after we get going we will
     * put other operators through an onboarding process similar to Lido's. After vetting and identifying
     * the best operators governance can whitelist them. 
     */
    function addOperator(address manager, string calldata name, uint256 serviceFeeBps, uint256 validatorFeeBps) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(serviceFeeBps + validatorFeeBps <= 10000, "Output: fees must be less than 100%");
        Operator memory operator = Operator(0, 0, SafeCast.toUint16(serviceFeeBps), SafeCast.toUint16(validatorFeeBps),true, manager, manager,name);
        operators.push(operator);
    }

    /** Funds state chain accounts 
     * @param addresses The list of Chainflip validator addresses to fund (hex version)
     * @param amounts The list of amounts to fund each address with
     * @dev Only addresses in the `validators` map can be funded. An offchain service known
     * as the fund manager handles this. Chainflip's staking mechanics are complicated because
     * there is a fixed 150 validators and the set is determined via a staking auction. Each
     * auction cycle (every 30 days), we ensure that the FLIP is distributed across as many
     * validators as possible.
     */
    function fundValidators(bytes32[] calldata addresses, uint256[] calldata amounts) external onlyRole(MANAGER_ROLE) {
        require(addresses.length == amounts.length, "lengths must match");

        Validator memory validator;
        for (uint i = 0; i < addresses.length; i++) {
            validator = validators[addresses[i]];
            require(validator.whitelisted == true, "Output: validator not whitelisted");
            operators[validator.operatorId].staked += SafeCast.toUint96(amounts[i]);
            stateChainGateway.fundStateChainAccount(addresses[i], amounts[i]);
        }
    }

    /** Redeems funds from state chain accounts
     * @param addresses The list of Chainflip validator to redeem
     * @dev The redemptions must be first generated by the validators
     * on the Chainflip side, ensuring that a redemption executor address was specified.
     * After this, the chainflip network will call registerRedemption on the StateChainGateway 
     * to make the redemption eligible to be claimed. Only the output contract will be able to
     * execute the redemption
     */
    function redeemValidators(bytes32[] calldata addresses) external onlyRole(MANAGER_ROLE) {
        uint256 amount;
        for (uint i = 0; i < addresses.length; i++) {
            amount = stateChainGateway.executeRedemption(addresses[i]);
            operators[validators[addresses[i]].operatorId].unstaked += SafeCast.toUint96(amount);
        }
    }

    /**
     * Return all validator addresses
     */
    function getValidators() external view returns (bytes32[] memory) {
        return validatorAddresses;
    }

    /**
     * Helper to hash the addresses offchain
     * @param addresses Validator addresses to hash
     */
    function computeValidatorHash(bytes32[] calldata addresses) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(addresses));
    }

    /**
     * Get number of all operators
     */
    function getOperatorCount() external view returns (uint256) {
        return operators.length;
    }

    /**
     * Returns relevant operator information
     * @param id ID of relevant operator
     * @return Operator staked counter
     * @return Operator unstaked counter
     * @return Operator service fee 
     * @return Operator validator fee
     * @dev Used for gas efficiency by the Rebaser contract since
     * the other information in the Operator struct is not relevant
     */
    function getOperatorInfo(uint256 id) external view returns (uint96, uint96, uint16, uint16) {
        return (operators[id].staked, operators[id].unstaked, operators[id].serviceFeeBps, operators[id].validatorFeeBps);
    }


    /**
     * Gets validator information
     * @param addresses Addresses of relevant validators
     * @return Operator ids of all the inputted addresses
     * @return Number of operators
     * @return Current validatorAddressHash
     * @dev Returns all this data in one call for gas efficiency
     * during the rebase calculation
     */
    function getValidatorInfo(bytes32[] calldata addresses) external view returns (uint256[] memory, uint256, bytes32) {
        uint256[] memory ids = new uint256[](addresses.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            ids[i] = validators[addresses[i]].operatorId;
        }
        return (ids, operators.length, validatorAddressHash);
    }

}


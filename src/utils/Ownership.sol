pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/AccessControlDefaultAdminRulesUpgradeable.sol";

contract Ownership is AccessControlDefaultAdminRulesUpgradeable {
    bytes32 public constant GOVERNER_ROLE = keccak256("GOVERNER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant FEE_RECIPIENT_ROLE = keccak256("FEE_RECIPIENT_ROLE");
    bytes32 public constant REBASER_ROLE = keccak256("REBASER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");


}









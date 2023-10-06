// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;


import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


// Storage for a YAM token
contract TokenStorage {

    /**
     * @notice EIP-20 token name for this token
     */
    string public name;

    /**
     * @notice EIP-20 token symbol for this token
     */
    string public symbol;

    /**
     * @notice EIP-20 token decimals for this token
     */
    uint8 public decimals;

    /**
     * @notice Whether the contract is frozen
     */
    bool public frozen;

    /**
     * @notice Internal decimals used to handle scaling factor
     */
    uint256 public constant internalDecimals = 10**24;

    /**
     * @notice Used for percentage maths
     */
    uint256 public constant BASE = 10**18;

    /**
     * @notice Map of token allowances
     */
    mapping (address => mapping (address => uint256)) internal _allowedFragments;

    /**
     * @notice The last timestamp that `setRebase` was called
     * @dev Set to uint32 for scaling factor calculations to use 1 ssload
     */
    uint32 public lastRebaseTimestamp;

    /**
     * @notice The end of the current rebase increase interval
     * @dev Set to uint32 for scaling factor calculations to use 1 ssload
     */
    uint32 public rebaseIntervalEnd;

    /**
     * @notice The scaling factor at the time of `lastRebaseTimestamp`
     * @dev Set to uint96 for scaling factor calculations to use 1 ssload
     */
    uint96 public previousYamScalingFactor;

    /**
     * @notice The scaling factor at `rebaseIntervalEnd`
     * @dev Set to uint96 for scaling factor calculations to use 1 ssload
     */
    uint96 public nextYamScalingFactor;

    uint256[45] private __gap;
}
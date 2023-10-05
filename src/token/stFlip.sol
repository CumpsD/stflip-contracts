// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.7;

import "./tStorage.sol";
import "../utils/Ownership.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/governance/utils/VotesUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

contract stFlip is Initializable, Ownership, TokenStorage, VotesUpgradeable {

    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Event emitted when tokens are rebased
     */
    event Rebase(uint256 epoch, uint256 prevYamsScalingFactor, uint256 newYamsScalingFactor, uint256 rebaseInterval);

    /* - ERC20 Events - */

    /**
     * @notice EIP20 Transfer event
     */
    event Transfer(address indexed from, address indexed to, uint amount);

    /**
     * @notice EIP20 Approval event
     */
    event Approval(address indexed owner, address indexed spender, uint amount);

    /* - Extra Events - */
    /**
     * @notice Tokens minted event
     */
    event Mint(address to, uint256 amount);

    /**
     * @notice Tokens burned event
     */
    event Burn(address from, uint256 amount, address refundee);

    // Modifiers
    modifier notFrozen() {
        require(frozen==false, "frozen");
        _;
    }
    
    /**
    * @notice Initializes the contract name, symbol, and decimals
    * @dev Limited to onlyGov modifier
    */
    function initialize(string memory name_, string memory symbol_, uint8 decimals_, address gov_, uint256 initialSupply_) initializer public {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;

        previousYamScalingFactor = SafeCast.toUint96(BASE);
        nextYamScalingFactor = SafeCast.toUint96(BASE);
        rebaseIntervalEnd = SafeCast.toUint32(block.timestamp);
        lastRebaseTimestamp = SafeCast.toUint32(block.timestamp);

        _transferVotingUnits(address(0), gov_, _fragmentToYam(initialSupply_));
        __AccessControlDefaultAdminRules_init(0, gov_);
        _grantRole(REBASER_ROLE, gov_);
        _grantRole(MINTER_ROLE, gov_);
    }


    /**
    * @notice Computes the current max scaling factor
    */
    function maxScalingFactor() external view returns (uint256) {
        return _maxScalingFactor();
    }

    function _maxScalingFactor() internal view returns (uint256) {
        // scaling factor can only go up to 2**256-1 = initSupply * yamsScalingFactor
        // this is used to check if yamsScalingFactor will be too high to compute balances when rebasing.
        return type(uint).max / _getTotalSupply();
    }

    /**
    * @notice Freezes any user transfers of the contract
    * @dev Limited to onlyGov modifier
    */
    function freeze(bool status) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        frozen = status;
        return true;
    }

    /**
    * @notice Mints new tokens, increasing totalSupply, initSupply, and a users balance.
    * @dev Limited to onlyMinter modifier
    */
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) returns (bool) {
        _mint(to, amount);
        return true;
    }

    function _mint(address to, uint256 amount) internal {

        _transfer(address(0), to, amount);
        // make sure the mint didnt push maxScalingFactor too low
        require(nextYamScalingFactor <= _maxScalingFactor(), "max scaling factor too low");

        emit Mint(to, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal {
        // underlying balance is stored in yams, so divide by current scaling factor
        uint256 yamValue = _fragmentToYam(amount);

        // decrease from
        _transferVotingUnits(from, to, yamValue);

        emit Transfer(from, to, amount);
    }
    /* - ERC20 functionality - */

    /**
    * @dev Transfer tokens to a specified address.
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    * @return True on success, false otherwise.
    */
    function transfer(address to, uint256 value) external notFrozen returns (bool) {
        // underlying balance is stored in yams, so divide by current scaling factor

        // note, this means as scaling factor grows, dust will be untransferrable.
        // minimum transfer value == yamsScalingFactor / 1e24;

        // get amount in underlying
        uint256 yamValue = _fragmentToYam(value);

        _transferVotingUnits(msg.sender, to, yamValue);

        emit Transfer(msg.sender, to, value);

        return true;
    }

    function burn(uint256 value, address refundee) external notFrozen onlyRole(BURNER_ROLE) returns (bool) {
        _burn(value, refundee);
        return true;
    }

    function _burn(uint256 value, address refundee) internal {
        // underlying balance is stored in yams, so divide by current scaling factor

        // note, this means as scaling factor grows, dust will be untransferrable.
        // minimum transfer value == yamsScalingFactor / 1e24;

        _transfer(refundee, address(0), value);

        require(nextYamScalingFactor <= _maxScalingFactor(), "max scaling factor too low");

        // add to balance of receiver
        emit Burn(msg.sender, value, refundee);

    }
    /**
    * @dev Transfer tokens from one address to another.
    * @param from The address you want to send tokens from.
    * @param to The address you want to transfer to.
    * @param value The amount of tokens to be transferred.
    */
    function transferFrom(address from, address to, uint256 value) external notFrozen returns (bool) {
        // decrease allowance
        _allowedFragments[from][msg.sender] = _allowedFragments[from][msg.sender] - value;

        _transfer(from, to, value);

        return true;
    }


    /**
    * @param who The address to query.
    * @return The balance of the specified address.
    */
    function balanceOf(address who) external view returns (uint256) {
        return _balanceOf(who);
    }

    function _balanceOf(address who) internal view returns (uint256) {
        return _yamToFragment(super.getVotes(who));
    }

    /** @notice Currently returns the internal storage amount
    * @param who The address to query.
    * @return The underlying balance of the specified address.
    */
    function balanceOfUnderlying(address who) external view returns (uint256) {
        return super.getVotes(who);
    }
    

    /**
     * @dev Function to check the amount of tokens that an owner has allowed to a spender.
     * @param owner_ The address which owns the funds.
     * @param spender The address which will spend the funds.
     * @return The number of tokens still available for the spender.
     */
    function allowance(address owner_, address spender) external view returns (uint256) {
        return _allowedFragments[owner_][spender];
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of
     * msg.sender. This method is included for ERC20 compatibility.
     * increaseAllowance and decreaseAllowance should be used instead.
     * Changing an allowance with this method brings the risk that someone may transfer both
     * the old and the new allowance - if they are both greater than zero - if a transfer
     * transaction is mined before the later approve() call is mined.
     *
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) external returns (bool) {
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /* - Extras - */

    function setRebase(uint256 epoch, uint256 value, uint256 rebaseInterval) external onlyRole(REBASER_ROLE) returns (bool) {
        require(value < _maxScalingFactor(), "stFLIP: rebaseFactor too large");

        uint96 previousYamScalingFactor_ = SafeCast.toUint96(_yamsScalingFactor());

        // 1 sstore
        nextYamScalingFactor = SafeCast.toUint96(value);
        previousYamScalingFactor = previousYamScalingFactor_;
        lastRebaseTimestamp = SafeCast.toUint32(block.timestamp);
        rebaseIntervalEnd = SafeCast.toUint32(block.timestamp + rebaseInterval);

        emit Rebase(epoch, previousYamScalingFactor_, value, rebaseInterval);
        return true;
    }

    function yamToFragment(uint256 yam) external view returns (uint256) {
        return _yamToFragment(yam);
    }

    function fragmentToYam(uint256 value) external view returns (uint256) {
        return _fragmentToYam(value);
    }

    function initSupply() external view returns (uint256) {
        return _getTotalSupply();
    }
    
    function _yamToFragment(uint256 yam) internal view returns (uint256) {
        return yam * _yamsScalingFactor() / internalDecimals;
    }

    function _fragmentToYam(uint256 value) internal view returns (uint256) {
        return value * internalDecimals / _yamsScalingFactor();
    }

    // Rescue tokens
    function rescueTokens(address token, address to, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        // transfer to
        SafeERC20.safeTransfer(IERC20(token), to, amount);
        return true;
    }

    function _yamsScalingFactor() internal view returns (uint256) {
        uint32 blockTimestamp = SafeCast.toUint32(block.timestamp);
        uint32 rebaseIntervalEnd_ = rebaseIntervalEnd;
        uint32 lastRebaseTimestamp_ = lastRebaseTimestamp;
        if (blockTimestamp >= rebaseIntervalEnd_) {
            return nextYamScalingFactor;
        }

        if (blockTimestamp == lastRebaseTimestamp_) {
            return previousYamScalingFactor;
        }

        uint96 previousYamScalingFactor_ = previousYamScalingFactor;
        uint96 nextYamScalingFactor_ = nextYamScalingFactor;
        uint256 ratioComplete = (blockTimestamp - lastRebaseTimestamp_) * internalDecimals / (rebaseIntervalEnd_ - lastRebaseTimestamp_);
        uint256 difference;

        if (nextYamScalingFactor_ > previousYamScalingFactor_) { // rewards, so factor increases
            difference = nextYamScalingFactor_ - previousYamScalingFactor_;
            return uint256(previousYamScalingFactor_ + difference * ratioComplete / internalDecimals);
        } else { // slash, so factor decreases
            difference = previousYamScalingFactor_ - nextYamScalingFactor_;
            return uint256(previousYamScalingFactor_ - difference * ratioComplete / internalDecimals);
        }
    }

    function yamsScalingFactor() external view returns (uint256) {
        return _yamsScalingFactor();
    }

    function _totalSupply() internal view returns (uint256) {
        return _getTotalSupply() * _yamsScalingFactor() / internalDecimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply();
    }
    function clock() public view override returns (uint48) {
        return uint48(block.timestamp);
    }

    // solhint-disable-next-line func-name-mixedcase
    function CLOCK_MODE() public pure override returns (string memory) {
        return "mode=timestamp";
    }
    
    // https://forum.openzeppelin.com/t/self-delegation-in-erc20votes/17501/17
    // https://github.com/aragon/osx/blob/a52bbae69f78e74d6a17647370ccfa2f2ea9bbf0/packages/contracts/src/token/ERC20/governance/GovernanceERC20.sol#L113

}






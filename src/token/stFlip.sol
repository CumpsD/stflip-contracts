// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.7;

import "./tStorage.sol";
import "../utils/Ownership.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/governance/utils/VotesUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

/**
 * @title stFlip token contract
 * @notice This is the token contract for StakedFLIP. It is backed 1:1 by native FLIP. 
 * It is rebasing and also a voting token. It is a fork of the YAM token contract. After each
 * transfer, a new checkpoint is added via `votesUpgradeable` which we have modified to automatically
 * self-delegate every address and disable delegation to every address, thus the latest checkpoint is the
 * `underlying` balance for a given address. This fork is here: https://github.com/thunderhead-labs/openzeppelin-contracts-upgradeable.
 * The changes are trivial. `underlying` is the representation used for balance in storage,
 * although the real balance is `underlying` * `yamsScalingFactor` / `internalDecimals`. `yamsScalingFactor`
 * is updated by calling Rebase, which the Rebaser contract handles. `yamsScalingFactor` also increases over
 * a period of time to ensure continous reward distribution. Yams are the `underlying` balance while `fragments`
 * are the balance the user/other contracts actually see. Relevant sources: https://forum.openzeppelin.com/t/self-delegation-in-erc20votes/17501/17 and 
 * https://github.com/aragon/osx/blob/a52bbae69f78e74d6a17647370ccfa2f2ea9bbf0/packages/contracts/src/token/ERC20/governance/GovernanceERC20.sol#L113
 */
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
     * Modifier to ensure token is not frozen for certain operations
     */
    modifier notFrozen() {
        require(frozen==false, "frozen");
        _;
    }
    
    /**
     * Sets initial initialization parameters
     * @param name_ Token name (Staked Chainflip)
     * @param symbol_ Token symbol (stFLIP)
     * @param decimals_ Decimals (18)
     * @param gov_ Governance address
     * @param initialSupply_ Initial supply (0)
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

    /**
     * @dev Balances are uint256 so we must ensure that we don't
     * set a rebaseFactor that when multiplied by underlying will 
     * cause a uint256 overflow. We will never get to this point since
     * uint256 is 10e51 times larger than the total supply of Chainflip
     * (90m).
     */
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
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) notFrozen returns (bool) {
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
        uint256 yamValue = _fragmentToYam(amount);

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
        // note, this means as scaling factor grows, dust will be untransferrable.
        // minimum transfer value == yamsScalingFactor / 1e24;

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
        // note, this means as scaling factor grows, dust will be untransferrable.
        // minimum transfer value == yamsScalingFactor / 1e24;

        _transfer(refundee, address(0), value);

        require(nextYamScalingFactor <= _maxScalingFactor(), "max scaling factor too low");
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

    /**
     * Queries balance of address
     * @param who The address to query
     * @dev This retrieves the underlying (yams) from `VotesUpgradeable`
     * which is the value of the latest balance checkpoint. It is then scaled
     * by the rebaseFactor in `yamToFragment`.
     */
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

    /**
     * Function called by Rebaser that sets the new rebase factor
     * @param epoch Used for event
     * @param value Value to set the new rebase factor to
     * @param rebaseInterval Time for the token to reach scaling factor of `value`
     * @dev The rebase factor will not actually increase to `value` right after this
     * transaction, it will linearly increase over the `rebaseInterval` specified. See
     * `_yamsScalingFactor` for more details. You can't set the rebase factor if the 
     * supply is zero. Rebases will not occur while the supply is small. 
     */
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

    /**
     * Convert underlying to balance
     * @param yam The amount of yam (underlying) to convert to fragment (actual balance)
     */
    function yamToFragment(uint256 yam) external view returns (uint256) {
        return _yamToFragment(yam);
    }

    /**
     * Convert balance to underlying
     * @param value The amount of fragment (actual balance) to convert to yam (underlying)
     */
    function fragmentToYam(uint256 value) external view returns (uint256) {
        return _fragmentToYam(value);
    }

    /**
     * Retrieves the total balance of `underlying` from `VotesUpgradeable`
     * latest supply checkpoint
     */
    function initSupply() external view returns (uint256) {
        return _getTotalSupply();
    }
    
    /**
     * Converts from yam (underlying) to fragment (actual balance)
     * @param yam The amount of yam (underlying)
     */
    function _yamToFragment(uint256 yam) internal view returns (uint256) {
        return yam * _yamsScalingFactor() / internalDecimals;
    }

    /**
     * Converts from fragment (actual balance) to yam (underlying)
     * @param value The amount of fragment (actual balance)
     */
    function _fragmentToYam(uint256 value) internal view returns (uint256) {
        return value * internalDecimals / _yamsScalingFactor();
    }

    /**
     * Perform rescues in case they are needed
     * @param token token address
     * @param to recipient address
     * @param amount amount
     */
    function rescueTokens(address token, address to, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        // transfer to
        SafeERC20.safeTransfer(IERC20(token), to, amount);
        return true;
    }

    /**
     * Calculates the current rebase factor of the token
     * @dev The rebase factor monotonically increases or decreases over the next interval
     * depending on whether there were net rewards or slashing during the last rebase. It increases
     * linearly based on how much time has elapsed. Once the interval ends this just returns the
     * `nextYamsScalingFactor`. 
     */
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

    /**
     * Public getter for yams scaling factor (used to calculate balance)
     */
    function yamsScalingFactor() external view returns (uint256) {
        return _yamsScalingFactor();
    }

    /**
     * Total supply of stFLIP
     * @dev Keep in mind that `_getTotalSupply` is an internal function 
     * from `VotesUpgradeable` that returns the total supply of underlying,
     * (value of latest supply checkpoint) this is also known as `initSupply` 
     * in the stFLIP contract.
     */
    function _totalSupply() internal view returns (uint256) {
        return _getTotalSupply() * _yamsScalingFactor() / internalDecimals;
    }

    /**
     * Public getter for total supply of stFLIP
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply();
    }

    /**
     * Overriding the clock set in `VotesUpgradeable` since
     * GovernorOmega uses timestamp
     */
    function clock() public view override returns (uint48) {
        return uint48(block.timestamp);
    }

    // solhint-disable-next-line func-name-mixedcase
    function CLOCK_MODE() public pure override returns (string memory) {
        return "mode=timestamp";
    }

}






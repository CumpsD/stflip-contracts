// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.7;

/* import "./YAMTokenInterface.sol"; */
import "./tStorage.sol";
import "../utils/Ownership.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/utils/VotesUpgradeable.sol";


contract stFlip is Initializable, Ownership, TokenStorage, VotesUpgradeable {


    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Event emitted when tokens are rebased
     */
    event Rebase(uint256 epoch, uint256 prevYamsScalingFactor, uint256 newYamsScalingFactor);

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

        yamsScalingFactor = BASE;
        initSupply = _fragmentToYam(initialSupply_);
        totalSupply = initialSupply_;
        _yamBalances[gov_] = initSupply;

        // DOMAIN_SEPARATOR = keccak256(
        //     abi.encode(
        //         DOMAIN_TYPEHASH,
        //         keccak256(bytes(name)),
        //         3,
        //         address(this)
        //     )
        // );

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
        return type(uint).max / initSupply;
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
        // increase totalSupply
        totalSupply = totalSupply + amount;

        // get underlying value
        uint256 yamValue = _fragmentToYam(amount);

        // increase initSupply
        initSupply = initSupply + yamValue;

        // make sure the mint didnt push maxScalingFactor too low
        require(yamsScalingFactor <= _maxScalingFactor(), "max scaling factor too low");

        // add balance
        _yamBalances[to] = _yamBalances[to] + yamValue;

        // add delegates to the minter
        emit Mint(to, amount);
        emit Transfer(address(0), to, amount);

        _afterTokenTransfer(address(0), to, yamValue);
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

        // sub from balance of sender
        _yamBalances[msg.sender] = _yamBalances[msg.sender] - yamValue;

        // add to balance of receiver
        _yamBalances[to] = _yamBalances[to] + yamValue;
        emit Transfer(msg.sender, to, value);

        _afterTokenTransfer(msg.sender, to, yamValue);
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

        // get amount in underlying
        totalSupply = totalSupply - value;

        uint256 yamValue = _fragmentToYam(value);

        initSupply = initSupply - yamValue;

        // sub from balance of sender

        require(yamsScalingFactor <= _maxScalingFactor(), "max scaling factor too low");

        _yamBalances[refundee] = _yamBalances[refundee] - yamValue;

        // add to balance of receiver
        emit Burn(msg.sender, value, refundee);
        emit Transfer(refundee, address(0), value);

        _afterTokenTransfer(refundee, address(0), yamValue);
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


        // get value in yams
        uint256 yamValue = _fragmentToYam(value);

        // sub from from
        _yamBalances[from] = _yamBalances[from] - yamValue;
        _yamBalances[to] = _yamBalances[to] + yamValue;

        emit Transfer(from, to, value);

        _afterTokenTransfer(from, to, yamValue);

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
        return _yamToFragment(_yamBalances[who]);
    }

    /** @notice Currently returns the internal storage amount
    * @param who The address to query.
    * @return The underlying balance of the specified address.
    */
    function balanceOfUnderlying(address who) external view returns (uint256) {
        return _yamBalances[who];
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
     * @dev Increase the amount of tokens that an owner has allowed to a spender.
     * This method should be used instead of approve() to avoid the double approval vulnerability
     * described above.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) external notFrozen returns (bool) {
        _allowedFragments[msg.sender][spender] = _allowedFragments[msg.sender][spender] + addedValue;
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner has allowed to a spender.
     *
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external notFrozen returns (bool) {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue - subtractedValue;
        }
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }
    
        // --- Approve by signature ---
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) notFrozen external {
        require(block.timestamp <= deadline, "stFlip: permit-expired");

        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    _domainSeparatorV4(),
                    keccak256(
                        abi.encode(
                            PERMIT_TYPEHASH,
                            owner,
                            spender,
                            value,
                            _useNonce(owner),
                            deadline
                        )
                    )
                )
            );

        require(owner != address(0), "stFlip: invalid-address-0");
        require(owner == ecrecover(digest, v, r, s), "stFlip: invalid-permit");
        _allowedFragments[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /* - Governance Functions - */

    /** @notice sets the rebaser
     * @param rebaser_ The address of the rebaser contract to use for authentication.
     */
    /* - Extras - */

    /**
    * @notice Initiates a new rebase operation, provided the minimum time period has elapsed.
    *
    * @dev The supply adjustment equals (totalSupply * DeviationFromTargetRate) / rebaseLag
    *      Where DeviationFromTargetRate is (MarketOracleRate - targetRate) / targetRate
    *      and targetRate is CpiOracleRate / baseCpi
    */
  
    function setRebase(uint256 epoch, uint256 value) external onlyRole(REBASER_ROLE) returns (uint256) {
        // no change
        if (value == yamsScalingFactor) {
          emit Rebase(epoch, yamsScalingFactor, yamsScalingFactor);
          return totalSupply;
        }

        // for events
        uint256 prevYamsScalingFactor = yamsScalingFactor;

        // positive reabse, increase scaling factor
        uint256 newScalingFactor = value;
        if (newScalingFactor < _maxScalingFactor()) {
            yamsScalingFactor = value;
        } else {
            yamsScalingFactor = _maxScalingFactor();
        }

        // update total supply, correctly
        totalSupply = _yamToFragment(initSupply);

        emit Rebase(epoch, prevYamsScalingFactor, yamsScalingFactor);
        return totalSupply;
    }

    function yamToFragment(uint256 yam) external view returns (uint256) {
        return _yamToFragment(yam);
    }

    function fragmentToYam(uint256 value) external view returns (uint256) {
        return _fragmentToYam(value);
    }

    function _yamToFragment(uint256 yam) internal view returns (uint256) {
        return yam * yamsScalingFactor / internalDecimals;
    }

    function _fragmentToYam(uint256 value) internal view returns (uint256) {
        return value * internalDecimals / yamsScalingFactor;
    }

    // Rescue tokens
    function rescueTokens(address token, address to, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        // transfer to
        SafeERC20.safeTransfer(IERC20(token), to, amount);
        return true;
    }

    function delegate(address delegatee) public override {
        revert("stFlip: delegation not allowed");
    }

    function _getVotingUnits(address account) internal view override returns (uint256) {
        return _balanceOf(account);
    }
    
    // https://forum.openzeppelin.com/t/self-delegation-in-erc20votes/17501/17
    // https://github.com/aragon/osx/blob/a52bbae69f78e74d6a17647370ccfa2f2ea9bbf0/packages/contracts/src/token/ERC20/governance/GovernanceERC20.sol#L113
    function _afterTokenTransfer(address from, address to, uint256 yam) internal {
        if (to != address(0) && delegates(to) == address(0) && !unallowedVoter[to]) {
            _delegate(to, to);
        }

        _transferVotingUnits(from, to, yam);
    }

    function setVoterStatus(address voter, bool unallowed) external onlyRole(DEFAULT_ADMIN_ROLE) {
        unallowedVoter[voter] = unallowed;
    }


}

// contract stFlip is StakedFLIP {
//     /**
//      * @notice Initialize the new money market
//      * @param name_ ERC-20 name of this token
//      * @param symbol_ ERC-20 symbol of this token
//      * @param decimals_ ERC-20 decimal precision of this token
//      */
//     function initialize(string memory name_, string memory symbol_, uint8 decimals_, address initial_owner, uint256 initTotalSupply_) onlyGov public {
//         super.initialize(name_, symbol_, decimals_);

//         yamsScalingFactor = BASE;
//         initSupply = _fragmentToYam(initTotalSupply_);
//         totalSupply = initTotalSupply_;
//         _yamBalances[initial_owner] = initSupply;
//         DOMAIN_SEPARATOR = keccak256(
//             abi.encode(
//                 DOMAIN_TYPEHASH,
//                 keccak256(bytes(name)),
//                 3,
//                 address(this)
//             )
//         );
//     }
// }

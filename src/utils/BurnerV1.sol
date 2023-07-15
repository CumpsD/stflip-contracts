// Thunderhead: https://github.com/thunderhead-labs


// Author(s)
// Addison Spiegel: https://addison.is
// Pierre Spiegel: https://pierre.wtf

pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../token/stFlip.sol";
import "forge-std/console.sol";
import "./Ownership.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

/**
 * @title Burner contract for stFLIP
 * @notice Allows users to burn their stFLIP to enter the burn queue.
 * Allows users to later redeem their native FLIP. Contains many
 * getter functions that are useful for a frontend. 
 */
contract BurnerV1 is Initializable, Ownership {

    address public gov;
    address public pendingGov;
    address public output;

    uint256 public balance = 0;
    uint256 public redeemed = 0;
    struct burn_ {
        address user;
        uint256 amount;
        bool completed;
    }
    burn_[] public burns;
    uint256[] public sums;

    stFlip public stflip;
    IERC20 public flip;

    constructor () {
        _disableInitializers();
    }

    function initialize(address stflip_, address gov_, address flip_, address output_) initializer public {
        stflip = stFlip(stflip_);
        __AccessControlDefaultAdminRules_init(0, gov_);
        flip = IERC20(flip_);
        burns.push(burn_(address(0), 0, true));
        sums.push(0);
        output = output_;
    }

    /// @notice Tokens burned event
    event Burn(uint256 amount, uint256 burnId);

    /**
     * @notice Burns stflip tokens, transfers FLIP tokens from msg.sender, adds entry to burns/sums list
     * @param to, the owner of the burn, the address that will receive the burn once completed
     * @param amount, the amount to burn
     */
    function burn(address to, uint256 amount) external returns (uint256) {
        stflip.burn(amount, msg.sender);
        burns.push(burn_(to, amount, false));
        sums.push(amount + sums[sums.length - 1]);

        emit Burn(amount, burns.length - 1);

        return burns.length - 1;
    }

    /**
     * @notice redeems a burn, claiming native FLIP back to "to" field of burn entry
     * @param burnId, the ID of the burn to redeem.
     */
    function redeem(uint256 burnId) external {
        require(_redeemable(burnId), "Burner: not redeemable. either already claimed or insufficient balance");

        flip.transferFrom(output, burns[burnId].user, burns[burnId].amount);
        burns[burnId].completed = true;
        redeemed = redeemed + burns[burnId].amount;
    }

    /**
     * @notice the sum of all unredeemed burns in the contract
     */
    function totalPendingBurns() external view returns (uint256) {
        return sums[burns.length - 1] - redeemed;
    }

    /// @notice all the burn ids associated with an address
    /// @param account The address of the user to check
    function _getBurnIds(address account) internal view returns (uint256[] memory) {

        uint256[] memory burnIds = new uint256[](burns.length);
        uint256 t = 0;

        for (uint256 i = 0; i < burns.length; i++) {
            if (burns[i].user == account) {
                burnIds[t] = i;
                t++;
            }
        }

        uint256[] memory filteredBurnIds = new uint256[](t);
        for (uint256 i = 0; i < t; i++) {
            filteredBurnIds[i] = burnIds[i];
        }

        return filteredBurnIds;
    }

    /// @notice public function to get all the burn ids associated with an address
    /// @param account The address of the user to check
    function getBurnIds(address account) external view returns (uint256[] memory) {
        return _getBurnIds(account);
    }

    /**
     * @notice get all the burns of an account, the the full structs, ids, and if they can be redeemed.
     * @param account The address of the user to pull burns for
     */
    function getBurns(
        address account
    ) external view returns (burn_[] memory, uint256[] memory, bool[] memory) {
        uint256[] memory burnIds = _getBurnIds(account);
        burn_[] memory userBurns = new burn_[](burnIds.length);
        bool[] memory userRedeemables = new bool[](burnIds.length);

        for (uint256 i = 0; i < burnIds.length; i++) {
            userBurns[i] = burns[burnIds[i]];
            userRedeemables[i] = _redeemable(burnIds[i]);
        }

        return (userBurns, burnIds, userRedeemables);
    }

    /**
    * @notice is a burn redeemable
    * @param burnId The id of the burn to check
    * @dev Firstly, burn can obviously not be redeemable if it has already been redeemed. 
    * Secondly, we ensure that there is enough FLIP to satisfy all prior burns in the burn queue, 
    * and the burn of `burnId` itself. `Sums[burnId]` is the sum of all burns up to and including `burnId`.
    * redeemed is the sum of all burns that have been redeemed. If the difference between the two is <= than the
    * balance of FLIP in the contract, then the burn is redeemable.
     */ 
    function _redeemable(uint256 burnId) internal view returns (bool) {
        uint256 difference = sums[burnId] < redeemed ? 0 : sums[burnId] - redeemed;
        return burns[burnId].completed == false && difference <= flip.balanceOf(address(output));
    }


    /**
    * @notice Public getter for redeemable
    * @param burnId The id of the burn to check
     */
    function redeemable(uint256 burnId) external view returns (bool) {
        return _redeemable(burnId);
    }

    /// @notice Public getter for the burns struct list
    function getAllBurns() external view returns (burn_[] memory) {
        return burns;
    }

}

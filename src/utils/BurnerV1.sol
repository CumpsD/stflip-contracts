pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../token/stFlip.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";


contract BurnerV1 is Initializable {
    using SafeMath for uint256;

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
        gov = gov_;
        flip = IERC20(flip_);
        burns.push(burn_(address(0), 0, true));
        sums.push(0);
        output = output_;
    }

    /// @notice Event emitted when pendingGov is changed
    event NewPendingGov(address oldPendingGov, address newPendingGov);

    /// @notice Event emitted when gov is changed
    event NewGov(address oldGov, address newGov);

    /// @notice Tokens burned event
    event Burn(uint256 amount, uint256 burnId);

    // Modifiers
    modifier onlyGov() {
        require(msg.sender == gov);
        _;
    }

    /// @notice sets the pendingGov
    /// @param pendingGov_ The address of the rebaser contract to use for authentication.
    function _setPendingGov(address pendingGov_) external onlyGov {
        address oldPendingGov = pendingGov;
        pendingGov = pendingGov_;
        emit NewPendingGov(oldPendingGov, pendingGov_);
    }

    /// @notice lets msg.sender accept governance
    function _acceptGov() external {
        require(msg.sender == pendingGov, "!pending");
        address oldGov = gov;
        gov = pendingGov;
        pendingGov = address(0);
        emit NewGov(oldGov, gov);
    }

    /**
     * @notice Burns stflip tokens, transfers FLIP tokens from msg.sender, adds entry to burns/sums list
     * @param to, the owner of the burn, the address that will receive the burn once completed
     * @param amount, the amount to burn
     */
    function burn(address to, uint256 amount) external returns (uint256) {
        stflip.burn(amount, msg.sender);
        burns.push(burn_(to, amount, false));
        sums.push(amount.add(sums[sums.length - 1]));

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
        redeemed = redeemed.add(burns[burnId].amount);
    }

    function emergencyWithdraw(uint256 amount, address token) external onlyGov {
        IERC20(token).transfer(msg.sender, amount);
    }

    /**
     * @notice the sum of all unredeemed burns in the contract
     */
    function totalPendingBurns() external view returns (uint256) {
        return sums[burns.length - 1] - redeemed;
    }

    /// @notice all the burn ids associated with an address
    /// @param account The address of the user to check
    function _getBurnIds(
        address account
    ) internal view returns (uint256[] memory) {

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
        return burns[burnId].completed == false && subtract(sums[burnId], redeemed) <= flip.balanceOf(address(output));
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

    function subtract(uint a, uint b) public pure returns (uint) {
        unchecked {
            if (a < b) return 0;
            return a - b;
        }
    }
}

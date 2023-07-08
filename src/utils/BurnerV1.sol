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
    uint256 public reedemed = 0;
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
        require(msg.sender == gov);
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

    /**
     * @notice Burns tokens, transfering tokens from msg.sender, burning them, adding an item to the burns list
     * @param to, the owner of the burn, the address that will receive the burn once completed
     * @param amount, the amount to burn
     */
    function burn(address to, uint256 amount) external returns (uint256) {
        burns.push(burn_(to, amount, false));
        sums.push(amount.add(sums[sums.length - 1]));
        stflip.burn(amount, msg.sender);
        emit Burn(amount, burns.length - 1);

        return burns.length - 1;
    }

    /**
     * @notice redeems a burn, claiming native FLIP back to "to"
     * @param burn_id, the ID of the burn to redeem.
     */
    function redeem(uint256 burn_id) external {
        require(burns[burn_id].completed == false, "completed");
        require(
            subtract(sums[burn_id], reedemed) <= flip.balanceOf(output),
            "insufficient balance"
        );

        flip.transferFrom(output, burns[burn_id].user, burns[burn_id].amount);
        burns[burn_id].completed = true;
        reedemed = reedemed.add(burns[burn_id].amount);
        // balance = balance.sub(burns[burn_id].amount);
    }

    function emergencyWithdraw(uint256 amount, address token) external onlyGov {
        IERC20(token).transfer(msg.sender, amount);
    }

    /**
     * @notice the sum of all unredeemed burns in the contract
     */
    function totalPendingBurns() external view returns (uint256) {
        return sums[burns.length - 1] - reedemed;
    }

    function getBurnIds(
        address account
    ) internal view returns (uint256[] memory) {
        uint256[] memory burn_ids = new uint256[](burns.length);
        uint256 t = 0;
        for (uint256 i = 0; i < burns.length; i++) {
            if (burns[i].user == account) {
                burn_ids[t] = i;
                t++;
            }
        }

        // remove extra zeros
        uint256[] memory burn_ids_ = new uint256[](t);
        for (uint256 i = 0; i < t; i++) {
            burn_ids_[i] = burn_ids[i];
        }

        return burn_ids_;
    }

    /**
     * @notice get all the burns of an account, the the full structs, ids, and if they can be redeemed.
     */
    function getBurns(
        address account
    ) external view returns (burn_[] memory, uint256[] memory, bool[] memory) {
        uint256[] memory burn_ids = getBurnIds(account);
        burn_[] memory burns_ = new burn_[](burn_ids.length);
        bool[] memory redeemables = new bool[](burn_ids.length);
        for (uint256 i = 0; i < burn_ids.length; i++) {
            burns_[i] = burns[burn_ids[i]];

            if (
                burns[burn_ids[i]].completed == false &&
                subtract(sums[burn_ids[i]], reedemed) <= flip.balanceOf(address(output))
            ) {
                redeemables[i] = true;
            } else {
                redeemables[i] = false;
            }
        }

        return (burns_, burn_ids, redeemables);
    }

    /** @notice is a burn redeemable
     */
    function redeemable(uint256 burn_id) external view returns (bool) {
        if (
            burns[burn_id].completed == false &&
            subtract(sums[burn_id], reedemed) <= flip.balanceOf(address(output))
        ) {
            return true;
        } else {
            return false;
        }
    }

    function getAllBurns() external view returns (burn_[] memory) {
        return burns;
    }

    function subtract(uint a, uint b) public pure returns (uint) {
        unchecked {
            if (a < b) return 0;
            return a - b;
        }
    }

    /** @notice will be used if we ever need to make a new burn contract
     */
    function importData(BurnerV1 burnerToImport) external onlyGov returns (bool) {
        burn_[] memory allBurns = burnerToImport.getAllBurns();

        for (uint i = 1; i < allBurns.length; i++) {
            sums.push(burnerToImport.sums(i));
            burns.push(allBurns[i]);
        }

        reedemed = burnerToImport.reedemed();

        return true;
    }
}

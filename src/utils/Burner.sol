pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../token/stFlip.sol";

contract Burner {
    using SafeMath for uint256;

    address public gov;
    address public pendingGov;
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

    constructor(address stflip_, address gov_, address flip_) {
        stflip = stFlip(stflip_);
        gov = gov_;
        flip = IERC20(flip_);
        burns.push(burn_(address(0), 0, true));
        sums.push(0);
    }

    event NewPendingGov(address oldPendingGov, address newPendingGov);

    event NewGov(address oldGov, address newGov);

    event Burn(uint256 amount, uint256 burn_id);

    modifier onlyGov() {
        require(msg.sender == gov);
        _;
    }

    function _setPendingGov(address pendingGov_)
        external
        onlyGov
    {
        address oldPendingGov = pendingGov;
        pendingGov = pendingGov_;
        emit NewPendingGov(oldPendingGov, pendingGov_);
    }

    function _acceptGov()
        external
    {
        require(msg.sender == pendingGov, "!pending");
        address oldGov = gov;
        gov = pendingGov;
        pendingGov = address(0);
        emit NewGov(oldGov, gov);
    }

    function burn(uint256 amount) external returns (uint256) {
        stflip.transferFrom(msg.sender, address(this), amount);
        burns.push(burn_(msg.sender, amount, false));
        sums.push(amount.add(sums[sums.length-1]));
        stflip.burn(amount, address(this));

        emit Burn(amount, burns.length-1);

        return burns.length-1;
    }
    
    function redeem(uint256 burn_id) external {
        require(burns[burn_id].user == msg.sender, "!user");
        require(burns[burn_id].completed == false, "completed");
        require(subtract(sums[burn_id], reedemed) <= balance, "insufficient balance");

        flip.transfer(msg.sender, burns[burn_id].amount);
        burns[burn_id].completed = true;
        reedemed = reedemed.add(burns[burn_id].amount);
        balance = balance.sub(burns[burn_id].amount);
    }

    function deposit(uint256 amount) external onlyGov {
        flip.transferFrom(msg.sender, address(this), amount);
        balance = balance.add(amount);
    }

    function govWithdraw(uint256 amount) external onlyGov {
        flip.transfer(msg.sender, amount);
        balance = balance.sub(amount);
    }

    function emergencyWithdraw(uint256 amount, address token) external onlyGov {
        IERC20(token).transfer(msg.sender, amount);
    }

    function totalPendingBurns()
      external
      view
      returns (uint256)
    {
        uint256 t = 0;
        for (uint256 i=0; i<burns.length; i++) {
            if (!burns[i].completed) {
                t += burns[i].amount;
            }
        }

        return t;
    }

    function getBurnIds(address account)
      internal 
      view
      returns (uint256[] memory)
    {
        uint256[] memory burn_ids = new uint256[](burns.length);
        uint256 t = 0;
        for (uint256 i=0; i<burns.length; i++) {
            if (burns[i].user == account) {
                burn_ids[t] = i;
                t++;
            }
        }

        // remove extra zeros
        uint256[] memory burn_ids_ = new uint256[](t);
        for (uint256 i=0; i<t; i++) {
            burn_ids_[i] = burn_ids[i];
        }

        return burn_ids_;
    }

    // returns all the pending burns of a user
    function getBurns(address account)
      external
      view
      returns (burn_[] memory, uint256[] memory, bool[] memory)
    {
        uint256[] memory burn_ids = getBurnIds(account);
        burn_[] memory burns_ = new burn_[](burn_ids.length);
        bool[] memory redeemables = new bool[](burn_ids.length);
        for (uint256 i=0; i<burn_ids.length; i++) {
            burns_[i] = burns[burn_ids[i]];

            if (burns[burn_ids[i]].completed == false && subtract(sums[burn_ids[i]], reedemed) <= balance) {
                redeemables[i] = true;
            } else {
                redeemables[i] = false;
            }
        }

        return (burns_, burn_ids, redeemables);
    }

    function redeemable(uint256 burn_id)
      external
      view
      returns (bool)
    {
      if (burns[burn_id].completed == false && subtract(sums[burn_id], reedemed) <= balance) {
        return true;
      } else {
        return false;
      }
    }

    function getAllBurns()
        external
        view
        returns (burn_[] memory)
    {
        return burns;
    }

    function subtract(uint a, uint b) 
      public 
      pure 
      returns (uint) 
    {
      unchecked {
        if (a<b) return 0;
        return a - b;
      }
    }
}



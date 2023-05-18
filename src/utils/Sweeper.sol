pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./BurnerV1.sol";

interface Staker {
  function executeClaim(bytes32 nodeID) external;
}

contract Sweeper {
    IERC20 public flip;
    BurnerV1 public burner;
    Staker public staker;

    constructor(address flip_, address burner_, address staker_) {
        flip = IERC20(flip_);
        burner = BurnerV1(burner_);
        staker = Staker(staker_);

        flip.approve(burner_, 2**256 -1 );
    }

    // @notice disperse tokens to a number of recipients in one transaction
    // @param recipients, normal token recipients
    // @param values, the corresponding amounts to go to each recipient
    // @param deposit, the amount to deposit into the burner contract
    function disperseToken(
        bytes32 nodeID,
        address[] calldata recipients,
        uint256[] calldata values,
        uint256 deposit
    ) external {
        staker.executeClaim(nodeID);
        uint256 total = deposit;
        for (uint256 i = 0; i < recipients.length; i++) total += values[i];
        require(flip.transferFrom(msg.sender, address(this), total));
        for (uint256 i = 0; i < recipients.length; i++) {
            require(flip.transfer(recipients[i], values[i]));
        }

        flip.transferFrom(msg.sender, address(this), deposit);
        burner.deposit(deposit);
    }
}

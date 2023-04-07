pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Burner.sol";

contract Sweeper {
    IERC20 public flip;
    Burner public burner;

    constructor(address flip_, address burner_) {
        flip = IERC20(flip_);
        burner = Burner(burner_);
    }

    // @notice disperse tokens to a number of recipients in one transaction
    // @param recipients, normal token recipients
    // @param values, the corresponding amounts to go to each recipient
    // @param deposit, the amount to deposit into the burner contract
    function disperseToken(
        address[] calldata recipients,
        uint256[] calldata values,
        uint256 deposit
    ) external {
        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i++) total += values[i];
        require(flip.transferFrom(msg.sender, address(this), total));
        for (uint256 i = 0; i < recipients.length; i++) {
            require(flip.transfer(recipients[i], values[i]));
        }

        flip.transferFrom(msg.sender, address(this), deposit);
        flip.approve(address(burner), deposit);
        burner.deposit(deposit);
    }
}

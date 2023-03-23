// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/utils/StakeAggregator.sol";
import "./MainMigration.sol";

contract StakeAggregatorTest is MainMigration {
    StakeAggregator public counter;

    function setUp() public {
        MainMigration migration = new MainMigration();
    }

    function testFuzz_Aggregate(uint256 amount_, uint256 lpAmount1_, uint256 lpAmount2_) public {
        uint256 flipBalance = flip.balanceOf(owner);
        uint256 stflipBalance = stflip.balanceOf(owner);
        // vm.assume(lpAmount1 < stflipBalance);
        uint256 lpAmount1 = bound(lpAmount1_, 1000, stflipBalance);
        uint256 lpAmount2 = bound(lpAmount2_, 1000, flipBalance-100);
        uint256 amount = bound(amount_, 2, flipBalance - lpAmount2);
        console.log(amount_,lpAmount1_,lpAmount2_);
        console.log(amount,lpAmount1,lpAmount2);

        vm.startPrank(owner);
        tenderSwap.addLiquidity([lpAmount1, lpAmount2], 0, block.timestamp+100);
        uint256 purchasable = stakeAggregator.calculatePurchasable(1003*10**(decimals - 3), 10**(decimals-2), 100);
        uint256 _dx;
        uint256 _minDy;

        if (purchasable == 0) {
            _dx = 0;
            _minDy = 0;
        } 
        else if (purchasable > amount) {
            _dx = amount;
            _minDy = tenderSwap.calculateSwap(IERC20(address(flip)), _dx);

        } 
        else {
            _dx = purchasable;
            _minDy = tenderSwap.calculateSwap(IERC20(address(flip)), _dx);
        }
        
        stakeAggregator.aggregate(amount, _dx, _minDy, block.timestamp + 100);
    }
}

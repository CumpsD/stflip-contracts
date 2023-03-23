// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/utils/StakeAggregator.sol";
import "./MainMigration.sol";

contract StakeAggregatorTest is MainMigration {
    StakeAggregator public counter;

    function setUp() public {
        MainMigration migration = new MainMigration();
        // counter = new StakeAggregator();
        // counter.setNumber(0);
    }

    function testCalculate() public {
        stakeAggregator.calculatePurchasable(1003*10**(decimals - 3), 10**(decimals-2), 100);
        // counter.increment();
        // assertEq(counter.number(), 1);
    }

    function testSetNumber(uint256 x) public {
        // counter.setNumber(x);
        // assertEq(counter.number(), x);
    }

    function testFuzz_Aggregate(uint256 amount) public {
        vm.assume(amount < flip.balanceOf(owner));
        vm.assume(amount > 0);

        vm.startPrank(owner);
        uint256 purchasable = stakeAggregator.calculatePurchasable(1003*10**(decimals - 3), 10**(decimals-2), 100);
        uint256 _dx;
        uint256 _minDy;
        // uint256 amount = 2000*decimalsMultiplier;
        if (purchasable == 0) {
            _dx = 0;
        } 
        else if (purchasable > amount) {
            _dx = amount;
        } 
        else {
            _dx = purchasable;
        }
        
        _minDy = tenderSwap.calculateSwap(IERC20(address(flip)), _dx);
        stakeAggregator.aggregate(amount, _dx, _minDy, block.timestamp + 100);
    }
}

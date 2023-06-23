// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/utils/AggregatorV1.sol";
import "./MainMigration.sol";

contract AggregatorTest is MainMigration {

    function setUp() public {
        MainMigration migration = new MainMigration();

        vm.startPrank(owner);
        stflip.mint(owner, 1000*10**18);
        tenderSwap.addLiquidity([1000*decimalsMultiplier, 800*decimalsMultiplier], 0, block.timestamp + 100);
        vm.stopPrank();
    }

    function testFuzz_Calculate(uint256 lpAmount1_, uint256 lpAmount2_, uint256 targetPrice_, uint256 targetError_) public {
        uint256 flipBalance = flip.balanceOf(owner);
        uint256 stflipBalance = stflip.balanceOf(owner);
        
        uint256 lpAmount1 = bound(lpAmount1_, 1000, stflipBalance);
        uint256 lpAmount2 = bound(lpAmount1_, 1000, flipBalance);
        uint256 targetPrice = bound(targetPrice_, 980*10**(decimals-3), 1020*10**(decimals-3));
        uint256 targetError = bound(targetError_, 10**12, 10**16);
        vm.prank(owner);
        tenderSwap.addLiquidity([lpAmount1, lpAmount2], 0, block.timestamp);
        wrappedAggregatorProxy.calculatePurchasable(targetPrice, targetError, 1000);
    }

    function testFuzz_Aggregate(uint256 amount_, uint256 lpAmount1_, uint256 lpAmount2_) public {
        uint256 flipBalance = flip.balanceOf(owner);
        uint256 stflipBalance = stflip.balanceOf(owner);
       
        uint256 lpAmount1 = bound(lpAmount1_, 1000, stflipBalance);
        uint256 lpAmount2 = bound(lpAmount2_, 1000, flipBalance-100);
        uint256 amount = bound(amount_, 2, flipBalance - lpAmount2);
        console.log(amount_,lpAmount1_,lpAmount2_);
        console.log(amount,lpAmount1,lpAmount2);

        vm.startPrank(owner);
        tenderSwap.addLiquidity([lpAmount1, lpAmount2], 0, block.timestamp+100);
        uint256 purchasable = wrappedAggregatorProxy.calculatePurchasable(1003*10**(decimals - 3), 10**(decimals-2), 100);
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
        
        wrappedAggregatorProxy.stakeAggregate(amount, _dx, _minDy, block.timestamp + 100);
    }

    function testFuzz_UnstakeAggregate(bool instantUnstake, uint256 lpAmount1_, uint256 lpAmount2_, uint256 amountClaimable_, uint256 amountUnstake_) public {
        uint256 flipBalance = flip.balanceOf(owner);
        uint256 stflipBalance = stflip.balanceOf(owner);
       
        uint256 lpAmount1 = bound(lpAmount1_, 100000, stflipBalance / 2);
        uint256 lpAmount2 = bound(lpAmount2_, 100000, flipBalance / 2);
        uint256 amountClaimable = bound(amountClaimable_, 50000, flipBalance - lpAmount2);
        uint256 amountUnstake = bound(amountUnstake_, 1000000, stflipBalance - lpAmount1 );
        console.log(lpAmount1, lpAmount2, amountClaimable, amountUnstake);
        
        vm.startPrank(owner);
        tenderSwap.addLiquidity([lpAmount1, lpAmount2], 0, block.timestamp+100);
        wrappedBurnerProxy.deposit(amountClaimable);

        uint256 amountSwapOut = 0;
        uint256 amountInstantBurn;
        uint256 amountBurn;
        uint256 amountSwap;
        

        if (amountUnstake < amountClaimable) {
            amountInstantBurn = amountUnstake;
            amountBurn = 0;
            amountSwap = 0;
        }
        else {
            amountInstantBurn = amountClaimable;

            if (instantUnstake == true) {
                amountSwap = amountUnstake - amountInstantBurn;
                amountSwapOut = tenderSwap.calculateSwap(IERC20(address(stflip)), amountSwap);
                amountBurn = 0;
            } 
            else {
                amountSwap = 0;
                amountBurn = amountUnstake - amountInstantBurn;
            }
        }
        console.log(amountInstantBurn, amountBurn, amountSwap);
        wrappedAggregatorProxy.unstakeAggregate(amountInstantBurn, amountBurn, amountSwap, amountSwapOut, block.timestamp);

        vm.stopPrank();
    }

}

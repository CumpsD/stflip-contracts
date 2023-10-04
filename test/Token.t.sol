// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "./MainMigration.sol";
import "forge-std/console.sol";

contract MinterTest is MainMigration {
    address user1 = 0x0000000000000000000000000000000000000001;
    address user2 = 0x0000000000000000000000000000000000000002;
    address user3 = 0x0000000000000000000000000000000000000003;

    function setUp() public {
        MainMigration migration = new MainMigration();
    }

    function _relativelyEq(uint256 num1, uint256 num2) internal returns (bool) {
        return (num1 > num2) ? (num1 - num2 <= 10**13) : (num2 - num1 <= 10**13);
    }

    function testFuzz_SetRebase(uint256 factor1_, uint256 factor2_, uint256 interval_, uint256 initialSupply_, bool slash) public {
        
        uint256 interval = bound(interval_, 60*60 / 100, 60*60*24*7 / 100) * 100;
        uint256 initialSupply = bound(initialSupply_, 10**18, 100_000_000*10**18);
        uint256 user1InitialBalance = initialSupply / 3;
        uint256 user2InitialBalance = initialSupply * 2/ 3;
        uint256 oldRebaseFactor;
        uint256 newRebaseFactor;
        if (slash == true) {
            oldRebaseFactor = bound(factor1_, stflip.BASE() * 11 / 10, stflip.BASE()*10);
            newRebaseFactor = bound(factor2_, stflip.BASE(), oldRebaseFactor);
        }  else {
            oldRebaseFactor = bound(factor1_, stflip.BASE(), stflip.BASE()*9);
            newRebaseFactor = bound(factor2_, oldRebaseFactor, stflip.BASE()*10);
        }    

        console.log("stflip supply prior to setup", stflip.totalSupply());
        console.log("stflip rebase factor prior to setup", stflip.yamsScalingFactor());
        console.log("stflip init supply prior to setup", stflip.initSupply());

        vm.startPrank(owner);
            wrappedMinterProxy.mint(owner, 1);
            stflip.setRebase(0, oldRebaseFactor, 0);
            flip.mint(user1, user1InitialBalance);
            flip.mint(user2, user2InitialBalance);
        vm.stopPrank();

        vm.startPrank(user1);
            flip.approve(address(minter), 2**256-1);
            wrappedMinterProxy.mint(user1, user1InitialBalance);
        vm.stopPrank();

        vm.startPrank(user2);
            flip.approve(address(minter), 2**256-1);
            wrappedMinterProxy.mint(user2, user2InitialBalance);
        vm.stopPrank();

        console.log("stflip supply after setup", stflip.totalSupply());
        console.log("stflip init supply after setup", stflip.initSupply());


        vm.startPrank(owner);
            stflip.setRebase(interval_, newRebaseFactor, interval);


        console.log("expected v. actual user1 balance", user1InitialBalance, stflip.balanceOf(user1));
        console.log("expected v. actual user2 balance", user2InitialBalance, stflip.balanceOf(user2));
        require(_relativelyEq(stflip.balanceOf(user1),user1InitialBalance), "user1 balance changed");
        require(_relativelyEq(stflip.balanceOf(user2), user2InitialBalance), "user2 balance changed");
        require(_relativelyEq(stflip.totalSupply(), initialSupply), "total supply changed");
        uint256 jump = interval / 100; 
        uint256 expectedRebaseFactor;
        for (uint i = 1; i <= 100; i++) {
            vm.warp(jump*i + 1);
            
            if (slash == true) {
                expectedRebaseFactor = oldRebaseFactor - (oldRebaseFactor - newRebaseFactor) * i / 100;

            } else {
                expectedRebaseFactor = oldRebaseFactor + (newRebaseFactor - oldRebaseFactor) * i / 100;
            }

            console.log("expected v. actual rebase factor", expectedRebaseFactor, stflip.yamsScalingFactor());
            require(_relativelyEq(expectedRebaseFactor, stflip.yamsScalingFactor()), "rebase factor incorrect");
            require(expectedRebaseFactor == stflip.yamsScalingFactor(), "rebase factor incorrect");
        }

        vm.warp(jump*101 + 1);

        require(newRebaseFactor == stflip.yamsScalingFactor(), "rebase factor incorrect");

    }

    function testFuzz_InterruptRebase(uint256 factor1_, uint256 factor2_, uint256 factor3_, uint256 interval_,uint256 pctComplete_, uint256 initialSupply_, bool slash1, bool slash2) external {
        uint256 interval = bound(interval_, 60*60 / 100, 60*60*24*7 / 100) * 100;
        uint256 initialSupply = bound(initialSupply_, 10**18, 100_000_000*10**18);
        uint256 pctComplete = bound(pctComplete_, 0, 100);
        uint256 oldRebaseFactor;
        uint256 newRebaseFactor;
        uint256 newRebaseFactor2;

        if (slash1 == true) {
            oldRebaseFactor = bound(factor1_, stflip.BASE() * 11 / 10, stflip.BASE()*10);
            newRebaseFactor = bound(factor2_, stflip.BASE(), oldRebaseFactor);
        }  else {
            oldRebaseFactor = bound(factor1_, stflip.BASE(), stflip.BASE()*9);
            newRebaseFactor = bound(factor2_, oldRebaseFactor, stflip.BASE()*10);
        }

        if (slash2 == true) {
            newRebaseFactor2 = bound(factor3_, stflip.BASE(), newRebaseFactor);
        }else {
            newRebaseFactor2 = bound(factor3_, newRebaseFactor, stflip.BASE()*10);
        }

        vm.startPrank(owner);
            flip.mint(owner, initialSupply);
            stflip.mint(owner, 1);
            stflip.setRebase(0, oldRebaseFactor, interval);
            wrappedMinterProxy.mint(owner, initialSupply);
        vm.stopPrank();

        require(_relativelyEq(stflip.totalSupply(), initialSupply), "total supply changed");

        vm.warp(block.timestamp + interval * pctComplete / 100);
        uint256 scalingFactor = stflip.yamsScalingFactor();

        vm.startPrank(owner);
            stflip.setRebase(0, newRebaseFactor2, interval);

        require(stflip.yamsScalingFactor() == scalingFactor, "rebase factor incorrect");
        require(stflip.previousYamScalingFactor() == scalingFactor, "previous rebase factor incorrect");
        require(stflip.nextYamScalingFactor() == newRebaseFactor2, "next rebase factor incorrect");
        require(stflip.rebaseIntervalEnd() == block.timestamp + interval, "rebase interval incorrect");
        require(stflip.lastRebaseTimestamp() == block.timestamp);
            
    }


    // write a unit test for token transfers

}

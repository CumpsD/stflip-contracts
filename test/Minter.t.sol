// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/utils/Burner.sol";
import "./MainMigration.sol";


contract MinterTest is MainMigration {
    Minter public counter;
    address user1 = 0x0000000000000000000000000000000000000001;
    address user2 = 0x0000000000000000000000000000000000000002;
    address user3 = 0x0000000000000000000000000000000000000003;

    function setUp() public {
        MainMigration migration = new MainMigration();
    }

    function testFuzz_OneToOne(uint256 amountToMint_) public {      
        uint256 amountToMint = bound(amountToMint_, 0, 100_000_000*decimalsMultiplier);
        vm.startPrank(owner);
        flip.mint(user1, amountToMint);
        vm.stopPrank();

        uint256 initialFlipSupply = flip.totalSupply();
        uint256 initialStflipSupply = stflip.totalSupply();
        uint256 initialFlipBalance = flip.balanceOf(user1);
        uint256 initialStflipBalance = stflip.balanceOf(user1);

        vm.startPrank(user1);
        flip.approve(address(minter),amountToMint);
        minter.mint(user1,amountToMint);
        vm.stopPrank();

        require(initialFlipSupply == flip.totalSupply(), "flip supply change");
        require(initialStflipSupply + amountToMint == stflip.totalSupply(), "unexpected stflip supply change");
        require(initialFlipBalance - amountToMint == flip.balanceOf(user1), "unexpected flip balance change");
        require(initialStflipBalance + amountToMint == stflip.balanceOf(user1), "unexpected flip balance change");
    }
    
}

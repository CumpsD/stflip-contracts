// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/utils/Burner.sol";
import "./MainMigration.sol";


contract BurnerTest is MainMigration {
    Burner public counter;
    address user1 = 0x0000000000000000000000000000000000000001;
    address user2 = 0x0000000000000000000000000000000000000002;
    address user3 = 0x0000000000000000000000000000000000000003;

    function setUp() public {
        MainMigration migration = new MainMigration();

        vm.startPrank(owner);
        flip.mint(owner, 3000000*decimalsMultiplier);
        minter.mint(user1, 1000000*decimalsMultiplier);
        minter.mint(user2, 1000000*decimalsMultiplier);
        minter.mint(user3, 1000000*decimalsMultiplier);
        vm.stopPrank();

        vm.prank(user1);
        stflip.approve(address(burner),1000000*decimalsMultiplier);
        vm.prank(user2);
        stflip.approve(address(burner),1000000*decimalsMultiplier);
        vm.prank(user3);
        stflip.approve(address(burner),1000000*decimalsMultiplier);

    }

    function testFail_BurnOrder() public {
        // depositing some flip
        vm.prank(owner);
        burner.deposit(1000*decimalsMultiplier);

        // first user doing an instant burn for all the flip
        vm.startPrank(user1);
        uint256 id1 = burner.burn(user1, 1000*decimalsMultiplier);
        burner.redeem(user1,id1);
        vm.stopPrank();

        // depositing some more flip. 
        vm.prank(owner);
        burner.deposit(100*decimalsMultiplier);
        
        // doing a burn for the amount that was just deposited
        vm.prank(user1);
        uint256 id2 = burner.burn(user1,100*decimalsMultiplier);

        // also doing a burn for the amount that was just deposited, except claiming it right after
        vm.startPrank(user2);
        uint256 id3 = burner.burn(user2,100*decimalsMultiplier);
        burner.redeem(user2,id3);
        vm.stopPrank();

        console.log("uh oh");
    }

    function test_Burn() public {
        vm.prank(owner);
        burner.deposit(1000*decimalsMultiplier);

        vm.prank(user1);
        uint256 id1 = burner.burn(user1,100*decimalsMultiplier);

        vm.prank(user2);
        uint256 id2 = burner.burn(user2,500*decimalsMultiplier);

        vm.prank(user3);
        uint256 id3 = burner.burn(user3,400*decimalsMultiplier);
        
        vm.prank(user3);
        burner.redeem(user3,id3);

        vm.prank(user1);
        burner.redeem(user1,id1);

        vm.prank(user2);
        burner.redeem(user2,id2);

    }
    
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "./MainMigration.sol";


contract MinterTest is MainMigration {
    address user1 = 0x0000000000000000000000000000000000000001;
    address user2 = 0x0000000000000000000000000000000000000002;
    address user3 = 0x0000000000000000000000000000000000000003;

    function setUp() public {
        MainMigration migration = new MainMigration();
    }


    /**
     * @notice Fuzz function to ensure minting works as expected
     * @param amountToMint_ Amount to mint
     * @param rebaseFactor_ Ensure this holds for all rebase factors
     */
    function testFuzz_OneToOne(uint256 amountToMint_, uint256 rebaseFactor_) public {      
        uint256 amountToMint = bound(amountToMint_, 0, 100_000_000*decimalsMultiplier);
        uint256 rebaseFactor = bound(rebaseFactor_, stflip.BASE(), stflip.BASE()*10);

        vm.startPrank(owner);
            flip.mint(user1, amountToMint);
            stflip.mint(owner, 1);
            stflip.setRebase(0, rebaseFactor, 0);
        vm.stopPrank();

        uint256 initialFlipSupply = flip.totalSupply();
        uint256 initialStflipSupply = stflip.totalSupply();
        uint256 initialFlipBalance = flip.balanceOf(user1);
        uint256 initialStflipBalance = stflip.balanceOf(user1);

        vm.startPrank(user1);
            flip.approve(address(minter), 2**256-1);
            wrappedMinterProxy.mint(user1,amountToMint);
        vm.stopPrank();
        
        console.log("amount to mint",amountToMint);
        console.log("initial stflip supply",initialStflipSupply / 10**15);
        console.log("expected v. actual flip supply",initialFlipSupply,flip.totalSupply());
        console.log("expected v. actual stflip supply",initialStflipSupply + amountToMint,stflip.totalSupply());
        console.log("expected v. actual stflip balance",initialStflipBalance + amountToMint,stflip.balanceOf(user1), stflip.getVotes(user1));
        console.log("expected v. actual flip balance",initialFlipBalance - amountToMint,flip.balanceOf(user1));

        require(initialFlipSupply == flip.totalSupply(), "flip supply change");
        require(initialStflipSupply + amountToMint == stflip.totalSupply() || initialStflipSupply + amountToMint -1 == stflip.totalSupply(), "unexpected stflip supply change");
        require(initialFlipBalance - amountToMint == flip.balanceOf(user1), "unexpected flip balance change");
        // rebase token rounding :/
        require(initialStflipBalance + amountToMint == stflip.balanceOf(user1) || initialStflipBalance + amountToMint - 1 == stflip.balanceOf(user1), "unexpected stflip balance change");
    }
    
}

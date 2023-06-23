// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/utils/BurnerV1.sol";
import "./MainMigration.sol";


contract BurnerTest is MainMigration {
    
    address user1 = 0x0000000000000000000000000000000000000001;
    address user2 = 0x0000000000000000000000000000000000000002;
    address user3 = 0x0000000000000000000000000000000000000003;

    function setUp() public {
        MainMigration migration = new MainMigration();

        vm.startPrank(owner);
        flip.mint(owner, 3000000*decimalsMultiplier);
        wrappedMinterProxy.mint(user1, 1000000*decimalsMultiplier);
        wrappedMinterProxy.mint(user2, 1000000*decimalsMultiplier);
        wrappedMinterProxy.mint(user3, 1000000*decimalsMultiplier);
        vm.stopPrank();

        vm.prank(user1);
        stflip.approve(address(burner),1000000*decimalsMultiplier);
        vm.prank(user2);
        stflip.approve(address(burner),1000000*decimalsMultiplier);
        vm.prank(user3);
        stflip.approve(address(burner),1000000*decimalsMultiplier);


        vm.prank(owner);
        flip.mint(user1,1000000000000);
    }

    function testFail_BurnOrder() public {
        // depositing some flip
        vm.prank(owner);
        wrappedBurnerProxy.deposit(1000*decimalsMultiplier);

        // first user doing an instant burn for all the flip
        vm.startPrank(user1);
        uint256 id1 = wrappedBurnerProxy.burn(user1, 1000*decimalsMultiplier);
        wrappedBurnerProxy.redeem(id1);
        vm.stopPrank();

        // depositing some more flip. 
        vm.prank(owner);
        wrappedBurnerProxy.deposit(100*decimalsMultiplier);
        
        // doing a burn for the amount that was just deposited
        vm.prank(user1);
        uint256 id2 = wrappedBurnerProxy.burn(user1,100*decimalsMultiplier);

        // also doing a burn for the amount that was just deposited, except claiming it right after
        vm.startPrank(user2);
        uint256 id3 = wrappedBurnerProxy.burn(user2,100*decimalsMultiplier);
        wrappedBurnerProxy.redeem(id3);
        vm.stopPrank();

        console.log("uh oh");
    }

    function test_Burn() public {
        vm.prank(owner);
        wrappedBurnerProxy.deposit(1000*decimalsMultiplier);

        vm.prank(user1);
        uint256 id1 = wrappedBurnerProxy.burn(user1,100*decimalsMultiplier);

        vm.prank(user2);
        uint256 id2 = wrappedBurnerProxy.burn(user2,500*decimalsMultiplier);

        vm.prank(user3);
        uint256 id3 = wrappedBurnerProxy.burn(user3,400*decimalsMultiplier);
        
        vm.prank(user3);
        wrappedBurnerProxy.redeem(id3);

        vm.prank(user1);
        wrappedBurnerProxy.redeem(id1);

        vm.prank(user2);
        wrappedBurnerProxy.redeem(id2);

    }
    
    function test_ImportData() public {
        uint256 goerliFork = vm.createFork(vm.envString("GOERLI_RPC_URL"));
        vm.selectFork(goerliFork);
        vm.rollFork(8_700_200);
        MainMigration goerliMigration = new MainMigration();

        vm.startPrank(goerliMigration.wrappedBurnerProxy().gov());
        BurnerV1 burnerToImport = BurnerV1(0xD1cc80373acb7d172E1A2c4507B0A2693abBDEf1);
        BurnerV1 burner_ = goerliMigration.wrappedBurnerProxy();
        burner_.importData(burnerToImport);
        vm.stopPrank();

        vm.startPrank(goerliMigration.owner());
        console.log("flip balance ", goerliMigration.flip().balanceOf(goerliMigration.owner()));
        goerliMigration.flip().approve(address(burner_),2**100-1);
        goerliMigration.stflip().approve(address(burner_),2**100-1);
        uint256 depositAmount = burner_.totalPendingBurns();
        burner_.deposit(depositAmount);
        vm.stopPrank();

        uint256 burnLength = burner_.getAllBurns().length;
        address user;
        uint256 amount;
        bool completed;
        uint256 total = 0;
        for (uint i = 1; i < burnLength; i++) {

            (user, amount, completed) = burner_.burns(i);

            if (!completed) {  
                console.log("burn amount, balance var, contract balance", amount, burner_.balance(), goerliMigration.flip().balanceOf(address(burner_)));
                vm.prank(user);
                burner_.redeem(i);
                total += amount;
            }
        }
        
        require(goerliMigration.flip().balanceOf(address(burner_)) == 0, "actual balance not zero");
        require(burner_.balance() == 0, "balance var not zero");
        require(depositAmount == total, "deposited != withdrawn");
    }


}


// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/utils/BurnerV1.sol";
import "./MainMigration.sol";


contract MigrationTest is MainMigration {

    function setUp() public {
        MainMigration migration = new MainMigration();
    }

    function test_CanUpgrade() public {
        BurnerV1 newBurner = new BurnerV1();
        vm.prank(admin.owner());
        admin.upgrade(burner, address(newBurner));

        MinterV1 newMinter = new MinterV1();
        vm.prank(admin.owner());
        admin.upgrade(minter, address(newMinter));

        AggregatorV1 newAggregator = new AggregatorV1();
        vm.prank(admin.owner());
        admin.upgrade(aggregator, address(newAggregator));
    }

    function test_OnlyInitializeOnce() public {
        vm.expectRevert("Initializable: contract is already initialized");
        wrappedBurnerProxy.initialize(address(stflip), address(this), address(flip));

        vm.expectRevert("Initializable: contract is already initialized");
        wrappedMinterProxy.initialize(address(stflip), address(output), address(owner), address(flip), address(rebaser));

        vm.expectRevert("Initializable: contract is already initialized");
        wrappedAggregatorProxy.initialize(address(stflip), address(output), address(tenderSwap), address(owner), address(flip));
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "./MainMigration.sol";


contract OutputTest is MainMigration {
    address user1 = 0x0000000000000000000000000000000000000001;
    address user2 = 0x0000000000000000000000000000000000000002;
    address user3 = 0x0000000000000000000000000000000000000003;

    bytes32[] validators = new bytes32[](5);

    function setUp() public {
        MainMigration migration = new MainMigration();
        validators[0] = 0x0000000000000000000000000000000000000000000000000000000000000000;
        validators[1] = 0x0000000000000000000000000000000000000000000000000000000000000001;
        validators[2] = 0x0000000000000000000000000000000000000000000000000000000000000002;
        validators[3] = 0x0000000000000000000000000000000000000000000000000000000000000003;
        validators[4] = 0x0000000000000000000000000000000000000000000000000000000000000004;
    }

    function test_Sweep() public {
        vm.prank(owner);
        wrappedOutputProxy.sweep(validators);

    }
}

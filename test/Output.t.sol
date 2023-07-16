// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "./MainMigration.sol";
import "forge-std/console.sol";


contract OutputTest is MainMigration {
    using stdStorage for StdStorage;

    mapping (bytes32 => uint8) public removed;

    function setUp() public {
        MainMigration migration = new MainMigration();
    }

    /**
     * @notice Fuzz function to test adding validators
     * @param validators_ The validators to add
     * @param length_ The number of validators to add
     */
    function testFuzz_AddValidators(bytes32[50] memory validators_, uint256 length_) external {
        uint256 length = bound(length_, 1, 49);
        
        bytes32[] memory validators = new bytes32[](length);

        for (uint i = 0; i < length; i++) {
            validators[i] = validators_[i];
        }
        
        vm.prank(owner);
            wrappedOutputProxy.addValidators(validators);

        for (uint i = 0; i < length; i++) {
            require(wrappedOutputProxy.validators(validators[i]) == true, "testFuzz_AddValidators: validators not imported correctly");
        }

    }

    /**
     * @notice Fuzz function to test removing validators
     * @param validators_ The validators to add/remove
     * @param length_ The index to add validators until
     * @param remove_ The index to remove validators until
     */
    function testFuzz_RemoveValidators(bytes32[50] memory validators_, uint256 length_, uint256 remove_) external {
        uint256 length = bound(length_, 1, 49);
        uint256 remove = bound(remove_, 1, length);

        bytes32[] memory validatorsToAdd = new bytes32[](length);
        bytes32[] memory validatorsToRemove = new bytes32[](remove);

        for (uint i = 0; i < length; i++) {
            validatorsToAdd[i] = validators_[i];
        }
        
        for (uint i = 0; i < remove; i++) {
            validatorsToRemove[i] = validators_[i];
            removed[validators_[i]] = 1;
        }

        vm.startPrank(owner);
            wrappedOutputProxy.addValidators(validatorsToAdd);
            wrappedOutputProxy.removeValidators(validatorsToRemove);
        vm.stopPrank();

        for (uint i = 0; i < length; i++) {
            if (removed[validators_[i]] == 1) {
                require(wrappedOutputProxy.validators(validators_[i]) == false, "testFuzz_RemoveValidators: validators not removed correctly");
            } else {
                require(wrappedOutputProxy.validators(validators_[i]) == true, "testFuzz_RemoveValidators: validators not imported correctly");
            }
        }
    }

    /**
     * @notice Fuzz function to test staking validators
     * @param validators_ The validators to stake
     * @param length_ The number of validators to stake
     * @param amounts_ The amounts to stake
     */
    function testFuzz_StakeValidators(bytes32[50] memory validators_, uint256 length_, uint8[50] memory amounts_) external {
        uint256 length = bound(length_, 1, 49);
        
        bytes32[] memory validators = new bytes32[](length);
        uint256[] memory amounts = new uint256[](length);
        uint256 total = 0;

        for (uint i = 0; i < length; i++) {
            validators[i] = validators_[i];
            amounts[i] = uint256(amounts_[i]) * 2 * 10**18;
            total += amounts[i];
        }
        
        vm.startPrank(owner);
            flip.mint(address(wrappedOutputProxy),2**100);
            uint256 initialBalance = flip.balanceOf(address(wrappedOutputProxy));
            wrappedOutputProxy.addValidators(validators);
            wrappedOutputProxy.fundValidators(validators, amounts);
        vm.stopPrank();
        
        uint256 expectedBalance =  flip.balanceOf(address(wrappedOutputProxy)) + total;
        require(initialBalance == expectedBalance, "testFuzz_StakeValidators: output balance unnecessarily changed");
    }

    /**
     * @notice Fuzz function to test unstaking validators
     * @param validators_ The validators to unstake
     * @param length_ The number of validators to unstake
     */
    function testFuzz_UnstakeValidators(bytes32[50] memory validators_, uint256 length_) external {
        uint256 length = bound(length_, 1, 49);
        
        bytes32[] memory validators = new bytes32[](length);

        for (uint i = 0; i < length; i++) {
            validators[i] = validators_[i];
        }
        
        uint256 initialBalance = flip.balanceOf(address(wrappedOutputProxy));
        vm.prank(owner);
            wrappedOutputProxy.redeemValidators(validators);
        uint256 currentBalance = flip.balanceOf(address(wrappedOutputProxy));

        require(currentBalance > initialBalance, "testFuzz_UnstakeValidators: output balance did not increase");
    }
}

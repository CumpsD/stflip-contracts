// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "./MainMigration.sol";
import "forge-std/console.sol";


contract OutputTest is MainMigration {
    using stdStorage for StdStorage;

    mapping (bytes32 => uint8) public removed;

    function setUp() public {
        MainMigration migration = new MainMigration();
    }
    
    struct Operator {
        uint256 staked;
        uint256 unstaked;
        uint256 serviceFeeBps;
        uint256 validatorFeeBps;
        string name;
        bool whitelisted;
        address manager;
        address feeRecipient;
    }


    function testFuzz_AddOperator(address[50] calldata managers, string[50] calldata names, uint256[50] calldata serviceFeeBps_, uint256[50] calldata validatorFeeBps_, uint256 count_) external {
        uint256 count = bound(count_, 2, 50);
        uint256[] memory serviceFeeBpsList = new uint256[](count);
        uint256[] memory validatorFeeBpsList = new uint256[](count);

        for (uint i = 0; i < count; i++) {
            serviceFeeBpsList[i] = bound(serviceFeeBps_[i], 0, 10000);
            validatorFeeBpsList[i] = bound(validatorFeeBps_[i], 0, 10000 - serviceFeeBpsList[i]);
        }

        vm.startPrank(owner);
        for (uint i = 1; i < count; i++) {
            wrappedOutputProxy.addOperator(managers[i], names[i], serviceFeeBpsList[i], validatorFeeBpsList[i]);
        }

        // string memory name;
        // bool whitelisted;
        // address manager;
        // address feeRecipient;
        // uint256 staked;
        // uint256 unstaked;
        // uint256 serviceFeeBps;
        // uint256 validatorFeeBps;

        Operator memory operator;

        for (uint i = 1; i < count; i++) {
            operator = _getOperator(i);
            console.log(operator.name, names[i]);
            require(keccak256(abi.encodePacked(operator.name)) == keccak256(abi.encodePacked(names[i])), "testFuzz_AddOperator: name not imported correctly");
            require(operator.whitelisted == true, "testFuzz_AddOperator: whitelisted not imported correctly");
            require(operator.manager == managers[i], "testFuzz_AddOperator: manager not imported correctly");
            require(operator.feeRecipient == managers[i], "testFuzz_AddOperator: feeRecipient not imported correctly");
            require(operator.staked == 0, "testFuzz_AddOperator: staked not imported correctly");
            require(operator.unstaked == 0, "testFuzz_AddOperator: unstaked not imported correctly");
            require(operator.serviceFeeBps == serviceFeeBpsList[i], "testFuzz_AddOperator: serviceFeeBps not imported correctly");
            require(operator.validatorFeeBps == validatorFeeBpsList[i], "testFuzz_AddOperator: validatorFeeBps not imported correctly");
        }
    }

    function _getOperator (uint256 id) internal returns (Operator memory) {
        Operator memory operator;
        (operator.staked, operator.unstaked, operator.serviceFeeBps, operator.validatorFeeBps, operator.name, operator.whitelisted, operator.manager, operator.feeRecipient) = wrappedOutputProxy.operators(id);
        return operator;
    }

    
    function testFuzz_FundValidators(bytes32[50] calldata addresses_, uint256[50] calldata amounts_, uint256[50] calldata order_) external {

        uint256[] memory amounts = new uint256[](50);
        uint256[] memory order = new uint256[](50);
        uint256[12] memory operatorBalances;
        bytes32[] memory addresses = new bytes32[](50);
        uint256 staked;
        uint256 total;
        bytes32[] memory inp = new bytes32[](1);
        for (uint i = 0; i < 50; i++) {
            amounts[i] = bound(amounts_[i], 0, 150_000*10**18);
            
            order[i] = bound(order_[i], 1, 9);
            addresses[i] = keccak256(abi.encodePacked(addresses[i],i));
            operatorBalances[order[i]] += amounts[i];
            total += amounts[i];
        }
        
        vm.startPrank(owner);
            for (uint i = 1; i < 10; i++) {
                wrappedOutputProxy.addOperator(address(uint160(i)), vm.toString(i), 0, 0);
            }

            flip.mint(owner, total);
            wrappedMinterProxy.mint(owner, total);
        vm.stopPrank();

        for (uint i = 0; i < 50; i++) {
            vm.prank(address(uint160(order[i])));
                inp[0] = addresses[i];
                wrappedOutputProxy.addValidators(inp, order[i]);
        }

        vm.startPrank(owner);
            wrappedOutputProxy.setValidatorsWhitelist(addresses,true);
            wrappedOutputProxy.fundValidators(addresses, amounts);
        vm.stopPrank();

        for (uint i = 1; i < 10; i++) {
            require(_getOperator(i).staked == operatorBalances[i], "testFuzz_FundValidators: staked not updated correctly");
        }
        
    }

    // /**u
    //  * @notice Fuzz function to test adding validators
    //  * @param validators_ The validators to add
    //  * @param length_ The number of validators to add
    //  */
    // function testFuzz_AddValidators(bytes32[50] memory validators_, uint256 length_) external {
    //     uint256 length = bound(length_, 1, 49);
        
    //     bytes32[] memory validators = new bytes32[](length);

    //     for (uint i = 0; i < length; i++) {
    //         validators[i] = validators_[i];
    //     }
        
    //     vm.prank(owner);
    //         wrappedOutputProxy.addValidators(validators);

    //     for (uint i = 0; i < length; i++) {
    //         require(wrappedOutputProxy.validators(validators[i]) == true, "testFuzz_AddValidators: validators not imported correctly");
    //     }

    // }

    // /**
    //  * @notice Fuzz function to test removing validators
    //  * @param validators_ The validators to add/remove
    //  * @param length_ The index to add validators until
    //  * @param remove_ The index to remove validators until
    //  */
    // function testFuzz_RemoveValidators(bytes32[50] memory validators_, uint256 length_, uint256 remove_) external {
    //     uint256 length = bound(length_, 1, 49);
    //     uint256 remove = bound(remove_, 1, length);

    //     bytes32[] memory validatorsToAdd = new bytes32[](length);
    //     bytes32[] memory validatorsToRemove = new bytes32[](remove);

    //     for (uint i = 0; i < length; i++) {
    //         validatorsToAdd[i] = validators_[i];
    //     }
        
    //     for (uint i = 0; i < remove; i++) {
    //         validatorsToRemove[i] = validators_[i];
    //         removed[validators_[i]] = 1;
    //     }

    //     vm.startPrank(owner);
    //         wrappedOutputProxy.addValidators(validatorsToAdd);
    //         wrappedOutputProxy.removeValidators(validatorsToRemove);
    //     vm.stopPrank();

    //     for (uint i = 0; i < length; i++) {
    //         if (removed[validators_[i]] == 1) {
    //             require(wrappedOutputProxy.validators(validators_[i]) == false, "testFuzz_RemoveValidators: validators not removed correctly");
    //         } else {
    //             require(wrappedOutputProxy.validators(validators_[i]) == true, "testFuzz_RemoveValidators: validators not imported correctly");
    //         }
    //     }
    // }

    // /**
    //  * @notice Fuzz function to test staking validators
    //  * @param validators_ The validators to stake
    //  * @param length_ The number of validators to stake
    //  * @param amounts_ The amounts to stake
    //  */
    // function testFuzz_StakeValidators(bytes32[50] memory validators_, uint256 length_, uint8[50] memory amounts_) external {
    //     uint256 length = bound(length_, 1, 49);
        
    //     bytes32[] memory validators = new bytes32[](length);
    //     uint256[] memory amounts = new uint256[](length);
    //     uint256 total = 0;

    //     for (uint i = 0; i < length; i++) {
    //         validators[i] = validators_[i];
    //         amounts[i] = uint256(amounts_[i]) * 2 * 10**18;
    //         total += amounts[i];
    //     }
        
    //     vm.startPrank(owner);
    //         flip.mint(address(wrappedOutputProxy),2**100);
    //         uint256 initialBalance = flip.balanceOf(address(wrappedOutputProxy));
    //         wrappedOutputProxy.addValidators(validators);
    //         wrappedOutputProxy.fundValidators(validators, amounts);
    //     vm.stopPrank();
        
    //     uint256 expectedBalance =  flip.balanceOf(address(wrappedOutputProxy)) + total;
    //     require(initialBalance == expectedBalance, "testFuzz_StakeValidators: output balance unnecessarily changed");
    // }

    // /**
    //  * @notice Fuzz function to test unstaking validators
    //  * @param validators_ The validators to unstake
    //  * @param length_ The number of validators to unstake
    //  */
    // function testFuzz_UnstakeValidators(bytes32[50] memory validators_, uint256 length_) external {
    //     uint256 length = bound(length_, 1, 49);
        
    //     bytes32[] memory validators = new bytes32[](length);

    //     for (uint i = 0; i < length; i++) {
    //         validators[i] = validators_[i];
    //     }
        
    //     uint256 initialBalance = flip.balanceOf(address(wrappedOutputProxy));
    //     vm.prank(owner);
    //         wrappedOutputProxy.redeemValidators(validators);
    //     uint256 currentBalance = flip.balanceOf(address(wrappedOutputProxy));

    //     require(currentBalance > initialBalance, "testFuzz_UnstakeValidators: output balance did not increase");
    // }
}

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/utils/Sweeper.sol";
import "./MainMigration.sol";

contract SweeperTest is MainMigration {
    function setUp() public {
        MainMigration migration = new MainMigration();

        vm.startPrank(owner);
        flip.mint(owner, 1000 * decimalsMultiplier);
        vm.stopPrank();
    }

    function test_Disperse() public {
        vm.startPrank(owner);
        address[] memory users = new address[](3);
        users[0] = 0x0000000000000000000000000000000000000001;
        users[1] = 0x0000000000000000000000000000000000000002;
        users[2] = 0x0000000000000000000000000000000000000003;
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 50;
        amounts[1] = 100;
        amounts[2] = 150;

        uint256 deposit = 200;

        sweeper.disperseToken(users, amounts, deposit);

        for (uint i = 0; i < users.length; i++) {
            require(flip.balanceOf(users[i]) == amounts[i], "wrong amount");
        }

        require(
            burner.balance() == deposit,
            "burner was transferred, not deposited"
        );
        vm.stopPrank();
    }
}

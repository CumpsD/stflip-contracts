pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/utils/BurnerV1.sol";
import "../src/token/stFlip.sol";

contract BurnerQuery is Script {
    struct burn_ {
        address user;
        uint256 amount;
        bool completed;
    }

    burn_[] public burns;

    function run() external {

        stFlip stflip = stFlip(vm.envAddress("STFLIP_ADDRESS"));
        stFlip flip = stFlip(vm.envAddress("FLIP_ADDRESS"));
        BurnerV1 burner = BurnerV1(vm.envAddress("BURNER_ADDRESS"));
        
        BurnerV1.burn_[] memory burnerBurns = burner.getAllBurns();
        
        for (uint256 i = 0; i < burnerBurns.length; i++) {
            console.log(i);
            console.log(burnerBurns[i].user, burnerBurns[i].amount / 10**17, burnerBurns[i].completed, burner.redeemable(i));
        }
        console.log(burnerBurns.length);
    }
}

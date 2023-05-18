pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/utils/BurnerV1.sol";
import "../src/token/stFlip.sol";

contract BurnerScript is Script {
    function run() external {
        // uint256 govKey = vm.envUint("GOV_PRIVATE_KEY");
        // stFlip stflip = stFlip(vm.envAddress("STFLIP_ADDRESS"));
        // stFlip flip = stFlip(vm.envAddress("FLIP_ADDRESS"));
        // vm.startBroadcast(govKey);
        // //0xD1cc80373acb7d172E1A2c4507B0A2693abBDEf1 
        // BurnerV1 oldBurner = Burner(0xcde75a4a795D70B68c4FCF387C0B30EB7faF6aEE);
        // Burner newBurner = new Burner(
        //     address(stflip),
        //     vm.addr(govKey),
        //     address(flip)
        // );

        // newBurner.importData(oldBurner);
        
        // uint256 withdrawAmount = flip.balanceOf(address(oldBurner));
        
        // oldBurner.govWithdraw(withdrawAmount);
        
        // flip.approve(address(newBurner),withdrawAmount);
        // newBurner.deposit(withdrawAmount);

        // vm.stopBroadcast();
    }
}
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/utils/Burner.sol";
import "../src/token/stFlip.sol";

contract BurnerScript is Script {
    function run() external {
        uint256 govKey = vm.envUint("GOV_PRIVATE_KEY");
        stFlip stflip = stFlip(vm.envAddress("STFLIP_ADDRESS"));
        stFlip flip = stFlip(vm.envAddress("FLIP_ADDRESS"));
        vm.startBroadcast(govKey);
        //0xD1cc80373acb7d172E1A2c4507B0A2693abBDEf1 
        Burner oldBurner = Burner(0xD7Bd2F1934f1DA7E3C2F4d3C2B954b17d9e00642);
        Burner newBurner = new Burner(
            address(stflip),
            vm.addr(govKey),
            address(flip)
        );

        newBurner.importData(oldBurner);
        
        uint256 withdrawAmount = flip.balanceOf(address(oldBurner));
        
        oldBurner.govWithdraw(withdrawAmount);
        
        flip.approve(address(newBurner),withdrawAmount);
        newBurner.deposit(withdrawAmount);

        vm.stopBroadcast();
    }
}
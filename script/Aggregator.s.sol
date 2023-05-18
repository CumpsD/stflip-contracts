// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/utils/AggregatorV1.sol";

contract CounterScript is Script {


    function run() public {
        uint256 govKey = vm.envUint("GOV_PRIVATE_KEY");

        vm.startBroadcast(govKey);

        // AggregatorV1 aggregator = new Aggregator(
        //     vm.envAddress("MINTER_ADDRESS"),
        //     vm.envAddress("BURNER_ADDRESS"),
        //     vm.envAddress("TENDERSWAP_ADDRESS"),
        //     vm.envAddress("STFLIP_ADDRESS"),
        //     vm.envAddress("FLIP_ADDRESS")
        // );

        vm.stopBroadcast();
    }
}

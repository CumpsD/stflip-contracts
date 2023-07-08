pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../../src/deploy/DeployV1.sol";
import "../../lib/safe-tools/src/SafeTestTools.sol";

import "../../src/token/stFlip.sol";
import "../../src/token/stFlip.sol";
import "../../src/utils/AggregatorV1.sol";
import "../../src/utils/MinterV1.sol";
import "../../src/utils/BurnerV1.sol";
import "../../src/utils/OutputV1.sol";
import "../../src/utils/RebaserV1.sol";
import "../../src/utils/Sweeper.sol";


import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract NewRebaser is Script {


    function run() external {
        
        vm.startBroadcast(vm.envUint("GOV_PK"));
            RebaserV1 rebaserV1 = new RebaserV1();
            console.log("new rebaser impl", address(rebaserV1));

            ProxyAdmin admin = ProxyAdmin(vm.envAddress("PROXY_ADMIN"));
            admin.upgrade(
                            TransparentUpgradeableProxy(payable(vm.envAddress("REBASER"))), 
                            address(rebaserV1)
                        );


        vm.stopBroadcast();
    }
}
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


import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract NewAggregator is Script {


    function run() external {
        
        vm.startBroadcast(vm.envUint("GOV_PK"));
            AggregatorV1 aggregatorV1 = new AggregatorV1();
            console.log("new aggregator impl", address(aggregatorV1));

            ProxyAdmin admin = ProxyAdmin(vm.envAddress("PROXY_ADMIN"));

            address aggregatorProxy = vm.envAddress("AGGREGATOR");
            admin.upgrade(
                            TransparentUpgradeableProxy(payable(aggregatorProxy)), 
                            address(aggregatorV1)
                        );

            console.log("upgraded aggregator ", aggregatorProxy, " to ", address(aggregatorV1));


        vm.stopBroadcast();
    }
}
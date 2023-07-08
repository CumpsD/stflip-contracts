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

contract NewBurner is Script {


    function run() external {
        
        vm.startBroadcast(vm.envUint("GOV_PK"));
            BurnerV1 burnerV1 = new BurnerV1();
            console.log("new burner impl", address(burnerV1));

            ProxyAdmin admin = ProxyAdmin(vm.envAddress("PROXY_ADMIN"));

            address burnerProxy = vm.envAddress("BURNER");
            admin.upgrade(
                            TransparentUpgradeableProxy(payable(burnerProxy)), 
                            address(burnerV1)
                        );

            console.log("upgraded burner ", burnerProxy, " to ", address(burnerV1));


        vm.stopBroadcast();
    }
}
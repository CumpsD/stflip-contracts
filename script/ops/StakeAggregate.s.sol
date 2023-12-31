pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../../src/deploy/DeployV1.sol";

import "../../src/token/stFlip.sol";
import "../../src/token/stFlip.sol";
import "../../src/utils/AggregatorV1.sol";
import "../../src/utils/MinterV1.sol";
import "../../src/utils/BurnerV1.sol";
import "../../src/utils/OutputV1.sol";
import "../../src/utils/RebaserV1.sol";


import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract StakeAggregate is Script {


    function run() external {
        
        vm.startBroadcast();
            address aggregatorProxy = vm.envAddress("AGGREGATOR");
            stFlip flip = stFlip(vm.envAddress("FLIP"));
            stFlip stflip = stFlip(vm.envAddress("STFLIP"));

            // vm.startPrank(vm.envAddress("CONTRACTSIG"));
            //     AggregatorV1(aggregatorProxy).setPool(vm.envAddress("LIQUIDITYPOOL"));
            // vm.stopPrank();

            // AggregatorTestnetV1(aggregatorProxy).stakeAggregate(1000*10**18, 100*10**18, 0, 99999999999999999);
            stflip.approve(address(aggregatorProxy), 2**256 -1 );
            flip.approve(address(aggregatorProxy), 0);

            AggregatorV1(aggregatorProxy).unstakeAggregate(172684374519099366658, 0, 0, 0);


        vm.stopBroadcast();
    }
}
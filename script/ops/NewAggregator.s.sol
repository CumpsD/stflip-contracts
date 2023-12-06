// pragma solidity ^0.8.0;

// import "forge-std/Script.sol";
// import "forge-std/console.sol";

// import "../../src/deploy/DeployV1.sol";

// import "../../src/token/stFlip.sol";
// import "../../src/token/stFlip.sol";
// import "../../src/utils/AggregatorV1.sol";
// import "../../src/utils/MinterV1.sol";
// import "../../src/utils/BurnerV1.sol";
// import "../../src/utils/OutputV1.sol";
// import "../../src/utils/RebaserV1.sol";
// import "../../src/testnet/AggregatorTestnetV1.sol";


// import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
// import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

// contract NewAggregator is Script {


//     function run() external {
        
//         vm.startBroadcast(vm.envUint("SIGNER1KEY"));
//             AggregatorTestnetV1 aggregatorV1 = new AggregatorTestnetV1();
//             console.log("new aggregator impl", address(aggregatorV1));

//             ProxyAdmin admin = ProxyAdmin(vm.envAddress("PROXYADMIN"));

//             address aggregatorProxy = vm.envAddress("AGGREGATOR");
//             bytes memory data;
//             // admin.upgradeAndCall(
//             //                 ITransparentUpgradeableProxy(payable(aggregatorProxy)), 
//             //                 address(aggregatorV1),
//             //                 data
//             //             );

//             // console.log("upgraded aggregator ", aggregatorProxy, " to ", address(aggregatorV1));


//         vm.stopBroadcast();
//     }
// }
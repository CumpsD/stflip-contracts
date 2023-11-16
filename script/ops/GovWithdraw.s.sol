// pragma solidity ^0.8.0;

// import "forge-std/Script.sol";
// import "forge-std/console.sol";

// import "../../src/deploy/DeployV1.sol";

// import "../../src/token/stFlip.sol";
// import "../../src/token/stFlip.sol";
// import "../../src/testnet/AggregatorTestnetV1.sol";
// import "../../src/utils/MinterV1.sol";
// import "../../src/utils/BurnerV1.sol";
// import "../../src/utils/OutputV1.sol";
// import "../../src/utils/RebaserV1.sol";


// import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
// import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

// contract NewAggregator is Script {


//     function run() external {
        
//         vm.startBroadcast(vm.envUint("GOVPK"));
//             address output = vm.envAddress("OUTPUT");
//             OutputV1(output).govWithdraw(70_000 * 10**18);


//         vm.stopBroadcast();
//     }
// }
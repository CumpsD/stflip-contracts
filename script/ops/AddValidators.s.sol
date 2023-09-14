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


// import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
// import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

// contract AddValidators is Script {

//     function run() external {
//         bytes32[] memory validators = new bytes32[](5);


//         validators[0] = 0xb8184be3f8bfad432ae5e2da610875ab5911a79e9d872d5f7bc59bd8d92fd55c;
//         validators[1] = 0x28be50bf4746307421961d4ba8114dc89321025b98176677f14a296059c12b07;
//         validators[2] = 0x001e4dd8c04c0f98e805dbc54ea30d04de1fbd0c4b5bbd88b0ef01faa21a4b1c;
//         validators[3] = 0x2e60e2b07027c7a407f149a322c6fa8bd9d2a7c1ec6ed6facdbfb9f0e30ba103;
//         validators[4] = 0x6653cd5180535fb3e3808c2af1a2051b29253472a52d422dc59bf05bb75d0e18;

//         OutputV1 wrappedOutputProxy = OutputV1(vm.envAddress("OUTPUT"));
//         vm.startBroadcast(vm.envUint("GOV_PK"));
        
//             wrappedOutputProxy.addValidators(validators);


//         vm.stopBroadcast();
//     }
// }
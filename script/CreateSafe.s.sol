// pragma solidity ^0.8.0;

// import "forge-std/Script.sol";
// import "forge-std/console.sol";

// import "../src/deploy/DeployV1.sol";
// import "../lib/safe-tools/src/SafeTestTools.sol";

// import "../src/token/stFlip.sol";
// import "../src/token/stFlip.sol";
// import "../src/utils/AggregatorV1.sol";
// import "../src/utils/MinterV1.sol";
// import "../src/utils/BurnerV1.sol";
// import "../src/utils/OutputV1.sol";
// import "../src/utils/RebaserV1.sol";
// import "../src/utils/Sweeper.sol";


// import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
// import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

// import "@safe/proxies/GnosisSafeProxyFactory.sol";
// import "@safe/proxies/GnosisSafeProxy.sol";
// import "@safe/GnosisSafe.sol";

// contract BurnerScript is Script, SafeTestTools {
//     using SafeTestLib for SafeInstance;

//     TenderSwap public tenderSwap;

//     stFlip public stflip;

//     ProxyAdmin public admin;

//     TransparentUpgradeableProxy public minter;
//     MinterV1 public minterV1;
//     MinterV1 public wrappedMinterProxy;

//     TransparentUpgradeableProxy public burner;
//     BurnerV1 public burnerV1;
//     BurnerV1 public wrappedBurnerProxy;

//     TransparentUpgradeableProxy public aggregator;
//     AggregatorV1 public aggregatorV1;
//     AggregatorV1 public wrappedAggregatorProxy;

//     TransparentUpgradeableProxy public output;
//     OutputV1 public outputV1;
//     OutputV1 public wrappedOutputProxy;

//     TransparentUpgradeableProxy public rebaser;
//     RebaserV1 public rebaserV1;
//     RebaserV1 public wrappedRebaserProxy;

//     uint8 public decimals = 18;
//     uint256 public decimalsMultiplier = 10**decimals;
//     address singleton = 0x3E5c63644E683549055b9Be8653de26E0B4CD36E;
//     function run() external {
        
//         address gov = 0x584a697DC2b125117d232Fca046f6cDe5Edd0ba7;
//         address flip = 0x1194C91d47Fc1b65bE18db38380B5344682b67db;
//         address liquidityPool = 0x1b61874F49e63014865696e0A1CBa5926C516cDF;
//         address stateChainGateway = 0xC960C4eEe4ADf40d24374D85094f3219cf2DD8EB;
//         address manager = 0xfEE0000000000000000000000000000000000000;
//         address feeRecipient = 0xfEE0000000000000000000000000000000000000;

//         vm.startBroadcast(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80);
//             SafeInstance memory safeInstance = _setupSafe();
            
//             console.log("safe at ", address(safeInstance.safe));
//         vm.stopBroadcast();
//     }
// }
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

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
// import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

// contract AddLiquidity is Script {

//     function run() external {
//         vm.startBroadcast(vm.envUint("USER_PK"));
//             TenderSwap tenderSwap = TenderSwap(vm.envAddress("TENDERSWAP"));
            
//             IERC20 flip = IERC20(vm.envAddress("FLIP"));
//             IERC20 stflip = IERC20(vm.envAddress("STFLIP"));

//             uint256[2] memory amounts;

//             amounts[0] = 30000*10**18;
//             amounts[1] = 5000*10**18;

//             stflip.approve(address(tenderSwap), 2**256-1);
//             flip.approve(address(tenderSwap), 2**256-1);

//             tenderSwap.addLiquidity(amounts, 0, 1798382716);
//         vm.stopBroadcast();
//     }
// }
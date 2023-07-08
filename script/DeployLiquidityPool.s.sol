pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/deploy/DeployV1.sol";
import "../lib/safe-tools/src/SafeTestTools.sol";

import "../src/token/stFlip.sol";
import "../src/token/stFlip.sol";
import "../src/utils/AggregatorV1.sol";
import "../src/utils/MinterV1.sol";
import "../src/utils/BurnerV1.sol";
import "../src/utils/OutputV1.sol";
import "../src/utils/RebaserV1.sol";
import "../src/utils/Sweeper.sol";


import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract DeployLiquidityPool is Script {

    TenderSwap public tenderSwap;

    ProxyAdmin public admin;

    TransparentUpgradeableProxy public minter;
    MinterV1 public minterV1;
    MinterV1 public wrappedMinterProxy;

    TransparentUpgradeableProxy public burner;
    BurnerV1 public burnerV1;
    BurnerV1 public wrappedBurnerProxy;

    TransparentUpgradeableProxy public aggregator;
    AggregatorV1 public aggregatorV1;
    AggregatorV1 public wrappedAggregatorProxy;

    TransparentUpgradeableProxy public output;
    OutputV1 public outputV1;
    OutputV1 public wrappedOutputProxy;

    TransparentUpgradeableProxy public rebaser;
    RebaserV1 public rebaserV1;
    RebaserV1 public wrappedRebaserProxy;

    uint8 public decimals = 18;
    uint256 public decimalsMultiplier = 10**decimals;

    function run() external {
        
        address flip = 0x1194C91d47Fc1b65bE18db38380B5344682b67db;
        address stflip = 0xfA6A8a263b645B55dfa8dfbD24cC7bDdD0B5A2a4;
        vm.startBroadcast(vm.envUint("GOV_PK"));
            tenderSwap = new TenderSwap();
            LiquidityPoolToken liquidityPoolToken = new LiquidityPoolToken();
            tenderSwap.initialize(IERC20(address(stflip)), IERC20(address(flip)), "FLIP-stFLIP LP Token", "FLIP-stFLIP", 10, 10**7, 0, liquidityPoolToken);

            console.log("tenderSwap: ", address(tenderSwap));
            console.log("lp token", address(liquidityPoolToken));
        vm.stopBroadcast();
    }
}
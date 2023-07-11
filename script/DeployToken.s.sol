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


import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract DeployToken is Script {
    using SafeTestLib for SafeInstance;

    TenderSwap public tenderSwap;

    stFlip public stflip;

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
        
        address gov = 0xFb34E9990B8eb2E1BE61747AB62896964823967C;


        vm.startBroadcast(vm.envUint("GOV_PK"));
        // creating token
            stflip = new stFlip();
            stflip.initialize("Staked Flip", "stFLIP", decimals, gov, 0);
            console.log("deploy and init token at", address(stflip));


        vm.stopBroadcast();
    }
}
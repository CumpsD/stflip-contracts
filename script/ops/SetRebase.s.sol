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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract CalculateSwap is Script {

    function run() external {
        RebaserV1 wrappedRebaserProxy = RebaserV1(vm.envAddress("REBASER"));

        vm.startBroadcast(vm.envUint("GOV_PK"));

        wrappedRebaserProxy.rebase(3, 92140636347596096000000, true);

        vm.stopBroadcast();
    }
}
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../../src/token/stFlip.sol";
import "../../src/utils/AggregatorV1.sol";
import "../../src/utils/MinterV1.sol";
import "../../src/utils/BurnerV1.sol";
import "../../src/utils/OutputV1.sol";
import "../../src/utils/RebaserV1.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract SetRebase is Script {

    function run(bytes32[] memory validators, uint256[] memory amounts) external {
        RebaserV1 wrappedRebaserProxy = RebaserV1(vm.envAddress("REBASER"));

        vm.startBroadcast();

        wrappedRebaserProxy.rebase(3, amounts,validators, true);

        vm.stopBroadcast();
    }
}
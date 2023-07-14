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
        TenderSwap tenderSwap = TenderSwap(vm.envAddress("TENDERSWAP"));

        tenderSwap.calculateSwap(IERC20(0x1194C91d47Fc1b65bE18db38380B5344682b67db), 111000000000000000000);
    }
}
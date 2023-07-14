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

contract Swap is Script {

    function run() external {
        TenderSwap tenderSwap = TenderSwap(vm.envAddress("TENDERSWAP"));


        address addy = vm.envAddress("STFLIP");



        vm.startBroadcast(vm.envUint("USER_PK"));
           
             IERC20(addy).approve(addy, 2**256 - 1);

           tenderSwap.swap(IERC20(vm.envAddress("STFLIP")),
                            10000*10**18,
                            0,
                            9999999999);


        vm.stopBroadcast();
    }
}
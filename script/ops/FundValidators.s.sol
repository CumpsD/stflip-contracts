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


import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract FundValidators is Script {

    function run() external {
        bytes32[] memory validators = new bytes32[](2);


        validators[0] = 0x0e267a96e4b870016a58415b1939f3b0a0902ef6897e28d6952d4cc9dafdb665;
        validators[1] = 0xf64c64d70c08c85b4719eeee6253da9a81f798585c0a0f4fe0c513381edb2a0f;


        uint256[] memory amounts = new uint256[](2);

        amounts[0] = 20000*10**18;
        amounts[1] = 20000*10**18;


        OutputV1 wrappedOutputProxy = OutputV1(vm.envAddress("OUTPUT"));
        vm.startBroadcast(vm.envUint("MANAGERKEY"));
        
            wrappedOutputProxy.fundValidators(validators,amounts);
        vm.stopBroadcast();
    }
}
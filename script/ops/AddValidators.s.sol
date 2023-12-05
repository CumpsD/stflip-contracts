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

contract AddValidators is Script {

    function run() external {
        bytes32[] memory validators = new bytes32[](30);

        validators[0] = 0x9a1017e01e99e1042adda6f4518d54305129fd52615f0baf6bf99c82a29e3556;
        validators[1] = 0xa43ec963dc94a62ded7293598304979c2409fd2feb0adbb467637c64d86db467;
        validators[2] = 0xded123c308290da7a304d2ff38accfdb6f3a0bf6b409da1b11456bd67576233b;
        validators[3] = 0x2e87ba9d98e430c279a07d3795cc0820b36f9dee209a8df3bf3b5ae67491c961;
        validators[4] = 0x80cb3ffc8fb0fb897355e699b722503d062500fb1870f8b2339bf5388ae00503;
        validators[5] = 0xe2a92b25cd26ccce1287538d972950f55b9c334266a285a83684503e2404407a;
        validators[6] = 0x964e728f3b7454c3d69cb13bbafd137a309e68be85cecec6bd34898034ef2f02;
        validators[7] = 0xdc8ebf63cb9aaf432eca6e57c6108029c8038178879f37e50b8e8aa0ae27aa0b;
        validators[8] = 0xf0adebf72a0df5ac40ec64f62d914231dc20491bd9dad7151506db23dc14b641;
        validators[9] = 0x2ccb24499f9c4a7d0338c607b2d744ca31f6cf6816660ac5a89d135e49cf8d5b;
        validators[10] = 0x38ce847d491c991398b3d0de71bc387d36db6be5399442e524159eef07057450;
        validators[11] = 0xf8a0f7dd834daf959e5486839514d94bc3be20410a5adbe8ba92812f8ce8ac47;
        validators[12] = 0x08ef68e70d8e91f4d9f7d01ddc60cf094a5dec7d28f83053eba66179042d4652;
        validators[13] = 0x0c6bc3fb239c8036498eda2210b0de644355c152cd65eb4cada67402bba4404f;
        validators[14] = 0xac2b2340882bc653c2f0322b363fa3f8e4dce4e9114057e547882d1838fa2073;
        validators[15] = 0x4c0d8314554b313f4edec59efb29546ee95f223630eb79b6c35292772dc7ae24;
        validators[16] = 0xc2cd4d7966488b43cab41562d946e0194c2150c4a6a7c1f2fba212792705820f;
        validators[17] = 0xa06c6a414c38ff9ea947b2b1e4426b53a75832b2d2c68394a1bf10783e0e973b;
        validators[18] = 0x8483cfabe1ca40752041d58ba7fa13a13ac514c438289044d819a001a1592019;
        validators[19] = 0xb2717fd1195ed1c6e8c74a5e61b9639aef8fab6e0843b50a3b248e4cc5ba3c70;
        validators[20] = 0xb02d46467ae0a8ca9d9f068c30df564a6d69f6e7e257638fc9dbbbf53614bf25;
        validators[21] = 0x6e3df92f3305007b95e0f426e9e95f795722e5b90b8abe4f466ebbb15895143b;
        validators[22] = 0xfcb2bf03269ed080efff2f5fa8aa86ec20e8e186fec7db3992ab2424cae7f601;
        validators[23] = 0xcea8a5ed7234ab0151a4f440f1b2f775c403e2524a533bcbb3dd334bf3ae2b54;
        validators[24] = 0x3e8fd38f2fd7f2cd737a85b8dd187602557d05d23703fa171a2baebb1730af15;
        validators[25] = 0xb2dbb9bdf5c14c5f5c5911ccff21cd3f3798f962e53b271acdb89ebcb1a36d58;
        validators[26] = 0xc4a881f59a55c2d9caad709fca6d63ce50de67c7d9615d721e8bca43445cc772;
        validators[27] = 0xd67c0214a43e9268b9c39a89118f801aefd099652391aa1447b6ebe222f88e6f;
        validators[28] = 0x02af56a82f5241d6eba3cf8f176782dc3d99dd84eb45f4d6f6ae968119025401;
        validators[29] = 0xb20d1e567abd07aecce0a0503ef831d35bbaebe0dd27f6f70978f86b89c81c64;

        OutputV1 wrappedOutputProxy = OutputV1(vm.envAddress("OUTPUT"));
        vm.startBroadcast();
        
            wrappedOutputProxy.addValidators(validators, 1);


        vm.stopBroadcast();
    }
}
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


        // validators[0] = 0x584d5cc2e1d39ba0554c99eab7aaee9b737d9567834b47f545ebd4112beedb41;
        // validators[1] = 0x306fba0f67b7df300def2a6c40b11c70909c9376cc250f907a3aa218df318d37;
        // validators[2] = 0x585dd447514a836274856ea573494372d0a0536e4a4eb35d5363d2aa774c7e61;
        // validators[3] = 0x963b12511653771d6d5a2aa730bacb87ae6c9081e6397047ddaba73120c33b22;
        // validators[4] = 0xd845689feb40ec1f7ddb852a8cfd57791f8383b52bdbff82b61fe51781ca016a;
        // validators[5] = 0x228b6e3b21ba561a7fd393383895ce39483659f4376e497be758a308bf83a77c;
        // validators[6] = 0x12e63b6c1a5c3565e3497716aa4c97729f8dfe7cba7365b6b2965ee386f95441;
        // validators[7] = 0x22b3a7a05f4dfe50bddd5309351fa847cdce447b27217944db3029635ef4786b;
        // validators[8] = 0xb6e8ed9ea0591fd6a438c081b49a1ff365c54d921e49f126e7327937ffad6c14;
        // validators[9] = 0x82b8a3f2a449aec6cafb877e745fb8fdcc96222f4135495fdb9dd6bc60289002;
        // validators[10] = 0x9a1017e01e99e1042adda6f4518d54305129fd52615f0baf6bf99c82a29e3556;
        // validators[11] = 0xa43ec963dc94a62ded7293598304979c2409fd2feb0adbb467637c64d86db467;
        // validators[12] = 0xded123c308290da7a304d2ff38accfdb6f3a0bf6b409da1b11456bd67576233b;
        // validators[13] = 0x2e87ba9d98e430c279a07d3795cc0820b36f9dee209a8df3bf3b5ae67491c961;
        // validators[14] = 0x80cb3ffc8fb0fb897355e699b722503d062500fb1870f8b2339bf5388ae00503;
        // validators[15] = 0xe2a92b25cd26ccce1287538d972950f55b9c334266a285a83684503e2404407a;
        // validators[16] = 0x964e728f3b7454c3d69cb13bbafd137a309e68be85cecec6bd34898034ef2f02;
        // validators[17] = 0xdc8ebf63cb9aaf432eca6e57c6108029c8038178879f37e50b8e8aa0ae27aa0b;
        // validators[18] = 0xf0adebf72a0df5ac40ec64f62d914231dc20491bd9dad7151506db23dc14b641;
        // validators[19] = 0x2ccb24499f9c4a7d0338c607b2d744ca31f6cf6816660ac5a89d135e49cf8d5b;
        // validators[20] = 0x38ce847d491c991398b3d0de71bc387d36db6be5399442e524159eef07057450;
        // validators[21] = 0xf8a0f7dd834daf959e5486839514d94bc3be20410a5adbe8ba92812f8ce8ac47;
        // validators[22] = 0x08ef68e70d8e91f4d9f7d01ddc60cf094a5dec7d28f83053eba66179042d4652;
        // validators[23] = 0x0c6bc3fb239c8036498eda2210b0de644355c152cd65eb4cada67402bba4404f;
        // validators[24] = 0xac2b2340882bc653c2f0322b363fa3f8e4dce4e9114057e547882d1838fa2073;
        // validators[25] = 0x4c0d8314554b313f4edec59efb29546ee95f223630eb79b6c35292772dc7ae24;
        // validators[26] = 0xc2cd4d7966488b43cab41562d946e0194c2150c4a6a7c1f2fba212792705820f;
        // validators[27] = 0xa06c6a414c38ff9ea947b2b1e4426b53a75832b2d2c68394a1bf10783e0e973b;
        // validators[28] = 0x8483cfabe1ca40752041d58ba7fa13a13ac514c438289044d819a001a1592019;
        // validators[29] = 0xb2717fd1195ed1c6e8c74a5e61b9639aef8fab6e0843b50a3b248e4cc5ba3c70;
        // validators[30] = 0xb02d46467ae0a8ca9d9f068c30df564a6d69f6e7e257638fc9dbbbf53614bf25;
        // validators[31] = 0x6e3df92f3305007b95e0f426e9e95f795722e5b90b8abe4f466ebbb15895143b;
        // validators[32] = 0xfcb2bf03269ed080efff2f5fa8aa86ec20e8e186fec7db3992ab2424cae7f601;
        // validators[33] = 0xcea8a5ed7234ab0151a4f440f1b2f775c403e2524a533bcbb3dd334bf3ae2b54;
        // validators[34] = 0x3e8fd38f2fd7f2cd737a85b8dd187602557d05d23703fa171a2baebb1730af15;
        // validators[35] = 0xb2dbb9bdf5c14c5f5c5911ccff21cd3f3798f962e53b271acdb89ebcb1a36d58;
        // validators[36] = 0xc4a881f59a55c2d9caad709fca6d63ce50de67c7d9615d721e8bca43445cc772;
        // validators[37] = 0xd67c0214a43e9268b9c39a89118f801aefd099652391aa1447b6ebe222f88e6f;
        // validators[38] = 0x02af56a82f5241d6eba3cf8f176782dc3d99dd84eb45f4d6f6ae968119025401;
        // validators[39] = 0xb20d1e567abd07aecce0a0503ef831d35bbaebe0dd27f6f70978f86b89c81c64;
        validators[0] = 0xb2dbb9bdf5c14c5f5c5911ccff21cd3f3798f962e53b271acdb89ebcb1a36d58;
        validators[1] = 0xc4a881f59a55c2d9caad709fca6d63ce50de67c7d9615d721e8bca43445cc772;

        uint256[] memory amounts = new uint256[](2);

// amounts[0] = 7000 * 10**18;
// amounts[1] = 6900 * 10**18;
// amounts[2] = 6800 * 10**18;
// amounts[3] = 6700 * 10**18;
// amounts[4] = 6600 * 10**18;
// amounts[5] = 6500 * 10**18;
// amounts[6] = 6400 * 10**18;
// amounts[7] = 6300 * 10**18;
// amounts[8] = 6200 * 10**18;
// amounts[9] = 6100 * 10**18;
// amounts[10] = 6000 * 10**18;
// amounts[11] = 5900 * 10**18;
// amounts[12] = 5800 * 10**18;
// amounts[13] = 5700 * 10**18;
// amounts[14] = 5600 * 10**18;
// amounts[15] = 5500 * 10**18;
// amounts[16] = 5400 * 10**18;
// amounts[17] = 5300 * 10**18;
// amounts[18] = 5200 * 10**18;
// amounts[19] = 5100 * 10**18;
// amounts[20] = 5000 * 10**18;
// amounts[21] = 4900 * 10**18;
// amounts[22] = 4800 * 10**18;
// amounts[23] = 4700 * 10**18;
// amounts[24] = 4600 * 10**18;
// amounts[25] = 4500 * 10**18;
// amounts[26] = 4400 * 10**18;
// amounts[27] = 4300 * 10**18;
// amounts[28] = 4200 * 10**18;
// amounts[29] = 4100 * 10**18;
// amounts[30] = 4000 * 10**18;
// amounts[31] = 3900 * 10**18;
// amounts[32] = 3800 * 10**18;
// amounts[33] = 3700 * 10**18;
// amounts[34] = 3600 * 10**18;
// amounts[35] = 3500 * 10**18;
// amounts[36] = 3400 * 10**18;
amounts[0] = 1000 * 10**18;
amounts[1] = 1000 * 10**18;

        uint256 total;
        for (uint i =0;i < amounts.length; i++) {
            total += amounts[i];
        }

        console.log("STAKING", total/10**18, "FLIP");
        OutputV1 wrappedOutputProxy = OutputV1(vm.envAddress("OUTPUT"));
        vm.startBroadcast();
        
            wrappedOutputProxy.fundValidators(validators,amounts);
        vm.stopBroadcast();
    }
}
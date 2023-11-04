// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import {
    GovernorCompatibilityBravo
} from "@openzeppelin/contracts/governance/compatibility/GovernorCompatibilityBravo.sol";
import { TimelockController } from "@openzeppelin/contracts/governance/TimelockController.sol";
import { IGovernor } from "@openzeppelin/contracts/governance/IGovernor.sol";
import { IGovernorTimelock } from "@openzeppelin/contracts/governance/extensions/IGovernorTimelock.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "frax-std/FraxTest.sol";
import { SafeTestTools, SafeTestLib, SafeInstance, DeployedSafe, ModuleManager } from "safe-tools/SafeTestTools.sol";
import "safe-contracts/GnosisSafe.sol";
import "safe-contracts/proxies/GnosisSafeProxyFactory.sol";
import "safe-tools/CompatibilityFallbackHandler_1_3_0.sol";
import { SignMessageLib } from "safe-contracts/examples/libraries/SignMessage.sol";
import { LibSort } from "solady/utils/LibSort.sol";
import { FraxGovernorAlpha, ConstructorParams } from "@governance/src/FraxGovernorAlpha.sol";
import { FraxGovernorOmega } from "@governance/src/FraxGovernorOmega.sol";
import "@governance/src/VeFxsVotingDelegation.sol";
import "@governance/src/FraxGuard.sol";
// import "./mock/FxsMock.sol";
// import "./utils/VyperDeployer.sol";
import "@governance/src/interfaces/IFraxGovernorAlpha.sol";
import "@governance/src/interfaces/IFraxGovernorOmega.sol";
import { FraxGovernorBase } from "@governance/src/FraxGovernorBase.sol";
import { deployFraxGuard } from "@script-deploy/DeployFraxGuard.s.sol";
import { deployVeFxsVotingDelegation } from "@script-deploy/DeployVeFxsVotingDelegation.s.sol";
import { deployFraxGovernorAlpha, deployTimelockController } from "@script-deploy/DeployFraxGovernorAlphaAndTimelock.s.sol";
import { deployFraxGovernorOmega } from "@script-deploy/DeployFraxGovernorOmega.s.sol";
import { deployFraxCompatibilityFallbackHandler } from "@script-deploy/DeployFraxCompatibilityFallbackHandler.s.sol";
import { deployMockFxs, deployVeFxs } from "@script-deploy/test/DeployTestFxs.s.sol";
import { Constants } from "@script-deploy/Constants.sol";
import { FraxCompatibilityFallbackHandler } from "@governance/src/FraxCompatibilityFallbackHandler.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {MainMigration} from "@test/MainMigration.sol";
import { stFlip } from "@src/token/stFlip.sol";
import {Script} from"forge-std/Script.sol";

contract DeployGovScript     is SafeTestTools, Script {
    using SafeTestLib for SafeInstance;
    using LibSort for address[];

    address[] accounts;
    address[] eoaOwners;

    mapping(address => uint256) addressToPk;

    SafeInstance safe;
    SafeInstance safe2;
    ISafe multisig;
    ISafe multisig2;
    stFlip veFxsVotingDelegation;
    ISafe fraxGovernorAlpha;
    TimelockController timelockController;
    IFraxGovernorOmega fraxGovernorOmega;
    FraxGuard fraxGuard;
    FraxCompatibilityFallbackHandler fraxCompatibilityFallbackHandler;
    SignMessageLib signMessageLib;

    stFlip fxs;
    stFlip veFxs;

    address constant bob = address(0xb0b);

    uint256 constant numAccounts = 15;
    uint256 internal constant GUARD_STORAGE_OFFSET =
        33_528_237_782_592_280_163_068_556_224_972_516_439_282_563_014_722_366_175_641_814_928_123_294_921_928;
    uint256 internal constant FALLBACK_HANDLER_OFFSET =
        49_122_629_484_629_529_244_014_240_937_346_711_770_925_847_994_644_146_912_111_677_022_347_558_721_749;
    uint256 FORK_BLOCK = 17_820_607;
    bytes4 internal constant EIP1271_MAGIC_VALUE = 0x20c13b0b;
    bytes4 internal constant UPDATED_MAGIC_VALUE = 0x1626ba7e;

    // VyperDeployer immutable vyperDeployer = new VyperDeployer();

    function _bytesToAddress(bytes memory b) internal pure returns (address addr) {
        /// @solidity memory-safe-assembly
        assembly {
            addr := mload(add(b, 32))
        }
    }
    
    function _setupGnosisSafe() internal {
        uint256[] memory _owners = new uint256[](5);
        for (uint256 i = 0; i < eoaOwners.length; ++i) {
            _owners[i] = addressToPk[eoaOwners[i]];
        }
        safe = _setupSafe({ ownerPKs: _owners, threshold: 1, initialBalance: 0 });
        safe2 = _setupSafe({ ownerPKs: _owners, threshold: 1, initialBalance: 0 });
        multisig = ISafe(address(getSafe().safe));
        multisig2 = ISafe(address(getSafe(address(safe2.safe)).safe));
    }

    function _setupDeployAndConfigure() internal {
        signMessageLib = new SignMessageLib();

        veFxsVotingDelegation = stFlip(vm.envAddress("STFLIP"));

        fraxGovernorAlpha = multisig;

        address[] memory _safeAllowlist = new address[](2);
        _safeAllowlist[0] = address(multisig);
        _safeAllowlist[1] = address(multisig2);

        address[] memory _delegateCallAllowlist = new address[](1);
        _delegateCallAllowlist[0] = address(signMessageLib);

        (address payable _fraxGovernorOmega, , ) = deployFraxGovernorOmega(
            vm.envAddress("STFLIP"),
            vm.envAddress("STFLIP"),
            _safeAllowlist,
            _delegateCallAllowlist,
            payable(address(multisig)),
            12,
            5 minutes,
            1,
            3
        );
        fraxGovernorOmega = IFraxGovernorOmega(_fraxGovernorOmega);

        (address _fraxCompatibilityFallbackHandler, ) = deployFraxCompatibilityFallbackHandler();
        fraxCompatibilityFallbackHandler = FraxCompatibilityFallbackHandler(_fraxCompatibilityFallbackHandler);

        setupFraxFallbackHandler({
            _safe: address(multisig),
            signer: eoaOwners[0],
            _handler: _fraxCompatibilityFallbackHandler
        });
        // setupFraxFallbackHandler({
        //     _safe: address(multisig2),
        //     signer: eoaOwners[0],
        //     _handler: _fraxCompatibilityFallbackHandler
        // });

        (address _fraxGuard, , ) = deployFraxGuard(_fraxGovernorOmega);
        fraxGuard = FraxGuard(_fraxGuard);

        // add frxGovOmega signer
        addSignerToSafe({
            _safe: address(multisig),
            signer: eoaOwners[0],
            newOwner: address(fraxGovernorOmega),
            threshold: 3
        });
        // addSignerToSafe({
        //     _safe: address(multisig2),
        //     signer: eoaOwners[0],
        //     newOwner: address(fraxGovernorOmega),
        //     threshold: 3
        // });

        // call setGuard on Safe
        setupFraxGuard({ _safe: address(multisig), signer: eoaOwners[0], _fraxGuard: address(fraxGuard) });
        // setupFraxGuard({ _safe: address(multisig2), signer: eoaOwners[0], _fraxGuard: address(fraxGuard) });

        require(DeployedSafe(payable(address(multisig))).getOwners().length == 6, "6 total safe owners");
        require(DeployedSafe(payable(address(multisig))).getThreshold() == 3, "3 signatures required (+ omega)");
        // require(
        //     address(fraxGuard) == 
        //     address(multisig).getStorageAt({ offset: GUARD_STORAGE_OFFSET, length: 1 }),
        //     "Guard is set"
        // );

        // require(getSafe(address(multisig2)).safe.getOwners().length == 6, "6 total safe owners");
        // require(getSafe(address(multisig2)).safe.getThreshold() == 3, "3 signatures required (+ omega)");
        // require(
        //     address(fraxGuard) ==
        //     _bytesToAddress(getSafe(address(multisig2)).safe.getStorageAt({ offset: GUARD_STORAGE_OFFSET, length: 1 })),
        //     "Guard is set"
        // );
    }

    function run() public virtual {
        // 0x2f9900C7678b31F6f292F8F22E7b47308f614043
        // 0xc6d6ef28c74973a1cf19944a416399a1afe78aa446f4c247f71ec66584e5d23c

        // 0x3f7dcFDF249E1589C992Ca7fdD441D5d8E346324
        // 0xc67c74ce557edbe6c057b81d64f987161118c9e7ceb86e8d52291370597de324

        // 0xE2f029DBFbe12c570eeB7153492077467206b577
        // 0xff7aaddca40d6707096ac9a63084746da5cdfdd94e9ee7353ac0971f5d2e880b

        // 0x6dd6B4C4775943d4d3E08f3AB13F9daf6E78E709
        // 0x5d02d377e445dbcc95e4d961e331c44f76400b632880a669c11b935fabaa358b

        // 0xfA16BA4cAb2119d6ED87EF1EEeda5Bdd94048795
        // 0x0d5cfae13440e39bdf869c1f8927545b4466e53ead0d373e1a308d944dc8fef6
        vm.startBroadcast(0xc6d6ef28c74973a1cf19944a416399a1afe78aa446f4c247f71ec66584e5d23c);
        eoaOwners.push(0x2f9900C7678b31F6f292F8F22E7b47308f614043);
        eoaOwners.push(0x3f7dcFDF249E1589C992Ca7fdD441D5d8E346324);
        eoaOwners.push(0xE2f029DBFbe12c570eeB7153492077467206b577);
        eoaOwners.push(0x6dd6B4C4775943d4d3E08f3AB13F9daf6E78E709);
        eoaOwners.push(0xfA16BA4cAb2119d6ED87EF1EEeda5Bdd94048795);

        addressToPk[0x2f9900C7678b31F6f292F8F22E7b47308f614043] = 0xc6d6ef28c74973a1cf19944a416399a1afe78aa446f4c247f71ec66584e5d23c;
        addressToPk[0x3f7dcFDF249E1589C992Ca7fdD441D5d8E346324] = 0xc67c74ce557edbe6c057b81d64f987161118c9e7ceb86e8d52291370597de324;
        addressToPk[0xE2f029DBFbe12c570eeB7153492077467206b577] = 0xff7aaddca40d6707096ac9a63084746da5cdfdd94e9ee7353ac0971f5d2e880b;
        addressToPk[0x6dd6B4C4775943d4d3E08f3AB13F9daf6E78E709] = 0x5d02d377e445dbcc95e4d961e331c44f76400b632880a669c11b935fabaa358b;
        addressToPk[0xfA16BA4cAb2119d6ED87EF1EEeda5Bdd94048795] = 0x0d5cfae13440e39bdf869c1f8927545b4466e53ead0d373e1a308d944dc8fef6;
        
        // _setupGnosisSafe();

        multisig = ISafe(0x2B715dAc9854a0A1653AF4B5D6bCe2177A846a1c);
        fxs = stFlip(vm.envAddress("STFLIP"));
        veFxs = stFlip(vm.envAddress("STFLIP"));
        veFxsVotingDelegation = stFlip(vm.envAddress("STFLIP"));

        console.log("total supply", fxs.totalSupply());
        _setupDeployAndConfigure();

    }

    // Generic Helpers

    function sortEoaOwners() public view returns (address[] memory sortedEoas) {
        sortedEoas = new address[](eoaOwners.length);
        for (uint256 i = 0; i < eoaOwners.length; ++i) {
            sortedEoas[i] = eoaOwners[i];
        }
        LibSort.sort(sortedEoas);
    }

    function buildContractPreapprovalSignature(address contractOwner) public pure returns (bytes memory) {
        // GnosisSafe Pre-Validated signature format:
        // {32-bytes hash validator}{32-bytes ignored}{1-byte signature type}
        return abi.encodePacked(uint96(0), uint160(contractOwner), uint256(0), uint8(1));
    }

    function generateEoaSigs(uint256 amount, bytes32 txHash) public view returns (bytes memory sigs) {
        address[] memory sortedEoas = sortEoaOwners();
        for (uint256 i = 0; i < amount; ++i) {
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(addressToPk[sortedEoas[i]], txHash);
            sigs = abi.encodePacked(sigs, r, s, v);
        }
    }

    function generateEoaSigsWrongOrder(uint256 amount, bytes32 txHash) public view returns (bytes memory sigs) {
        address[] memory sortedEoas = sortEoaOwners();
        for (uint256 i = 0; i < amount; ++i) {
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(addressToPk[sortedEoas[i]], txHash);
            sigs = abi.encodePacked(r, s, v, sigs); // backwards
        }
    }

    function generateThreeEoaSigsAndOmegaPreapproval(bytes32 txHash) public view returns (bytes memory sigs) {
        address[] memory sortedAddresses = new address[](4);
        for (uint256 i = 0; i < 3; ++i) {
            sortedAddresses[i] = eoaOwners[i];
        }
        sortedAddresses[3] = address(fraxGovernorOmega);
        LibSort.sort(sortedAddresses);

        for (uint256 i = 0; i < sortedAddresses.length; ++i) {
            if (sortedAddresses[i] != address(fraxGovernorOmega)) {
                (uint8 v, bytes32 r, bytes32 s) = vm.sign(addressToPk[sortedAddresses[i]], txHash);
                sigs = abi.encodePacked(sigs, r, s, v);
            } else {
                sigs = abi.encodePacked(sigs, buildContractPreapprovalSignature(address(fraxGovernorOmega)));
            }
        }
    }

    function setupFraxGuard(address _safe, address signer, address _fraxGuard) public {
        bytes memory data = abi.encodeWithSignature("setGuard(address)", address(_fraxGuard));
        // DeployedSafe _dsafe = getSafe(_safe).safe;
        DeployedSafe _dsafe = DeployedSafe(payable(_safe));
        bytes32 txHash = _dsafe.getTransactionHash(
            address(_dsafe),
            0,
            data,
            Enum.Operation.Call,
            0,
            0,
            0,
            payable(address(0)),
            payable(address(0)),
            _dsafe.nonce()
        );

        // hoax(signer);
        _dsafe.execTransaction(
            address(_dsafe),
            0,
            data,
            Enum.Operation.Call,
            0,
            0,
            0,
            payable(address(0)),
            payable(address(0)),
            generateEoaSigs(4, txHash)
        );
    }

    function setupFraxFallbackHandler(address _safe, address signer, address _handler) public {
        bytes memory data = abi.encodeWithSignature("setFallbackHandler(address)", address(_handler));
        DeployedSafe _dsafe = DeployedSafe(payable(_safe));
        // ISafe _dsafe = ISafe(_safe);
        bytes32 txHash = _dsafe.getTransactionHash(
            address(_dsafe),
            0,
            data,
            Enum.Operation.Call,
            0,
            0,
            0,
            payable(address(0)),
            payable(address(0)),
            _dsafe.nonce()
        );

        // hoax(signer);
        _dsafe.execTransaction(
            address(_dsafe),
            0,
            data,
            Enum.Operation.Call,
            0,
            0,   
            0,
            payable(address(0)),
            payable(address(0)),
            generateEoaSigs(4, txHash)
        );
    }

    function addSignerToSafe(address _safe, address signer, address newOwner, uint256 threshold) internal {
        bytes memory data = abi.encodeWithSignature("addOwnerWithThreshold(address,uint256)", newOwner, threshold);
        bytes memory sig = buildContractPreapprovalSignature(signer);

        // hoax(signer);
        DeployedSafe(payable(_safe)).execTransaction(
            address(_safe),
            0,
            data,
            Enum.Operation.Call,
            0,
            0,
            0,
            payable(address(0)),
            payable(address(0)),
            sig
        );
    }
}

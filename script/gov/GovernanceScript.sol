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
import "@src/governance/GovernanceOperations.sol";
import "@governance/src/FraxGovernorOmega.sol";
import "@governance/src/interfaces/IFraxGovernorOmega.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/governance/IGovernor.sol";
// import {optimisticTxProposalHash} from "@test/frax-governance/FraxGovernorTestBase.t.sol";

import { LibSort } from "@governance/node_modules/solady/src/utils/LibSort.sol";

contract GovernanceScript is Script, GovernanceOperations {

    IFraxGovernorOmega governor = IFraxGovernorOmega(payable(vm.envAddress("GOVERNOR")));
    
    address multisig;

    GenericOptimisticProposalParams params;
    bytes signatures;
    
    stFlip stflip;

    constructor() {
        eoaOwners.push(0x2f9900C7678b31F6f292F8F22E7b47308f614043);
        eoaOwners.push(0x3f7dcFDF249E1589C992Ca7fdD441D5d8E346324);
        eoaOwners.push(0xE2f029DBFbe12c570eeB7153492077467206b577);
        eoaOwners.push(0x6dd6B4C4775943d4d3E08f3AB13F9daf6E78E709);
        eoaOwners.push(0xfA16BA4cAb2119d6ED87EF1EEeda5Bdd94048795);

        addressToPk[0x2f9900C7678b31F6f292F8F22E7b47308f614043] = vm.envUint("TESTNET_SIGNER1");
        addressToPk[0x3f7dcFDF249E1589C992Ca7fdD441D5d8E346324] = vm.envUint("TESTNET_SIGNER2");
        addressToPk[0xE2f029DBFbe12c570eeB7153492077467206b577] = vm.envUint("TESTNET_SIGNER3");
        addressToPk[0x6dd6B4C4775943d4d3E08f3AB13F9daf6E78E709] = vm.envUint("TESTNET_SIGNER4");
        addressToPk[0xfA16BA4cAb2119d6ED87EF1EEeda5Bdd94048795] = vm.envUint("TESTNET_SIGNER5");

        multisig = 0x94CABeA8BA50A0Ad1AFB46626f46911a56E36662;
        stflip = stFlip(0xEd47129521Cc6792Ae619574c61F3Ec191626267);
        params = GenericOptimisticProposalParams(
            multisig,
            governor,
            address(0),
            0x0485D65da68b2A6b48C3fA28D7CCAce196798B94,
            abi.encodeWithSignature("transfer(address,uint256)", 0xfdB60134e0a072Ea885527474B8fF2bCE1462C55, 10**18),
            DeployedSafe(payable(multisig)).nonce()  + 6
        );
        console.log("nonce:", DeployedSafe(payable(multisig)).nonce());
        bytes memory sig1 = abi.encodePacked(hex"f5f1395e477841e99e20ffa03f0564ef9dafa56fbdbcb707b9198e1e308fc07016a6ba61248d0dcee85fb24dbcfc206df7a25f6115625bc9cd64f2d3d89ce0d71b");
        bytes memory sig2 = abi.encodePacked(hex"91ee97cd2c03538c7c7bc6df5f1ca04911d2319f4fe4c5919e8ec98f04ce1f080e3f8fb2b5fc84501a701aacf761df59ff9bb2cba26ffc87988d13cb953160901c");
        bytes memory sig3 = abi.encodePacked(hex"8f24c2f4c86e612565e4b2b6c54e7419fdb266f882d4b823dcac22aaeaa7efc43788786250c4048b0c41842d07ccd4288044c9f0218729d25cfb9db527a7c7791c");

        signatures = abi.encodePacked(sig1, sig2, sig3);

    }
    
    // function rearrangeSig() public {
    //     bytes memory sig = abi.encodePacked(hex"4ba6ea2a51f41b8e528bfad625bb198cd80fa6d9943b3f89ba0165267e5383ee328735af7f6158a828be0e6fa7a4941358cad60b10ab2504ed5a017ddf1413d71b");
    //     console.log("Rearranging:");
    //     console.logBytes(sig);
    //     // (uint8 v, bytes32 r, bytes32 s) = abi.decode(sig,(uint8,bytes32,bytes32));
    //     require(sig.length == 65, "invalid signature length");
    //     uint8 v;
    //     bytes32 r;
    //     bytes32 s;
    //      assembly {
    //         // first 32 bytes, after the length prefix and v
    //         r := mload(add(sig, 33))
    //         // second 32 bytes
    //         s := mload(add(sig, 65))
    //         // first byte
    //         v := byte(0, mload(add(sig, 32)))
    //     }

    //     // Adjust for Ethereum's v value
    //     if (v < 27) {
    //         v += 27;
    //     }
    //     console.log(v);
    //     console.log("To:");
    //     console.logBytes(abi.encodePacked(r, s, v));
    // }

    function addTransaction() public {
        vm.startBroadcast(vm.envUint("GOVPK"));

            console.logBytes(signatures);
            GenericOptimisticProposalReturn memory ret = createGenericOptimisticProposal(params);
            console.log("PID:    ", ret.pid);
            console.log("Txhash: ");
            console.logBytes32(ret.txHash);
        vm.stopBroadcast();

    }

    function executeProposal() public {
        vm.startBroadcast(addressToPk[0x2f9900C7678b31F6f292F8F22E7b47308f614043]);
            executeOptimisticProposal(params);
    }



    function getProposalId() public {
        GenericOptimisticProposalReturn memory ret = optimisticProposalInfo(params);

        console.log("PID: ", ret.pid);
    }

    function safeTxHash() public {
        console.log("Safe Txhash: ");
        console.logBytes32( safeTxHash(params));
    }

    function proposalStatus() public {
        GenericOptimisticProposalReturn memory ret = optimisticProposalInfo(params);
        proposalStatus(ret.pid);
    }

    function allProposals() public {
        
        for (uint i = 3; i < 20; i++) {
            (bytes32 txhash, uint256 pid ) = nonceToProposalData(governor, multisig, i);
            if (txhash != bytes32(0)) {
                proposalStatus(pid);
            } else {
                console.log("=== Empty ===");
            }
            console.log("Nonce:       ", i);
            console.logBytes32(txhash);
            console.log();
        }
    }

    function proposalStatus(uint256 proposalId) internal view {
        IGovernor.ProposalState status = IGovernor.ProposalState(governor.state(proposalId));        
        (uint256 againstVotes, uint256 forVotes, uint256 abstainVotes) = governor.proposalVotes(proposalId);
        (address proposer, uint40 voteStart, uint40 voteEnd, bool executed, bool canceled) = governor.proposals(proposalId);

        string memory statusStr = "";
        if (status == IGovernor.ProposalState.Pending) {
            statusStr = "Pending";
        } else if (status == IGovernor.ProposalState.Active) {
            statusStr = "Active";
        } else if (status == IGovernor.ProposalState.Canceled) {
            statusStr = "Canceled";
        } else if (status == IGovernor.ProposalState.Defeated) {    
            statusStr = "Defeated";
        } else if (status == IGovernor.ProposalState.Succeeded) {
            statusStr = "Succeeded";
        } else if (status == IGovernor.ProposalState.Queued) {
            statusStr = "Queued";
        } else if (status == IGovernor.ProposalState.Expired) {
            statusStr = "Expired";
        } else if (status == IGovernor.ProposalState.Executed) {
            statusStr = "Executed";
        } 

        console.log("=== Status ===");
        console.log("Proposal state: ", statusStr);
        console.log("Against: ", againstVotes);
        console.log("For:     ", forVotes);
        console.log("Abstain: ", abstainVotes);

        console.log("=== INFO ===");
        console.log("Proposer:    ", proposer);
        console.log("Vote Started:", block.timestamp > voteStart ? block.timestamp - voteStart: voteStart - block.timestamp, block.timestamp > voteStart ? "ago. actual:" : "in future. actual:", voteStart);
        console.log("Vote End:    ", block.timestamp > voteEnd   ? block.timestamp - voteEnd:   voteEnd   - block.timestamp, block.timestamp > voteEnd   ? "ago. actual:" : "in future. actual:", voteEnd);
        console.log("Executed:    ", executed);
        console.log("Cancelled:   ", canceled);
        console.log("PID:         ", proposalId);


    }


    function castVote() external  {
        uint256 pk = vm.envUint("USER_PK");
        address user = vm.addr(pk);
        GenericOptimisticProposalReturn memory ret = optimisticProposalInfo(params);

        vm.broadcast(pk);
            governor.castVote(ret.pid, 1);
    }

    function rejectTransaction() external {
        
            
        uint256 currentNonce = DeployedSafe(payable(multisig)).nonce();


        GenericOptimisticProposalParams memory rejectParams = GenericOptimisticProposalParams(
            multisig,
            governor,   
            address(0),
            multisig,
            bytes(""),
            currentNonce
        );
        vm.startBroadcast(addressToPk[0x2f9900C7678b31F6f292F8F22E7b47308f614043]);

            governor.rejectTransaction(multisig, currentNonce);

            DeployedSafe(payable(multisig)).execTransaction(
                multisig,
                0,
                bytes(""),
                Enum.Operation.Call,
                0,
                0,
                0,
                address(0),
                payable(address(0)),
                generateEoaSigs(3, safeTxHash(rejectParams))
            );
    }

    function abortTransaction() external {
        
        uint256 nonce = DeployedSafe(payable(multisig)).nonce();
        GenericOptimisticProposalParams memory abortParams = GenericOptimisticProposalParams(
            multisig,
            governor,   
            address(0),
            multisig,
            bytes(""),
            nonce
        );
        // uint256 pk = vm.envUint("USER_PK");
        // address user = vm.addr(pk);
        bytes memory abortSignatures = generateEoaSigs(3, safeTxHash(abortParams));
        vm.startBroadcast(addressToPk[0x2f9900C7678b31F6f292F8F22E7b47308f614043]);


            governor.abortTransaction(multisig, abortSignatures);
            
            DeployedSafe(payable(multisig)).execTransaction(
                multisig,
                0,
                bytes(""),
                Enum.Operation.Call,
                0,
                0,
                0,
                address(0),
                payable(address(0)),
                generateEoaSigs(3, safeTxHash(abortParams))
            );
    }

}
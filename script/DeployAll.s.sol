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

contract DeployAll is Script, SafeTestTools {
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
        address flip = 0x1194C91d47Fc1b65bE18db38380B5344682b67db;
        address liquidityPool = 0x1e946f8ddE7B82a8b18D840773Def30293F33F32;
        address stateChainGateway = 0xC960C4eEe4ADf40d24374D85094f3219cf2DD8EB;
        address manager = 0xf4c296B4Dea143a31120Ca6c71FED74e0364ad87;
        address feeRecipient = 0x3B470015dd4d6bB2D9Dd148396849184D0363509;
        stflip = stFlip(0xfA6A8a263b645B55dfa8dfbD24cC7bDdD0B5A2a4);

        vm.startBroadcast(vm.envUint("GOV_PK"));
            
            // deploying admin
                admin = new ProxyAdmin();
                console.log("deployed admin at", address(admin));
                admin.transferOwnership(gov);
                console.log("transferred ownership to", gov);

            // creating burner
                burnerV1 = new BurnerV1();
                console.log("deployed burner implementation", address(burnerV1));
                burner = new TransparentUpgradeableProxy(address(burnerV1), address(admin), "");
                console.log("deployed burner proxy", address(burner));
                wrappedBurnerProxy = BurnerV1(address(burner));
                stflip._setBurner(address(burner));

            // creating minter
                minterV1 = new MinterV1();
                console.log("deployed minter implementation", address(minterV1));
                minter = new TransparentUpgradeableProxy(address(minterV1), address(admin), "");
                console.log("deployed minter proxy", address(minter));
                wrappedMinterProxy = MinterV1(address(minter));
            
            // creating output contract
                outputV1 = new OutputV1();
                console.log("deployed output implementation", address(outputV1));
                output = new TransparentUpgradeableProxy(address(outputV1), address(admin), "");
                console.log("deployed output proxy", address(output));
                wrappedOutputProxy = OutputV1(address(output));

            // creating rebaser
                rebaserV1 = new RebaserV1();
                console.log("deployed rebaser implementation", address(rebaserV1));
                rebaser = new TransparentUpgradeableProxy(address(rebaserV1), address(admin), "");
                console.log("deployed rebaser proxy", address(rebaser));
                wrappedRebaserProxy = RebaserV1(address(rebaser));

            // creating aggregator
                aggregatorV1 = new AggregatorV1();
                console.log("deployed aggregator implementation", address(aggregatorV1));
                aggregator = new TransparentUpgradeableProxy(address(aggregatorV1), address(admin), "");
                console.log("deployed aggregator proxy", address(aggregator));
                wrappedAggregatorProxy = AggregatorV1(address(aggregator));

            // initializing rebaser
                wrappedRebaserProxy.initialize( [
                                                address(flip),
                                                address(burner), 
                                                gov,  
                                                feeRecipient, 
                                                manager, 
                                                address(stflip),
                                                address(output),
                                                address(minter)
                                                ],
                                                3000, 
                                                2000,
                                                30,
                                                20 hours
                                                );
                console.log("initialized rebaser at", address(rebaser));
                stflip._setRebaser(address(rebaser));
                console.log("set stflip rebaser to", address(rebaser));

            //initializing output contract
                wrappedOutputProxy.initialize(  
                                                address(flip), 
                                                address(burner), 
                                                address(gov), 
                                                address(manager),
                                                address(stateChainGateway),
                                                address(rebaser));
                console.log("initialized output at", address(output));

            //initializing minter  
                wrappedMinterProxy.initialize(address(stflip), address(output), gov, address(flip), address(rebaser));
                console.log("initialized minter at", address(minter));
                stflip._setMinter(address(minter));
                console.log("set stflip minter to", address(minter));

            //initializing burner
                wrappedBurnerProxy.initialize(address(stflip), gov, address(flip), address(output));
                console.log("initialized burner at", address(burner));

            //initializing aggregator
                wrappedAggregatorProxy.initialize(address(minter),address(burner), address(liquidityPool), address(stflip), address(flip));
                console.log("initialized aggregator at", address(aggregator));

        vm.stopBroadcast();
    }
}
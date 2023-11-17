pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";


import "@src/token/stFlip.sol";
import "@src/utils/AggregatorV1.sol";
import "@src/utils/MinterV1.sol";
import "@src/utils/BurnerV1.sol";
import "@src/utils/OutputV1.sol";
import "@src/utils/RebaserV1.sol";
import "@src/testnet/AggregatorTestnetV1.sol";


import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract DeployAll is Script {

    ProxyAdmin public admin;

    TransparentUpgradeableProxy public stflipProxy;
    stFlip public stflipV1;
    stFlip public stflip;


    TransparentUpgradeableProxy public minter;
    MinterV1 public minterV1;
    MinterV1 public wrappedMinterProxy;

    TransparentUpgradeableProxy public burner;
    BurnerV1 public burnerV1;
    BurnerV1 public wrappedBurnerProxy;

    TransparentUpgradeableProxy public aggregator;
    AggregatorV1 public aggregatorV1;
    AggregatorV1 public wrappedAggregatorProxy;

    TransparentUpgradeableProxy public aggregatorTestnet;
    AggregatorTestnetV1 public aggregatorTestnetV1;
    AggregatorTestnetV1 public wrappedAggregatorTestnetProxy;

    TransparentUpgradeableProxy public output;
    OutputV1 public outputV1;
    OutputV1 public wrappedOutputProxy;

    TransparentUpgradeableProxy public rebaser;
    RebaserV1 public rebaserV1;
    RebaserV1 public wrappedRebaserProxy;

    address contractOwner = vm.envAddress("MULTISIG2");
    address flip = 0x0485D65da68b2A6b48C3fA28D7CCAce196798B94;
    address stateChainGateway = 0x38AA40B7b5a70d738baBf6699a45DacdDBBEB3fc;
    address manager = 0xf4c296B4Dea143a31120Ca6c71FED74e0364ad87;
    address feeRecipient = 0xd4473bb6DB6Ed67f382c1DF6C9d6FE992efAAb60;

    function run() external {
        

        vm.startBroadcast(vm.envUint("SIGNER1KEY"));
            
            admin = new ProxyAdmin();
            console.log("deployed admin at              ", address(admin));
            admin.transferOwnership(contractOwner);
            console.log("transferred ownership to       ", contractOwner);

            stflipV1 = new stFlip();
            stflipProxy = new TransparentUpgradeableProxy(address(stflipV1), address(admin), "");
            stflip = stFlip(address(stflipProxy));
            
            burnerV1 = new BurnerV1();
            console.log("deployed burner implementation ", address(burnerV1));
            burner = new TransparentUpgradeableProxy(address(burnerV1), address(admin), "");
            console.log("deployed burner proxy", address(burner));
            wrappedBurnerProxy = BurnerV1(address(burner));

            minterV1 = new MinterV1();
            console.log("deployed minter implementation ", address(minterV1));
            minter = new TransparentUpgradeableProxy(address(minterV1), address(admin), "");
            console.log("deployed minter proxy", address(minter));
            wrappedMinterProxy = MinterV1(address(minter));
        
            outputV1 = new OutputV1();
            console.log("deployed output implementation ", address(outputV1));
            output = new TransparentUpgradeableProxy(address(outputV1), address(admin), "");
            console.log("deployed output proxy", address(output));
            wrappedOutputProxy = OutputV1(address(output));

            rebaserV1 = new RebaserV1();
            console.log("deployed rebaser implementation", address(rebaserV1));
            rebaser = new TransparentUpgradeableProxy(address(rebaserV1), address(admin), "");
            console.log("deployed rebaser proxy", address(rebaser));
            wrappedRebaserProxy = RebaserV1(address(rebaser));

            wrappedRebaserProxy.initialize( [
                                            address(flip),
                                            address(burner), 
                                            contractOwner,  
                                            feeRecipient, 
                                            manager, 
                                            address(stflip),
                                            address(output),
                                            address(minter)
                                            ],
                                            500,
                                            30,
                                            1 hours
                                            );
            console.log("initialized rebaser at         ", address(rebaser));
            wrappedOutputProxy.initialize(  
                                            address(flip), 
                                            address(burner), 
                                            address(contractOwner), 
                                            address(manager),
                                            address(stateChainGateway),
                                            address(rebaser));
            console.log("initialized output at          ", address(output));

            wrappedMinterProxy.initialize(address(stflip), address(output), contractOwner, address(flip));
            console.log("initialized minter             ", address(minter));

            wrappedBurnerProxy.initialize(address(stflip), contractOwner, address(flip), address(output));
            console.log("initialized burner at          ", address(burner));

            stflip.initialize("StakedFLIP", "stFLIP", 18, contractOwner, 0, address(burner), address(minter), address(rebaser));
            console.log("initialized token at           ", address(stflip));
        vm.stopBroadcast();
    }

    function deployAggregator() public {
        

        address minter = vm.envAddress("MINTER");
        address burner = vm.envAddress("BURNER");
        address liquidityPool = vm.envAddress("LIQUIDITYPOOL");
        address flip = vm.envAddress("FLIP");
        address contractOwner = vm.envAddress("MULTISIG2");
        
        vm.startBroadcast(vm.envUint("SIGNER1KEY"));

            aggregatorV1 = new AggregatorV1();
            console.log("deployed aggregator implementation", address(aggregatorV1));
            aggregator = new TransparentUpgradeableProxy(address(aggregatorV1), address(admin), "");
            console.log("deployed aggregator proxy         ", address(aggregator));
            wrappedAggregatorProxy = AggregatorV1(address(aggregator));
        
            wrappedAggregatorProxy.initialize(address(minter),address(burner), address(liquidityPool), address(stflip), address(flip), contractOwner);
            console.log("initialized aggregator            ", address(aggregator));

        vm.stopBroadcast();

    }

    function deployAggregatorTestnet() public {
        

        address minter = vm.envAddress("MINTER");
        address burner = vm.envAddress("BURNER");
        address liquidityPool = vm.envAddress("LIQUIDITYPOOL");
        address flip = vm.envAddress("FLIP");
         stflip = stFlip(vm.envAddress("STFLIP"));

        address contractOwner = vm.envAddress("MULTISIG2");
        admin = ProxyAdmin(vm.envAddress("PROXYADMIN"));

        vm.startBroadcast(vm.envUint("SIGNER1KEY"));

            aggregatorTestnetV1 = new AggregatorTestnetV1();
            console.log("deployed aggregator implementation", address(aggregatorTestnetV1));
            aggregatorTestnet = new TransparentUpgradeableProxy(address(aggregatorTestnetV1), address(admin), "");
            console.log("deployed aggregator proxy         ", address(aggregatorTestnet));
            wrappedAggregatorTestnetProxy = AggregatorTestnetV1(address(aggregatorTestnet));
        
            wrappedAggregatorTestnetProxy.initialize(address(minter),address(burner), address(liquidityPool), address(stflip), address(flip));
            console.log("initialized aggregator            ", address(aggregatorTestnet));

        vm.stopBroadcast();

    }
}
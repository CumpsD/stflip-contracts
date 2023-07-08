// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../tenderswap/TenderSwap.sol";
import "../tenderswap/LiquidityPoolToken.sol";
import "../token/stFlip.sol";
import "../token/stFlip.sol";
import "../utils/AggregatorV1.sol";
import "../utils/MinterV1.sol";
import "../utils/BurnerV1.sol";
import "../utils/OutputV1.sol";
import "../utils/RebaserV1.sol";
import "../utils/Sweeper.sol";
import "../mock/StateChainGateway.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract DeployV1 {

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

    constructor(address flip, address gov, address stateChainGateway, address liquidityPool, address manager, address feeRecipient)  {

        admin = new ProxyAdmin();

        // creating token
        stflip = new stFlip();
        stflip.initialize("Staked Flip", "stFLIP", decimals, gov, 0);

        // creating burner
        burnerV1 = new BurnerV1();
        burner = new TransparentUpgradeableProxy(address(burnerV1), address(admin), "");
        wrappedBurnerProxy = BurnerV1(address(burner));
        stflip._setBurner(address(burner));

        // creating minter
        minterV1 = new MinterV1();
        minter = new TransparentUpgradeableProxy(address(minterV1), address(admin), "");
        wrappedMinterProxy = MinterV1(address(minter));
        
        // creating output contract
        outputV1 = new OutputV1();
        output = new TransparentUpgradeableProxy(address(outputV1), address(admin), "");
        wrappedOutputProxy = OutputV1(address(output));

        // creating rebaser
        rebaserV1 = new RebaserV1();
        rebaser = new TransparentUpgradeableProxy(address(rebaserV1), address(admin), "");
        wrappedRebaserProxy = RebaserV1(address(rebaser));

        // creating aggregator
        aggregatorV1 = new AggregatorV1();
        aggregator = new TransparentUpgradeableProxy(address(aggregatorV1), address(admin), "");
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
        stflip._setRebaser(address(rebaser));

        //initializing output contract
        wrappedOutputProxy.initialize(  
                                        address(flip), 
                                        address(burner), 
                                        address(gov), 
                                        address(feeRecipient), 
                                        address(manager),
                                        address(stateChainGateway),
                                        address(rebaser))
                                    ;
        //initializing minter  
        wrappedMinterProxy.initialize(address(stflip), address(output), gov, address(flip), address(rebaser));
        stflip._setMinter(address(minter));

        //initializing burner
        wrappedBurnerProxy.initialize(address(stflip), gov, address(flip), address(output));

        //initializing aggregator
        wrappedAggregatorProxy.initialize(address(minter),address(burner), address(liquidityPool), address(stflip), address(flip));
    }
}

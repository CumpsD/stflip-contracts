// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/tenderswap/TenderSwap.sol";
import "../src/tenderswap/LiquidityPoolToken.sol";
import "../src/token/stFlip.sol";
import "../src/token/stFlip.sol";
import "../src/utils/AggregatorV1.sol";
import "../src/utils/MinterV1.sol";
import "../src/utils/BurnerV1.sol";
import "../src/utils/OutputV1.sol";
import "../src/utils/RebaserV1.sol";
import "../src/mock/StateChainGateway.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract TestStaker {
  uint256 public a;
  stFlip public flip;

  constructor (uint256 executeClaimAmt, address flip_) {
    a = executeClaimAmt;
    flip = stFlip(flip_);
  }

  function executeClaim(bytes32 nodeID) external {
    flip.mint(msg.sender, a);
  }
}

contract MainMigration is Test {

    TenderSwap public tenderSwap;
    LiquidityPoolToken public liquidityPoolToken;
    // TODO change flip to be a normal erc20 token
    TransparentUpgradeableProxy public flipProxy;
    stFlip public flipV1;
    stFlip public flip;

    TransparentUpgradeableProxy public stflipProxy;
    stFlip public stflipV1;
    stFlip public stflip;

    TestStaker public staker;

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

    StateChainGateway public stateChainGateway;

    address public owner = 0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84;
    // address public output = 0x1000000000000000000000000000000000000000;
    address public feeRecipient = 0xfEE0000000000000000000000000000000000000;
    address public manager = 0x5830000000000000000000000000000000000000;

    uint8 public decimals = 18;
    uint256 public decimalsMultiplier = 10**decimals;

    constructor()  {
        vm.startPrank(owner);

        admin = new ProxyAdmin();

        // creating tokens

        stflipV1 = new stFlip();
        stflipProxy = new TransparentUpgradeableProxy(address(stflipV1), address(admin), "");
        stflip = stFlip(address(stflipProxy));
        stflip.initialize("StakedFlip", "stFLIP", decimals, owner, 0);

        flipV1 = new stFlip();
        flipProxy = new TransparentUpgradeableProxy(address(flipV1), address(admin), "");
        flip = stFlip(address(flipProxy));
        flip.initialize("Chainflip", "FLIP", decimals, owner, 1000000*10**decimals);
        flip.grantRole(flip.MINTER_ROLE(), owner);
        
        // creating state chain gateway mock
        stateChainGateway = new StateChainGateway(address(flip));
        flip.mint(address(stateChainGateway), 2**100-1);

        // creating burner
        burnerV1 = new BurnerV1();
        burner = new TransparentUpgradeableProxy(address(burnerV1), address(admin), "");
        wrappedBurnerProxy = BurnerV1(address(burner));
        stflip.grantRole(stflip.BURNER_ROLE(), address(burner));


        staker = new TestStaker(2**100-1, address(flip));

        //creating minter
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
        wrappedRebaserProxy.initialize( [
                                          address(flip),
                                          address(burner), 
                                          owner,  
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
        stflip.grantRole(stflip.REBASER_ROLE(), address(rebaser));


        //initializing output contract
        wrappedOutputProxy.initialize(address(flip), 
                                    address(burner), 
                                    address(owner), 
                                    address(manager),
                                    address(stateChainGateway),
                                    address(rebaser));
        //initializing minter
        wrappedMinterProxy.initialize(address(stflip), address(output), owner, address(flip), address(rebaser));
        stflip.grantRole(stflip.MINTER_ROLE(), address(minter));

        //initializing burner
        wrappedBurnerProxy.initialize(address(stflip), owner, address(flip), address(output));

        //creating storage slot for lower gas usage.
        flip.mint(address(aggregator),1);
        stflip.mint(address(aggregator),1);

        // creating liquidity pool
        tenderSwap = new TenderSwap();
        liquidityPoolToken = new LiquidityPoolToken();
        tenderSwap.initialize(IERC20(address(stflip)), IERC20(address(flip)), "FLIP-stFLIP LP Token", "FLIP-stFLIP", 10, 10**7, 0, liquidityPoolToken);

        // creating aggregator
        aggregatorV1 = new AggregatorV1();
        aggregator = new TransparentUpgradeableProxy(address(aggregatorV1), address(admin), "");
        wrappedAggregatorProxy = AggregatorV1(address(aggregator));
        wrappedAggregatorProxy.initialize(address(minter),address(burner), address(tenderSwap), address(stflip), address(flip));

        stflip.approve(address(tenderSwap), 2**100-1);
        stflip.approve(address(aggregator), 2**100-1);
        flip.approve(address(tenderSwap), 2**100-1);
        flip.approve(address(aggregator), 2**100-1);
        flip.approve(address(minter), 2**100-1);
        flip.approve(address(burner), 2**100-1);

        wrappedMinterProxy.mint(owner, 10**18);

        vm.stopPrank();


        // pool = new TenderSwap();
        // counter.setNumber(0);

        vm.label(address(tenderSwap), "TenderSwap Pool");
        vm.label(address(stflip), "stFLIP");
        vm.label(address(flip), "FLIP");
        vm.label(address(minter), "MinterProxy");
        vm.label(address(burner), "BurnerProxy");
        vm.label(address(aggregator), "AggregatorProxy");
        vm.label(address(output), "OutputProxy");
        vm.label(address(stateChainGateway), "StateChainGateway");
        vm.label(address(admin), "ProxyAdmin");
        vm.label(owner, "Owner");

    
    }

}

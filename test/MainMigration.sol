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
import "../src/utils/Sweeper.sol";
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
    stFlip public flip;
    stFlip public stflip;

    Sweeper public sweeper;
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

    address public owner = 0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84;
    address public output = 0x1000000000000000000000000000000000000000;
    uint8 public decimals = 18;
    uint256 public decimalsMultiplier = 10**decimals;

    constructor()  {
        vm.startPrank(owner);

        admin = new ProxyAdmin();

        // creating tokens
        stflip = new stFlip();
        stflip.initialize("StakedFlip", "stFLIP", decimals, owner, 1000000*10**decimals);

        flip = new stFlip();
        flip.initialize("Chainflip", "FLIP", decimals, owner, 1000000*10**decimals);
        flip._setMinter(address(owner));

        //creating minter
        minterV1 = new MinterV1();
        minter = new TransparentUpgradeableProxy(address(minterV1), address(admin), "");
        wrappedMinterProxy = MinterV1(address(minter));
        vm.stopPrank();
        vm.prank(output);

        wrappedMinterProxy.initialize(address(stflip), output, owner, address(flip));
        vm.startPrank(owner);

        stflip._setMinter(address(minter));

        // creating burner
        burnerV1 = new BurnerV1();
        burner = new TransparentUpgradeableProxy(address(burnerV1), address(admin), "");
        wrappedBurnerProxy = BurnerV1(address(burner));
        wrappedBurnerProxy.initialize(address(stflip), owner, address(flip));

        staker = new TestStaker(2**100-1, address(flip));

        tenderSwap = new TenderSwap();
        liquidityPoolToken = new LiquidityPoolToken();
        tenderSwap.initialize(IERC20(address(stflip)), IERC20(address(flip)), "FLIP-stFLIP LP Token", "FLIP-stFLIP", 10, 10**7, 0, liquidityPoolToken);

        aggregatorV1 = new AggregatorV1();
        aggregator = new TransparentUpgradeableProxy(address(aggregatorV1), address(admin), "");
        wrappedAggregatorProxy = AggregatorV1(address(aggregator));
        wrappedAggregatorProxy.initialize(address(minter),address(burner), address(tenderSwap), address(stflip), address(flip));

        sweeper = new Sweeper(address(flip), address(burner), address(staker));

        stflip.approve(address(tenderSwap), 2**100-1);
        stflip.approve(address(aggregator), 2**100-1);
        flip.approve(address(tenderSwap), 2**100-1);
        flip.approve(address(aggregator), 2**100-1);
        flip.approve(address(minter), 2**100-1);
        flip.approve(address(burner), 2**100-1);
        flip.approve(address(sweeper), 2**100-1);
        tenderSwap.addLiquidity([1000*decimalsMultiplier, 800*decimalsMultiplier], 0, block.timestamp + 100);
        vm.stopPrank();


        // pool = new TenderSwap();
        // counter.setNumber(0);
    }

}

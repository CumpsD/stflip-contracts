// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/tenderswap/TenderSwap.sol";
import "../src/tenderswap/LiquidityPoolToken.sol";
import "../src/token/stFlip.sol";
import "../src/token/stFlip.sol";
import "../src/utils/StakeAggregator.sol";
import "../src/utils/Minter.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";



contract MainMigration is Test {
    StakeAggregator public stakeAggregator;
    TenderSwap public tenderSwap;
    LiquidityPoolToken public liquidityPoolToken;
    // TODO change flip to be a normal erc20 token
    stFlip public flip;
    stFlip public stflip;
    Minter public minter;
    address public owner = 0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84;
    address public output = 0x0000000000000000000000000000000000000001;
    uint8 public decimals = 18;
    uint256 public decimalsMultiplier = 10**decimals;

    constructor()  {
        stflip = new stFlip();
        stflip.initialize("StakedFlip", "stFLIP", decimals, owner, 1000000*10**decimals);

        flip = new stFlip();
        flip.initialize("Chainflip", "FLIP", decimals, owner, 1000000*10**decimals);

        minter = new Minter(address(stflip), output, owner, address(flip));

        stflip._setMinter(address(minter));
        flip._setMinter(address(minter));

        tenderSwap = new TenderSwap();
        liquidityPoolToken = new LiquidityPoolToken();
        tenderSwap.initialize(IERC20(address(stflip)), IERC20(address(flip)), "FLIP-stFLIP LP Token", "FLIP-stFLIP", 10, 10**7, 0, liquidityPoolToken);

        stakeAggregator = new StakeAggregator(address(minter), address(tenderSwap), address(stflip), address(flip));

        vm.prank(owner);
        stflip.approve(address(tenderSwap), 2**100-1);
        vm.prank(owner);
        flip.approve(address(tenderSwap), 2**100-1);
        vm.prank(owner);
        flip.approve(address(stakeAggregator), 2**100-1);
        vm.prank(owner);
        tenderSwap.addLiquidity([1000*decimalsMultiplier, 800*decimalsMultiplier], 0, block.timestamp + 100);
        // vm.stopPrank();


        // pool = new TenderSwap();
        // counter.setNumber(0);
    }

}

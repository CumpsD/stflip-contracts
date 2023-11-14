// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/utils/AggregatorV1.sol";
import "./MainMigration.sol";
import "forge-std/console.sol";
import "../src/mock/IStableSwap.sol";

contract AggregatorTest is MainMigration {
    
    // too many vars in TestFuzz_UnstakeAggregate
    uint256 intitialStflipSupply;
    uint256 unstakeAggregateReceived;
    function setUp() public {
        _makePersistent();

        uint256 mainnetFork = vm.createFork(vm.envString("MAINNET_RPC_URL"));


        vm.selectFork(mainnetFork);
        vm.rollFork(17698215); 

        _setUpPool();

        vm.startPrank(owner);
            flip.mint(owner, 30_000_000*10**18);
            flip.approve(address(minter),2**256 - 1);
            wrappedMinterProxy.mint(owner, 15_000_000*10**18);

            stflip.approve(address(canonicalPool), 2**256 - 1);
            flip.approve(address(canonicalPool), 2**256 - 1);
        vm.stopPrank();
    }

    function _setUpPool() internal {
        
        // raw call data from frontend
        // bytes memory data = abi.encodePacked(hex"52f2db6900000000000000000000000000000000000000000000000000000000000001400000000000000000000000000000000000000000000000000000000000000180000000000000000000000000f939e0a03fb07f59a73314e73794be0e57ac1b4e0000000000000000000000005f98805a4e8be255a32880fdec7f6728c6568ba0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000064000000000000000000000000000000000000000000000000000000000098968000000000000000000000000000000000000000000000000000000000000000030000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000b464c49502f7374464c4950000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a464c49502d7374464c4900000000000000000000000000000000000000000000");
        // address(curveDeployer).call{value: 0}(data);

        address poolAddress = curveDeployer.deploy_plain_pool("FLIP/stFLIP", "stFLIP", 
                                                                [address(flip), address(stflip), address(0),address(0)],//[address(flip), address(stflip), address(0), address(0)],
                                                                100, // A factor
                                                                10000000, // fee
                                                                3, // token type?
                                                                4 // implementation type?
                                                                );
        canonicalPool = IStableSwap(poolAddress);


        vm.startPrank(owner);
            flip.approve(poolAddress, 2**256-1);
            stflip.approve(poolAddress, 2**256-1);

            wrappedAggregatorProxy.setPool(address(canonicalPool));

        vm.stopPrank();


        vm.label(poolAddress, "Canonical Pool");

        vm.makePersistent(poolAddress);
    }


    function _makePersistent() internal {
        vm.makePersistent(address(flip));

        vm.makePersistent(address(stflipProxy));
        vm.makePersistent(address(stflipV1));

        vm.makePersistent(address(minter));
        vm.makePersistent(address(minterV1));

        vm.makePersistent(address(burner));
        vm.makePersistent(address(burnerV1));

        vm.makePersistent(address(aggregator));
        vm.makePersistent(address(aggregatorV1));

        vm.makePersistent(address(output));
        vm.makePersistent(address(outputV1));

        vm.makePersistent(address(rebaser));
        vm.makePersistent(address(rebaserV1));

        vm.makePersistent(address(owner));
        vm.makePersistent(address(admin));
    }

    /**
     * @notice Fuzz function to do frontend calculation and `stakeAggregate`
     * @param amount_ The amount that the account will `stakeAggregate`
     * @param lpAmount1_ The amount of FLIP to add to the LP prior to aggregating
     * @param lpAmount2_ The amount of stFLIP to add to the LP prior to aggregating
     * @dev Curve errors when you try to add too imbalanced LP, so we have a minimum of 5k.
     * `calculatePurchasable` is not perfectly accurate, so we check to see that the price of
     * the pool after buying purchasable is accurate to 1 bps. We ensure that the price of the pool
     * is as it should be, whether the user bought all `purchasable`, just a piece, or none at all.
     */
    function testFuzz_StakeAggregate(uint256 amount_, uint256 lpAmount1_, uint256 lpAmount2_) public {
        uint256 flipBalance = flip.balanceOf(owner);
        uint256 stflipBalance = stflip.balanceOf(owner);
        intitialStflipSupply = stflip.totalSupply();

        uint256 lpAmount1 = bound(lpAmount1_, 5000*10**18, flipBalance-1000);
        uint256 lpAmount2 = bound(lpAmount2_, 5000*10**18, stflipBalance-100);

        uint256 amount = bound(amount_, 1000, flipBalance - lpAmount1 );
        console.log(amount_,lpAmount1_,lpAmount2_);
        console.log(amount,lpAmount1,lpAmount2);
        
        vm.startPrank(owner);
            flip.approve(address(canonicalPool), 2**200);
            stflip.approve(address(canonicalPool), 2**200);
            canonicalPool.add_liquidity([lpAmount1, lpAmount2], 0);

            uint256 price = 10**18;

            uint256 purchasable = wrappedAggregatorProxy.calculatePurchasable(price, 10**8, 100, address(canonicalPool), 0, 1);
            uint256 _dx;
            uint256 _minDy;

            if (purchasable == 0) {
                _dx = 0;
                _minDy = 0;
            } else if (purchasable > amount) {
                _dx = amount;
                _minDy = canonicalPool.get_dy(0, 1, _dx);

            } else {
                _dx = purchasable;
                _minDy = canonicalPool.get_dy(0, 1, _dx);
            }
            
            uint256 received = wrappedAggregatorProxy.stakeAggregate(amount, _dx, _minDy);
        vm.stopPrank();

        console.log("price", price);
        console.log("actual price", canonicalPool.get_dy(0,1,10**18));
        console.log("marginal cost", wrappedAggregatorProxy.marginalCost(address(0),0,1,1));
        console.log("pool balances", flip.balanceOf(address(canonicalPool)), stflip.balanceOf(address(canonicalPool)));
        console.log("purchasable", purchasable);
        if (_dx == purchasable && _dx > 0) {
            require(_relativelyEq(price, canonicalPool.get_dy(0,1,10**18)), "testFuzz_StakeAggregate: calculate purchasable did not report correct amount");
        } 
        
        if (_dx == 0) {
            require(canonicalPool.get_dy(0,1,10**18) < price, "testFuzz_StakeAggregate: Calculate purchasable shouldn't be zero");
        }

        if (_dx > 0) {
            require(canonicalPool.get_dy(0,1,10**18) > price, "testFuzz_StakeAggregate: Did not buy enough");
        }

        require(intitialStflipSupply + amount - _dx == stflip.totalSupply(), "testFuzz_StakeAggregate: incorrect supply change");
        require(flip.balanceOf(owner) == flipBalance - lpAmount1 - amount, "testFuzz_StakeAggregate: incorrect FLIP balance change");
        require(stflip.balanceOf(owner) == stflipBalance - lpAmount2 + received, "testFuzz_StakeAggregate: incorrect stFLIP balance change");
    }

    /**
     * @notice Fuzz test to do frontend calculations and run an `unstakeAggregate`
     * @param instantUnstake whether or not the user will sell the stFLIP they can't instant burn
     * @param lpAmount1_ The amount of FLIP to add as LP
     * @param lpAmount2_ The amount of stFLIP to add as LP
     * @param amountClaimable_ The amount of stFLIP to allow instant burns for 
     * @param amountUnstake_ The amount of stFLIP that the user will opt to unstake
     */
    function testFuzz_UnstakeAggregate(bool instantUnstake, uint256 lpAmount1_, uint256 lpAmount2_, uint256 amountClaimable_, uint256 amountUnstake_) public {
        uint256 flipBalance = flip.balanceOf(owner);
        uint256 stflipBalance = stflip.balanceOf(owner);
        intitialStflipSupply = stflip.totalSupply();

        uint256 lpAmount1 = bound(lpAmount1_, 1000*10**18, flipBalance / 2);
        uint256 lpAmount2 = bound(lpAmount2_, 1000*10**18, stflipBalance / 2);
        uint256 amountClaimable = bound(amountClaimable_, 50000, flipBalance - lpAmount1);
        uint256 amountUnstake = bound(amountUnstake_, 1000000, stflipBalance - lpAmount2 );
        console.log(lpAmount1, lpAmount2, amountClaimable, amountUnstake);
        
        vm.startPrank(owner);
            canonicalPool.add_liquidity([lpAmount1, lpAmount2], 0);
        
            uint256 amountSwapOut = 0;
            uint256 amountInstantBurn;
            uint256 amountBurn;
            uint256 amountSwap;
            

            if (amountUnstake < amountClaimable) {
                amountInstantBurn = amountUnstake;
                amountBurn = 0;
                amountSwap = 0;
            }
            else {
                amountInstantBurn = amountClaimable;

                if (instantUnstake == true) {
                    amountSwap = amountUnstake - amountInstantBurn;
                    amountSwapOut = canonicalPool.get_dy(1, 0, amountSwap);
                    amountBurn = 0;
                } 
                else {
                    amountSwap = 0;
                    amountBurn = amountUnstake - amountInstantBurn;
                }
            }
            console.log(amountInstantBurn, amountBurn, amountSwap);
            unstakeAggregateReceived = wrappedAggregatorProxy.unstakeAggregate(amountInstantBurn, amountBurn, amountSwap, amountSwapOut);

        vm.stopPrank();

        require(intitialStflipSupply - amountInstantBurn - amountBurn == stflip.totalSupply(), "testFuzz_UnstakeAggregate: incorrect supply change");
        require(flip.balanceOf(owner) == flipBalance - lpAmount1 + unstakeAggregateReceived, "testFuzz_UnstakeAggregate: incorrect FLIP balance change");
        require(stflip.balanceOf(owner) == stflipBalance - lpAmount2 - amountInstantBurn - amountBurn - amountSwap, "testFuzz_UnstakeAggregate: incorrect stFLIP balance change");
    }


    /**
     * @notice Compares prices to 1 bps
     * @param num1 Number 1
     * @param num2 Number 2
     * @dev Calculate purchasable is not perfectly accurate so we have this. 
     */
    function _relativelyEq(uint256 num1, uint256 num2) internal returns (bool) {
        return (num1 > num2) ? (num1 - num2 <= 10**14) : (num2 - num1 <= 10**14);
    }  

    /**
     * @notice Additional sanity check on stETH/ETH pool
     */
    function testFork_Calculate() public {
        uint256 mainnetFork = vm.createFork(vm.envString("MAINNET_RPC_URL"));
        vm.selectFork(mainnetFork);
        vm.rollFork(14_950_000); //steth was at big discount here (mid june '22)
 
        MainMigration goerliMigration = new MainMigration();
        IStableSwap pool = IStableSwap(0xDC24316b9AE028F1497c275EB9192a3Ea0f67022);
        uint256 price = 10001*10**(decimals - 4);
        uint256 error = 10**(decimals-5);
        uint256 amount = goerliMigration.wrappedAggregatorProxy().calculatePurchasable(price, 
                                                                            error, 
                                                                            1000,
                                                                            0xDC24316b9AE028F1497c275EB9192a3Ea0f67022,
                                                                            0,
                                                                            1);

        vm.deal(owner, amount*2);
        vm.prank(owner);
            pool.exchange{value: amount}(0,1,amount,amount);

        console.log("price", price);
        console.log("actual price", pool.get_dy(0,1,10**18));
        console.log("marginal cost", wrappedAggregatorProxy.marginalCost(address(pool),0,1,1));

        require(_relativelyEq(price, pool.get_dy(0,1,10**18)), "calculate purchasable did not report correct amount");
    }   


    /**
     * @notice Fuzz to confirm that `calculatePurchasable` works
     * @param lpAmount1_ The amount of FLIP to add to LP
     * @param lpAmount2_ The amount of stFLIP to addd to LP
     * @dev Adds the LP and runs calculate purchasable. It purchases all of what is 
     * `purchasable`. If this is greater then zero, it checks that the price of the pool
     * is what was given to `calculatePurchasable`.
     */

    function testFuzz_CalculatePurchasable(uint256 lpAmount1_, uint256 lpAmount2_) public {
        uint256 flipBalance = flip.balanceOf(owner);
        uint256 stflipBalance = stflip.balanceOf(owner);
        uint256 lpAmount1 = bound(lpAmount1_, 1000*10**18, flipBalance / 2);
        uint256 lpAmount2 = bound(lpAmount2_, 1000*10**18, stflipBalance / 2);

        vm.prank(owner);
            canonicalPool.add_liquidity([lpAmount1, lpAmount2], 0);

        uint256 price = 10**18;
        uint256 purchasable = wrappedAggregatorProxy.calculatePurchasable(price, 10**8, 100, address(canonicalPool), 0, 1);

        canonicalPool = wrappedAggregatorProxy.canonicalPool();


        if (purchasable > 0) {

            vm.startPrank(owner);
                flip.mint(owner, purchasable);
                canonicalPool.exchange(0, 1, purchasable, 0);
            vm.stopPrank();
        
            console.log("price", price);
            console.log("actual price", canonicalPool.get_dy(0,1,10**18));
            console.log("marginal cost", wrappedAggregatorProxy.marginalCost(address(canonicalPool),0,1,1));

            require(_relativelyEq(price, canonicalPool.get_dy(0,1,10**18)), "testFuzz_CalculatePurchasable: Calculate purchasable did not report correct amount");

        } else {
            require(canonicalPool.get_dy(0,1,10**18) < price, "testFuzz_CalculatePurchasable: Calculate purchasable shouldn't be zero");
        }
    }
}

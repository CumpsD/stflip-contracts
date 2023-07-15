pragma solidity ^0.8.20;

// import "./IERC20.sol";
import "../tenderswap/TenderSwap.sol";
import "../mock/IStableSwap.sol";
import "./MinterV1.sol";
import "./BurnerV1.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract AggregatorV1 is Initializable {

    IERC20 public stflip;
    IERC20 public flip;
    MinterV1 public minter;
    BurnerV1 public burner;
    TenderSwap public tenderSwap;

    constructor () {
        _disableInitializers();
    }

    function initialize (address minter_, address burner_, address liquidityPool_, address stflip_, address flip_) initializer public {
        // // associating relevant contracts
        minter = MinterV1(minter_);
        burner = BurnerV1(burner_);
        tenderSwap = TenderSwap(liquidityPool_);
        flip = IERC20(flip_);
        stflip = IERC20(stflip_);

        // giving infinite approvals to the curve pool and the minter
        flip.approve(address(tenderSwap), 2**256-1);
        flip.approve(address(minter), 2**256-1);
        stflip.approve(address(burner), 2**256-1);
        stflip.approve(address(tenderSwap), 2**256-1);

    }

    event Aggregation (address sender, uint256 total, uint256 swapped, uint256 minted);
    event BurnAggregation (address sender, uint256 amountInstantBurn, uint256 amountBurn, uint256 received);
    
    /**
    * @notice Spends stFLIP for FLIP via swap, instant burn, and unstake request.
    * @param amountInstantBurn The amount of stFLIP to instant burn
    * @param amountBurn The amount of stFLIP to burn.
    * @param amountSwap The amount of stFLIP to swap for FLIP
    * @param minimumAmountSwapOut The minimum amount of FLIP  to receive from the swap piece of the route
    * @param deadline Unix swap deadline
    * @dev Contract will only swap if `amountSwap > 0`. Contract will only mint if amountSwap < amountTotal.
     */
    function unstakeAggregate(uint256 amountInstantBurn, uint256 amountBurn, uint256 amountSwap, uint256 minimumAmountSwapOut, uint256 deadline)
        external
        returns (uint256)
    {
        uint256 total = amountInstantBurn + amountBurn + amountSwap;
        uint256 received = 0;

        stflip.transferFrom(msg.sender, address(this), total);
        
        if (amountInstantBurn > 0) {
            uint256 instantBurnId = burner.burn(msg.sender, amountInstantBurn);
            burner.redeem(instantBurnId); 
        }

        if (amountBurn > 0) {
            uint256 burnId = burner.burn(msg.sender, amountBurn);
        }

        if (amountSwap > 0) {
            received = tenderSwap.swap(stflip, amountSwap, minimumAmountSwapOut, deadline);
            flip.transfer(msg.sender, received - 1);
        }

        emit BurnAggregation(msg.sender,amountInstantBurn, amountBurn, received-1);

        return amountInstantBurn + received;
    }

    /**
    * @notice Spends FLIP to mint and swap for stFLIP in the same transaction.
    * @param amountTotal The total amount of FLIP to spend.
    * @param amountSwap The amount of FLIP to swap for stFLIP.
    * @param minimumAmountSwapOut The minimum amount of stFLIP to receive from the swap piece of the route
    * @param deadline Unix swap deadline
    * @dev Contract will only swap if `amountSwap > 0`. Contract will only mint if amountSwap < amountTotal. 
    * Use `calculatePurchasable` on frontend to determine route prior to calling this.  
     */
    function stakeAggregate(uint256 amountTotal, uint256 amountSwap, uint256 minimumAmountSwapOut, uint256 deadline)
        external
        returns (uint256)
    {
        flip.transferFrom(msg.sender, address(this), amountTotal);
        uint256 received;
        uint256 mintAmount = amountTotal - amountSwap;

        if (amountSwap > 0){
            received = tenderSwap.swap(flip, amountSwap, minimumAmountSwapOut, deadline);
        } else {
            received = 0;
        }

        if (mintAmount > 0) {
            minter.mint(address(this), mintAmount);

        }

        stflip.transfer( msg.sender, mintAmount + received - 1);
        emit Aggregation (msg.sender,mintAmount + received, received, mintAmount);
        return mintAmount + received;
    }


    function marginalCost(uint256 amount) external view returns (uint256){
        return _marginalCost(amount);
    }

        // calculates the marginal cost for the last unit of swap
    // essentially calculates the price of the pool (dy/dx) after a given input

    /**
    * @notice Calculates the marginal cost for the last unit of swap of `amount`
    * @param amount The size to calculate marginal cost for the last unit of swap
     */
    function _marginalCost(uint256 amount) internal view returns (uint256) {
        uint256 dx1 = amount;
        uint256 dx2 = amount + 10**18;
        uint256 amt1 = tenderSwap.calculateSwap(flip, dx1);
        uint256 amt2 = tenderSwap.calculateSwap(flip, dx2);

        return (amt2 - amt1)* 10**18 / (dx2 - dx1);
    }

    /**
    * @notice Calculates the total amount of stFLIP purchasable within targetError of a certain targetPrice
    * @param targetPrice The target price to calculate the amount of stFLIP purchasable until. 10**18 = 1
    * @param targetError The acceptable range around `targetPrice` for acceptable return value. 10**18 = 100%
    * @param attempts The number of hops within the binary search allowed before reverting
    * @dev Uses binary search. Must specify number of attempts to prevent infinite loop. This is not a perfect
    * calculation because the marginal cost is not exactly equal to dy. This is a decent approximation though
    * An analytical solution would be ideal but its not easy to get.
     */
    function calculatePurchasable(uint256 targetPrice, uint256 targetError, uint256 attempts)
        external
        view
        returns (uint256)
    {
        uint256 first = 0;
        uint256 mid = 0;
        // this would be the absolute maximum of FLIP spendable, so we can start there
        uint256 last = stflip.balanceOf(address(tenderSwap));
        uint256 price = 10**17;

        uint256 error = targetError;

        uint256 startPrice = _marginalCost(1*10**18);
        if (startPrice < targetPrice) {
            return 0;
        }

        while (true) {

            require(attempts > 0, "no attempts left");


            mid = (last+first) / 2;

            price = _marginalCost(mid);

            if (price > targetPrice) {
                first = mid + 1;
            } else {
                last = mid - 1;
            }

            attempts = attempts - 1;

            // calculate the error between the marginalPrice we calculate and the targetPrice
            if (price < targetPrice) {
                error = 10**18 - (price*10**18/targetPrice);
            } else {
                error = (price*10**18/targetPrice) - 10**18;
            }

            console.log(mid, price, error, attempts);

            // if the error is acceptable then we can return the amountIn we found
            if (error < targetError) {
                return mid;
            }
        }
    }


    /// @notice Marginal cost for mainnet
    function _marginalCostMainnet(address pool, int128 tokenIn, int128 tokenOut, uint256 amount) internal view returns (uint256) {
        uint256 dx1 = amount;
        uint256 dx2 = amount + 10**18;

        uint256 amt1 = IStableSwap(pool).get_dy(tokenIn, tokenOut, dx1);
        uint256 amt2 = IStableSwap(pool).get_dy(tokenIn, tokenOut, dx2);

        return (amt2 - amt1)* 10**18 / (dx2 - dx1);
    }


    /// @notice Calculate purchaseable function for mainnet
    function calculatePurchasableMainnet(uint256 targetPrice, uint256 targetError, uint256 attempts, address pool, int128 tokenIn, int128 tokenOut)
        external
        view
        returns (uint256)
    {
        uint256 first = 0;
        uint256 mid = 0;
        // this would be the absolute maximum of FLIP spendable, so we can start there
        uint256 last = IStableSwap(pool).balances(uint256(int256(tokenOut)));
        uint256 price;
        uint256 currentError = targetError;
        uint256 startPrice = _marginalCostMainnet(pool, tokenIn, tokenOut, 1*10**18);

        if (startPrice < targetPrice) {
            return 0;
        }

        while (true) {
            require(attempts > 0, "Aggregator: no attempts left");

            mid = (last+first) / 2;
            price = _marginalCostMainnet(pool, tokenIn, tokenOut, mid);

            if (price > targetPrice) {
                first = mid + 1;
            } else {
                last = mid - 1;
            }

            attempts = attempts - 1;

            if (price < targetPrice) {
                currentError = 10**18 - (price*10**18/targetPrice);
            } else {
                currentError = (price*10**18/targetPrice) - 10**18;
            }

            if (currentError < targetError) {
                console.log("price, target", price, targetPrice);
                console.log("curr, target", currentError, targetError);
                return mid;
            }
        }
    }

}

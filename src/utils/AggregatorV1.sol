pragma solidity ^0.8.4;

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
        // associating relevant contracts
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
    
    // 1) transfer the stflip from user to this contract
    // 2) burn amountInstantBurn and claim it immediately to msg.sender
    // 3) perform burn for amountBurn to msg.sender
    // 4) perform swap for amountSwap
    // 5) transfer funds back to user 
    //      TODO: use LP that has a 'to' field 
    // 6) emit BurnAggregation
    // 7) return amount of FLIP that user received
    function unstakeAggregate(uint256 amountInstantBurn, uint256 amountBurn, uint256 amountSwap, uint256 minimumAmountSwapOut, uint256 deadline)
        external
        returns (uint256)
    {
        uint256 total = amountInstantBurn + amountBurn + amountSwap;
        uint256 received = 0;

        console.log("transferring from user to contract", total);
        stflip.transferFrom(msg.sender, address(this), total);
        console.log("FLIP balance of contract ", flip.balanceOf(address(this)));
        console.log("stFLIP balance of contract ", stflip.balanceOf(address(this)));
        
        if (amountInstantBurn > 0) {
            console.log("performing instant burn for ", amountInstantBurn);
            uint256 instantBurnId = burner.burn(msg.sender, amountInstantBurn);
            burner.redeem(instantBurnId); 
        }

        if (amountBurn > 0) {
            console.log("performing normal burn for ", amountBurn);
            uint256 burnId = burner.burn(msg.sender, amountBurn);
        }

        if (amountSwap > 0) {
            console.log("performing swap for ", amountSwap);
            received = tenderSwap.swap(stflip, amountSwap, minimumAmountSwapOut, deadline);
            console.log("transferring FLIP back to user ", received - 1);
            console.log("FLIP balance of contract ", flip.balanceOf(address(this)));
            console.log("stFLIP balance of contract ", stflip.balanceOf(address(this)));
            flip.transfer(msg.sender, received - 1);
        }

        emit BurnAggregation(msg.sender,amountInstantBurn, amountBurn, received);

        return amountInstantBurn + received;
    }
    // 1) transfer all FLIP from user to this contract
    // 2) swap amountSwap amount of FLIP in the pool for minimum _minDy
    // 2) mint the excess amount of FLIP into stFLIP (amountTotal - amountSwap)
    // 3) transfer the amount of stFLIP bought + the amount of stFLIP minted back to the user
    function stakeAggregate(uint256 amountTotal, uint256 amountSwap, uint256 minimumAmountSwapOut, uint256 _deadline)
        external
        returns (uint256)
    {
        console.log("transferring to contract ", amountTotal);
        flip.transferFrom(msg.sender, address(this), amountTotal);
        uint256 received;
        uint256 mintAmount = amountTotal - amountSwap;

        if (amountSwap > 0){
             console.log("swapping ", amountSwap);

            received = tenderSwap.swap(flip, amountSwap, minimumAmountSwapOut, _deadline);
            console.log("received", received);
        } else {
            received = 0;
        }

        if (mintAmount > 0) {
             console.log("minting ", mintAmount);

            minter.mint(address(this), mintAmount);

            console.log("successfully minted");
        }

        console.log("transferring back to user ", mintAmount + received - 1);
        console.log("Mintamount", mintAmount);
        console.log("Received", received);
        console.log("actual balance", stflip.balanceOf(address(this)));

        stflip.transfer( msg.sender, mintAmount + received - 1);

        emit Aggregation (msg.sender,mintAmount + received, received, mintAmount);

        console.log("aggregation complete. total, received, mintAmount");
        console.log(mintAmount + received, received, mintAmount);
        return mintAmount + received;
    }


    function marginalCost(uint256 amount) external view returns (uint256){
        return _marginalCost(amount);
    }

        // calculates the marginal cost for the last unit of swap
    // essentially calculates the price of the pool (dy/dx) after a given input
    function _marginalCost(uint256 amount) internal view returns (uint256) {
        uint256 dx1 = amount;
        uint256 dx2 = amount + 10**18;
        uint256 amt1 = tenderSwap.calculateSwap(flip, dx1);
        uint256 amt2 = tenderSwap.calculateSwap(flip, dx2);

        return (amt2 - amt1)* 10**18 / (dx2 - dx1);
    }


    // calculates the total amount of stFLIP purchasable within targetError of a certain targetPrice
    // it uses binary search. specify a number of attempts so it doesnt get stuck in an infinite loop if it doesn't find something
    function calculatePurchasable(uint256 targetPrice, uint256 targetError, uint256 attempts)
        external
        view
        returns (uint256)
    {
        uint256 first = 0;
        uint256 mid = 0;
        // this would be the absolute maximum of FLIP spendable, so we can start there
        uint256 last = stflip.balanceOf(address(tenderSwap));
        // initiating the variable
        uint256 price = 10**17;

        uint256 error = targetError;


        uint256 startPrice = _marginalCost(1*10**18);
        if (startPrice < targetPrice) {
            console.log(startPrice, " less than the targetPrice of ",targetPrice, " returning zero ");
            return 0;
        }

        console.log("targetPrice, targetError, attempts", targetPrice, targetError, attempts);
        console.log("amt, price, error, attempts");


        while (true) {

            require(attempts > 0, "no attempts left");


            mid = (last+first) / 2;

            price = _marginalCost(mid);

            // go into the top half or the bottom half?
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
                console.log("returning val ", mid);
                return mid;
            }
        }
    }

    function _marginalCostMainnet(address pool, int128 tokenIn, int128 tokenOut, uint256 amount) internal view returns (uint256) {
        uint256 dx1 = amount;
        uint256 dx2 = amount + 10**18;

        uint256 amt1 = IStableSwap(pool).get_dy(tokenIn, tokenOut, dx1);
        uint256 amt2 = IStableSwap(pool).get_dy(tokenIn, tokenOut, dx2);

        return (amt2 - amt1)* 10**18 / (dx2 - dx1);
    }

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

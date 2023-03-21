pragma solidity 0.8.4;

// import "./IERC20.sol";
import "../contracts/tenderswap/TenderSwap.sol";



contract StakeAggregator {
    using SafeMath for uint256;


    IERC20 public agg_stflip;
    IERC20 public agg_flip;
    Minter public agg_minter;
    TenderSwap public agg_liquidityPool;

    constructor(address minter_, address liquidityPool_, address stflip_, address flip_) {
        // associating relevant contracts
        agg_minter = Minter(minter_);
        agg_liquidityPool = TenderSwap(liquidityPool_);
        agg_flip = IERC20(flip_);
        agg_stflip = IERC20(stflip_);

        // giving infinite approvals to the curve pool and the minter
        agg_flip.approve(address(agg_liquidityPool), 2**256-1);
        agg_flip.approve(address(agg_minter), 2**256-1);
    }

    event Aggregation (uint256 total, uint256 swapped, uint256 minted);


    // 1) transfer all FLIP from user to this contract
    // 2) swap _dx amount of FLIP in the pool for minimum _minDy
    // 2) mint the excess amount of FLIP into stFLIP (amount - _dx)
    // 3) transfer the amount of stFLIP bought + the amount of stFLIP minted back to the user
    function aggregate(uint256 amount, uint256 _dx, uint256 _minDy, uint256 _deadline)
        external
        returns (uint256)
    {
        console.log("transferring to contract ", uint2str(amount));
        agg_flip.transferFrom(msg.sender, address(this), amount);
        // revert("here 374");
        uint256 received;
        uint256 mintAmount = amount-_dx;

        if (_dx > 0){
             console.log("swapping ", uint2str(_dx));

            received = agg_liquidityPool.swap(agg_flip, _dx, _minDy, _deadline);
        } else {
            received = 0;
        }

        if (mintAmount > 0) {
             console.log("minting ", uint2str(mintAmount));

            agg_minter.mint(address(this), mintAmount);
        }

        console.log("transferring back to user ", uint2str(mintAmount + received - 1));
        console.log("Mintamount", uint2str(mintAmount));
        console.log("Received", uint2str(received));
        console.log("actual balance", agg_stflip.balanceOf(address(this)));

        agg_stflip.transfer( msg.sender, mintAmount + received - 1);

        emit Aggregation (mintAmount + received, received, mintAmount);

        console.log("aggregation complete. total, received, mintAmount");
        console.log(uint2str(mintAmount + received), uint2str(received), uint2str(mintAmount));
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
        uint256 amt1 = agg_liquidityPool.calculateSwap(agg_flip, dx1);
        uint256 amt2 = agg_liquidityPool.calculateSwap(agg_flip, dx2);

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
        uint256 last = agg_stflip.balanceOf(address(agg_liquidityPool));
        // initiating the variable
        uint256 price = 10**17;

        uint256 error = targetError;


        uint256 startPrice = _marginalCost(1*10**18);
        if (startPrice < targetPrice) {
            console.log(uint2str(startPrice), " less than the targetPrice of ", uint2str(targetPrice), " returning zero ");
            return 0;
        }

        console.log("targetPrice, targetError, attempts", uint2str(targetPrice), uint2str(targetError), uint2str(attempts));
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

            console.log(uint2str(mid), uint2str(price), uint2str(error), uint2str(attempts));

            // if the error is acceptable then we can return the amountIn we found
            if (error < targetError) {
                console.log("returning val ", uint2str(mid));
                return mid;
            }
        }
    }

   function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}
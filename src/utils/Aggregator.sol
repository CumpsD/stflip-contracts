pragma solidity ^0.8.4;

// import "./IERC20.sol";
import "../tenderswap/TenderSwap.sol";
import "./Minter.sol";
import "./Burner.sol";
import "forge-std/console.sol";


contract Aggregator {


    IERC20 public stflip;
    IERC20 public flip;
    Minter public minter;
    Burner public burner;
    TenderSwap public tenderSwap;

    constructor(address minter_, address burner_, address liquidityPool_, address stflip_, address flip_) {
        // associating relevant contracts
        minter = Minter(minter_);
        burner = Burner(burner_);
        tenderSwap = TenderSwap(liquidityPool_);
        flip = IERC20(flip_);
        stflip = IERC20(stflip_);

        // giving infinite approvals to the curve pool and the minter
        flip.approve(address(tenderSwap), 2**256-1);
        flip.approve(address(minter), 2**256-1);
        stflip.approve(address(burner), 2**256-1);
        stflip.approve(address(tenderSwap), 2**256-1);

    }

    event Aggregation (uint256 total, uint256 swapped, uint256 minted);
    event BurnAggregation (uint256 amountInstantBurn, uint256 amountBurn, uint256 received);
    
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
            console.log("transferring FLIP back to user ", received);
            console.log("FLIP balance of contract ", flip.balanceOf(address(this)));
            console.log("stFLIP balance of contract ", stflip.balanceOf(address(this)));
            flip.transfer(msg.sender, received);
        }

        emit BurnAggregation(amountInstantBurn, amountBurn, received);

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
        console.log("transferring to contract ", uint2str(amountTotal));
        flip.transferFrom(msg.sender, address(this), amountTotal);
       
        uint256 received;
        uint256 mintAmount = amountTotal - amountSwap;

        if (amountSwap > 0){
             console.log("swapping ", uint2str(amountSwap));

            received = tenderSwap.swap(flip, amountSwap, minimumAmountSwapOut, _deadline);
            console.log("received", uint2str(received));
        } else {
            received = 0;
        }

        if (mintAmount > 0) {
             console.log("minting ", uint2str(mintAmount));

            minter.mint(address(this), mintAmount);

            console.log("successfully minted");
        }

        console.log("transferring back to user ", uint2str(mintAmount + received - 1));
        console.log("Mintamount", uint2str(mintAmount));
        console.log("Received", uint2str(received));
        console.log("actual balance", stflip.balanceOf(address(this)));

        stflip.transfer( msg.sender, mintAmount + received - 1);

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

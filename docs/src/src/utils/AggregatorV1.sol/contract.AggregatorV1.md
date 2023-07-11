# AggregatorV1
[Git Source](https://github.com/thunderhead-labs/stflip-contracts/blob/a54a4561fa7129ea9a332ff80d4d3e8aee76ae43/src/utils/AggregatorV1.sol)

**Inherits:**
Initializable


## State Variables
### stflip

```solidity
IERC20 public stflip;
```


### flip

```solidity
IERC20 public flip;
```


### minter

```solidity
MinterV1 public minter;
```


### burner

```solidity
BurnerV1 public burner;
```


### tenderSwap

```solidity
TenderSwap public tenderSwap;
```


## Functions
### constructor


```solidity
constructor();
```

### initialize


```solidity
function initialize(address minter_, address burner_, address liquidityPool_, address stflip_, address flip_)
    public
    initializer;
```

### unstakeAggregate

Spends stFLIP for FLIP via swap, instant burn, and unstake request.

*Contract will only swap if `amountSwap > 0`. Contract will only mint if amountSwap < amountTotal.*


```solidity
function unstakeAggregate(
    uint256 amountInstantBurn,
    uint256 amountBurn,
    uint256 amountSwap,
    uint256 minimumAmountSwapOut,
    uint256 deadline
) external returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amountInstantBurn`|`uint256`|The amount of stFLIP to instant burn|
|`amountBurn`|`uint256`|The amount of stFLIP to burn.|
|`amountSwap`|`uint256`|The amount of stFLIP to swap for FLIP|
|`minimumAmountSwapOut`|`uint256`|The minimum amount of FLIP  to receive from the swap piece of the route|
|`deadline`|`uint256`||


### stakeAggregate

Spends FLIP to mint and swap for stFLIP in the same transaction.

*Contract will only swap if `amountSwap > 0`. Contract will only mint if amountSwap < amountTotal.
Use `calculatePurchasable` on frontend to determine route prior to calling this.*


```solidity
function stakeAggregate(uint256 amountTotal, uint256 amountSwap, uint256 minimumAmountSwapOut, uint256 _deadline)
    external
    returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amountTotal`|`uint256`|The total amount of FLIP to spend.|
|`amountSwap`|`uint256`|The amount of FLIP to swap for stFLIP.|
|`minimumAmountSwapOut`|`uint256`|The minimum amount of stFLIP to receive from the swap piece of the route|
|`_deadline`|`uint256`|Unix swap deadline|


### marginalCost


```solidity
function marginalCost(uint256 amount) external view returns (uint256);
```

### _marginalCost

Calculates the marginal cost for the last unit of swap of `amount`


```solidity
function _marginalCost(uint256 amount) internal view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The size to calculate marginal cost for the last unit of swap|


### calculatePurchasable

Calculates the total amount of stFLIP purchasable within targetError of a certain targetPrice

*Uses binary search. Must specify number of attempts to prevent infinite loop. This is not a perfect
calculation because the marginal cost is not exactly equal to dy. This is a decent approximation though
An analytical solution would be ideal but its not easy to get.*


```solidity
function calculatePurchasable(uint256 targetPrice, uint256 targetError, uint256 attempts)
    external
    view
    returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`targetPrice`|`uint256`|The target price to calculate the amount of stFLIP purchasable until. 10**18 = 1|
|`targetError`|`uint256`|The acceptable range around `targetPrice` for acceptable return value. 10**18 = 100%|
|`attempts`|`uint256`|The number of hops within the binary search allowed before reverting|


### _marginalCostMainnet

Marginal cost for mainnet


```solidity
function _marginalCostMainnet(address pool, int128 tokenIn, int128 tokenOut, uint256 amount)
    internal
    view
    returns (uint256);
```

### calculatePurchasableMainnet

Calculate purchaseable function for mainnet


```solidity
function calculatePurchasableMainnet(
    uint256 targetPrice,
    uint256 targetError,
    uint256 attempts,
    address pool,
    int128 tokenIn,
    int128 tokenOut
) external view returns (uint256);
```

## Events
### Aggregation

```solidity
event Aggregation(address sender, uint256 total, uint256 swapped, uint256 minted);
```

### BurnAggregation

```solidity
event BurnAggregation(address sender, uint256 amountInstantBurn, uint256 amountBurn, uint256 received);
```


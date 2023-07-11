# AggregatorV1
[Git Source](https://github.com/thunderhead-labs/stflip-contracts/blob/7cc8544d9ea72822b709c48cbb1ce3c466520cc8/src/utils/AggregatorV1.sol)

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


```solidity
function unstakeAggregate(
    uint256 amountInstantBurn,
    uint256 amountBurn,
    uint256 amountSwap,
    uint256 minimumAmountSwapOut,
    uint256 deadline
) external returns (uint256);
```

### stakeAggregate


```solidity
function stakeAggregate(uint256 amountTotal, uint256 amountSwap, uint256 minimumAmountSwapOut, uint256 _deadline)
    external
    returns (uint256);
```

### marginalCost


```solidity
function marginalCost(uint256 amount) external view returns (uint256);
```

### _marginalCost


```solidity
function _marginalCost(uint256 amount) internal view returns (uint256);
```

### calculatePurchasable


```solidity
function calculatePurchasable(uint256 targetPrice, uint256 targetError, uint256 attempts)
    external
    view
    returns (uint256);
```

### _marginalCostMainnet


```solidity
function _marginalCostMainnet(address pool, int128 tokenIn, int128 tokenOut, uint256 amount)
    internal
    view
    returns (uint256);
```

### calculatePurchasableMainnet


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


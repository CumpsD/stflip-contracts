# SwapUtils
[Git Source](https://github.com/thunderhead-labs/stflip-contracts/blob/7cc8544d9ea72822b709c48cbb1ce3c466520cc8/src/tenderswap/SwapUtils.sol)


## State Variables
### POOL_PRECISION_DECIMALS

```solidity
uint8 public constant POOL_PRECISION_DECIMALS = 18;
```


### FEE_DENOMINATOR

```solidity
uint256 private constant FEE_DENOMINATOR = 10 ** 10;
```


### MAX_SWAP_FEE

```solidity
uint256 public constant MAX_SWAP_FEE = 10 ** 8;
```


### MAX_ADMIN_FEE

```solidity
uint256 public constant MAX_ADMIN_FEE = 10 ** 10;
```


### MAX_LOOP_LIMIT

```solidity
uint256 private constant MAX_LOOP_LIMIT = 256;
```


### NUM_TOKENS

```solidity
uint256 internal constant NUM_TOKENS = 2;
```


### A_PRECISION

```solidity
uint256 public constant A_PRECISION = 100;
```


### MAX_A

```solidity
uint256 public constant MAX_A = 10 ** 6;
```


### MAX_A_CHANGE

```solidity
uint256 private constant MAX_A_CHANGE = 2;
```


### MIN_RAMP_TIME

```solidity
uint256 private constant MIN_RAMP_TIME = 14 days;
```


## Functions
### swap

swap two tokens in the pool


```solidity
function swap(
    PooledToken storage tokenFrom,
    PooledToken storage tokenTo,
    uint256 dx,
    uint256 minDy,
    Amplification storage amplificationParams,
    FeeParams storage feeParams
) external returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenFrom`|`PooledToken`|the token to sell|
|`tokenTo`|`PooledToken`|the token to buy|
|`dx`|`uint256`|the number of tokens to sell|
|`minDy`|`uint256`|the min amount the user would like to receive (revert if not met)|
|`amplificationParams`|`Amplification`|amplification parameters for the pool|
|`feeParams`|`FeeParams`|fee parameters for the pool|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|amount of token user received on swap|


### getVirtualPrice

Get the virtual price, to help calculate profit


```solidity
function getVirtualPrice(
    PooledToken storage token0,
    PooledToken storage token1,
    Amplification storage amplificationParams,
    LiquidityPoolToken lpToken
) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token0`|`PooledToken`|token0 in the pool|
|`token1`|`PooledToken`|token1 in the pool|
|`amplificationParams`|`Amplification`|amplification parameters for the pool|
|`lpToken`|`LiquidityPoolToken`|Liquidity pool token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|the virtual price, scaled to precision of POOL_PRECISION_DECIMALS|


### calculateSwap

Externally calculates a swap between two tokens.


```solidity
function calculateSwap(
    PooledToken storage tokenFrom,
    PooledToken storage tokenTo,
    uint256 dx,
    Amplification storage amplificationParams,
    FeeParams storage feeParams
) external view returns (uint256 dy);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenFrom`|`PooledToken`|the token to sell|
|`tokenTo`|`PooledToken`|the token to buy|
|`dx`|`uint256`|the number of tokens to sell|
|`amplificationParams`|`Amplification`|amplification parameters for the pool|
|`feeParams`|`FeeParams`|fee parameters for the pool|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`dy`|`uint256`|the number of tokens the user will get|


### addLiquidity

Add liquidity to the pool


```solidity
function addLiquidity(
    PooledToken[2] memory tokens,
    uint256[2] memory amounts,
    uint256 minToMint,
    Amplification storage amplificationParams,
    FeeParams storage feeParams,
    LiquidityPoolToken lpToken
) external returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokens`|`PooledToken[2]`|Array of [token0, token1]|
|`amounts`|`uint256[2]`|the amounts of each token to add, in their native precision according to the cardinality of 'tokens'|
|`minToMint`|`uint256`|the minimum LP tokens adding this amount of liquidity should mint, otherwise revert. Handy for front-running mitigation allowed addresses. If the pool is not in the guarded launch phase, this parameter will be ignored.|
|`amplificationParams`|`Amplification`|amplification parameters for the pool|
|`feeParams`|`FeeParams`|fee parameters for the pool|
|`lpToken`|`LiquidityPoolToken`|Liquidity pool token contract|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|amount of LP token user received|


### removeLiquidity

Burn LP tokens to remove liquidity from the pool.

*Liquidity can always be removed, even when the pool is paused.*


```solidity
function removeLiquidity(
    uint256 amount,
    PooledToken[2] calldata tokens,
    uint256[2] calldata minAmounts,
    LiquidityPoolToken lpToken
) external returns (uint256[2] memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|the amount of LP tokens to burn|
|`tokens`|`PooledToken[2]`|Array of [token0, token1]|
|`minAmounts`|`uint256[2]`|the minimum amounts of each token in the pool acceptable for this burn. Useful as a front-running mitigation. Should be according to the cardinality of 'tokens'|
|`lpToken`|`LiquidityPoolToken`|Liquidity pool token contract|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256[2]`|amounts of tokens the user receives for each token in the pool according to [token0, token1] cardinality|


### removeLiquidityOneToken

Remove liquidity from the pool all in one token.


```solidity
function removeLiquidityOneToken(
    uint256 tokenAmount,
    PooledToken storage tokenReceive,
    PooledToken storage tokenCounterpart,
    uint256 minAmount,
    Amplification storage amplificationParams,
    FeeParams storage feeParams,
    LiquidityPoolToken lpToken
) external returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenAmount`|`uint256`|the amount of the lp tokens to burn|
|`tokenReceive`|`PooledToken`| the token you want to receive|
|`tokenCounterpart`|`PooledToken`|the counterpart token in the pool of the token you want to receive|
|`minAmount`|`uint256`|the minimum amount to withdraw, otherwise revert|
|`amplificationParams`|`Amplification`|amplification parameters for the pool|
|`feeParams`|`FeeParams`|fee parameters for the pool|
|`lpToken`|`LiquidityPoolToken`|Liquidity pool token contract|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|amount chosen token that user received|


### removeLiquidityImbalance

Remove liquidity from the pool, weighted differently than the
pool's current balances.


```solidity
function removeLiquidityImbalance(
    PooledToken[2] memory tokens,
    uint256[2] memory amounts,
    uint256 maxBurnAmount,
    Amplification storage amplificationParams,
    FeeParams storage feeParams,
    LiquidityPoolToken lpToken
) public returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokens`|`PooledToken[2]`|Array of [token0, token1]|
|`amounts`|`uint256[2]`|how much of each token to withdraw according to cardinality of pooled tokens|
|`maxBurnAmount`|`uint256`|the max LP token provider is willing to pay to remove liquidity. Useful as a front-running mitigation.|
|`amplificationParams`|`Amplification`|amplification parameters for the pool|
|`feeParams`|`FeeParams`|fee parameters for the pool|
|`lpToken`|`LiquidityPoolToken`|Liquidity pool token contract|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|actual amount of LP tokens burned in the withdrawal|


### calculateWithdrawOneToken

Calculate the dy, the amount of selected token that user receives and
the fee of withdrawing in one token


```solidity
function calculateWithdrawOneToken(
    uint256 tokenAmount,
    PooledToken storage tokenReceive,
    PooledToken storage tokenCounterpart,
    Amplification storage amplificationParams,
    FeeParams storage feeParams,
    LiquidityPoolToken lpToken
) internal view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenAmount`|`uint256`|the amount to withdraw in the pool's precision|
|`tokenReceive`|`PooledToken`|which token will be withdrawn|
|`tokenCounterpart`|`PooledToken`|the token we need to swap for|
|`amplificationParams`|`Amplification`|amplification parameters for the pool|
|`feeParams`|`FeeParams`|fee parameters for the pool|
|`lpToken`|`LiquidityPoolToken`|liquidity pool token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|the amount of token user will receive|


### _calculateWithdrawOneToken

Calculate the dy, the amount of selected token that user receives and
the fee of withdrawing in one token


```solidity
function _calculateWithdrawOneToken(
    uint256 tokenAmount,
    PooledToken storage tokenReceive,
    PooledToken storage tokenCounterpart,
    uint256 totalSupply,
    Amplification storage amplificationParams,
    FeeParams storage feeParams
) internal view returns (uint256, uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenAmount`|`uint256`|the amount to withdraw in the pool's precision|
|`tokenReceive`|`PooledToken`|which token will be withdrawn|
|`tokenCounterpart`|`PooledToken`|the token we need to swap for|
|`totalSupply`|`uint256`|total supply of LP tokens|
|`amplificationParams`|`Amplification`|amplification parameters for the pool|
|`feeParams`|`FeeParams`|fee parameters for the pool|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|the amount of token user will receive|
|`<none>`|`uint256`||


### calculateWithdrawOneTokenDY

Calculate the dy of withdrawing in one token


```solidity
function calculateWithdrawOneTokenDY(
    uint256 tokenAmount,
    PooledToken storage tokenReceive,
    PooledToken storage tokenCounterpart,
    uint256 totalSupply,
    uint256 preciseA,
    uint256 swapFee
) internal view returns (uint256, uint256, uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenAmount`|`uint256`|the amount to withdraw in the pools precision|
|`tokenReceive`|`PooledToken`|Swap struct to read from|
|`tokenCounterpart`|`PooledToken`|which token will be withdrawn|
|`totalSupply`|`uint256`|total supply of the lp token|
|`preciseA`|`uint256`||
|`swapFee`|`uint256`||

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|the d and the new y after withdrawing one token|
|`<none>`|`uint256`||
|`<none>`|`uint256`||


### calculateTokenAmount

A simple method to calculate prices from deposits or
withdrawals, excluding fees but including slippage. This is
helpful as an input into the various "min" parameters on calls
to fight front-running

*This shouldn't be used outside frontends for user estimates.*


```solidity
function calculateTokenAmount(
    PooledToken[2] memory tokens,
    uint256[] calldata amounts,
    bool deposit,
    Amplification storage amplificationParams,
    LiquidityPoolToken lpToken
) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokens`|`PooledToken[2]`|Array of tokens in the pool according to pool cardinality [token0, token1]|
|`amounts`|`uint256[]`|an array of token amounts to deposit or withdrawal, corresponding to tokens. The amount should be in each pooled token's native precision.|
|`deposit`|`bool`|whether this is a deposit or a withdrawal|
|`amplificationParams`|`Amplification`|amplification parameters for the pool|
|`lpToken`|`LiquidityPoolToken`|liquidity pool token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|if deposit was true, total amount of lp token that will be minted and if deposit was false, total amount of lp token that will be burned|


### getYD

Calculate the price of a token in the pool with given
precision-adjusted balances and a particular D.

*This is accomplished via solving the invariant iteratively.
See the StableSwap paper and Curve.fi implementation for further details.
x_1**2 + x1 * (sum' - (A*n**n - 1) * D / (A * n**n)) = D ** (n + 1) / (n ** (2 * n) * prod' * A)
x_1**2 + b*x_1 = c
x_1 = (x_1**2 + c) / (2*x_1 + b)*


```solidity
function getYD(uint256 a, uint256 xpFrom, uint256 d) internal pure returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`a`|`uint256`|the amplification coefficient * n * (n - 1). See the StableSwap paper for details.|
|`xpFrom`|`uint256`|a precision-adjusted balance of the token to send|
|`d`|`uint256`|the stableswap invariant|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|the price of the token, in the same precision as in xp|


### _calculateSwap

Internally calculates a swap between two tokens.

*The caller is expected to transfer the actual amounts (dx and dy)
using the token contracts.*


```solidity
function _calculateSwap(
    PooledToken storage tokenFrom,
    PooledToken storage tokenTo,
    uint256 dx,
    Amplification storage amplificationParams,
    FeeParams storage feeParams
) internal view returns (uint256 dy, uint256 dyFee);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenFrom`|`PooledToken`|the token to sell|
|`tokenTo`|`PooledToken`|the token to buy|
|`dx`|`uint256`|the number of tokens to sell|
|`amplificationParams`|`Amplification`|amplification parameters for the pool|
|`feeParams`|`FeeParams`|fee parameters for the pool|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`dy`|`uint256`|the number of tokens the user will get|
|`dyFee`|`uint256`|the associated fee|


### calculateRemoveLiquidity

A simple method to calculate amount of each underlying
tokens that is returned upon burning given amount of
LP tokens


```solidity
function calculateRemoveLiquidity(uint256 amount, PooledToken[2] calldata tokens, LiquidityPoolToken lpToken)
    external
    view
    returns (uint256[2] memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|the amount of LP tokens that would to be burned on withdrawal|
|`tokens`|`PooledToken[2]`|the tokens of the pool in their cardinality [token0, token1]|
|`lpToken`|`LiquidityPoolToken`|Liquidity pool token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256[2]`|array of amounts of tokens user will receive|


### _calculateRemoveLiquidity

A simple method to calculate amount of each underlying
tokens that is returned upon burning given amount of
LP tokens


```solidity
function _calculateRemoveLiquidity(uint256 amount, PooledToken[2] calldata tokens, uint256 totalSupply)
    internal
    view
    returns (uint256[2] memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|the amount of LP tokens that would to be burned on withdrawal|
|`tokens`|`PooledToken[2]`|the tokens of the pool in their cardinality [token0, token1]|
|`totalSupply`|`uint256`|total supply of the LP token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256[2]`|array of amounts of tokens user will receive|


### getY

Calculate the new balances of the tokens given FROM and TO tokens.
This function is used as a helper function to calculate how much TO token
the user should receive on swap.


```solidity
function getY(uint256 preciseA, uint256 fromXp, uint256 toXp, uint256 x) internal pure returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`preciseA`|`uint256`|precise form of amplification coefficient|
|`fromXp`|`uint256`|FROM precision-adjusted balance in the pool|
|`toXp`|`uint256`|TO precision-adjusted balance in the pool|
|`x`|`uint256`|the new total amount of precision-adjusted FROM token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|the amount of TO token that should remain in the pool|


### getD

Get D, the StableSwap invariant, based on a set of balances and a particular A.


```solidity
function getD(uint256 fromXp, uint256 toXp, uint256 a) internal pure returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`fromXp`|`uint256`|a precision-adjusted balance of the token to sell|
|`toXp`|`uint256`|a precision-adjusted balance of the token to buy|
|`a`|`uint256`|the amplification coefficient * n * (n - 1) in A_PRECISION. See the StableSwap paper for details|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|the invariant, at the precision of the pool|


### _xp

Given a a balance and precision multiplier, return the
precision-adjusted balance.


```solidity
function _xp(uint256 balance, uint256 precisionMultiplier) internal pure returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`balance`|`uint256`|a token balance in its native precision|
|`precisionMultiplier`|`uint256`|a precision multiplier for the token, When multiplied together they should yield amounts at the pool's precision.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|an amount  "scaled" to the pool's precision|


### _feePerToken

internal helper function to calculate fee per token multiplier used in
swap fee calculations


```solidity
function _feePerToken(uint256 swapFee) internal pure returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`swapFee`|`uint256`|swap fee for the tokens|


### getA

Return A, the amplification coefficient * n * (n - 1)

*See the StableSwap paper for details*


```solidity
function getA(Amplification storage self) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`self`|`Amplification`|Swap struct to read from|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|A parameter|


### getAPrecise

Return A in its raw precision

*See the StableSwap paper for details*


```solidity
function getAPrecise(Amplification storage self) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`self`|`Amplification`|Swap struct to read from|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|A parameter in its raw precision form|


### _getAPrecise

Return A in its raw precision

*See the StableSwap paper for details*


```solidity
function _getAPrecise(Amplification storage self) internal view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`self`|`Amplification`|Swap struct to read from|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|A parameter in its raw precision form|


### rampA

Start ramping up or down A parameter towards given futureA_ and futureTime_
Checks if the change is too rapid, and commits the new A value only when it falls under
the limit range.


```solidity
function rampA(Amplification storage self, uint256 futureA_, uint256 futureTime_) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`self`|`Amplification`|Swap struct to update|
|`futureA_`|`uint256`|the new A to ramp towards|
|`futureTime_`|`uint256`|timestamp when the new A should be reached|


### stopRampA

Stops ramping A immediately. Once this function is called, rampA()
cannot be called for another 24 hours


```solidity
function stopRampA(Amplification storage self) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`self`|`Amplification`|Swap struct to update|


### getTokenBalance


```solidity
function getTokenBalance(PooledToken storage _token) external view returns (uint256);
```

### _getTokenBalance


```solidity
function _getTokenBalance(IERC20 _token) internal view returns (uint256);
```

### setAdminFee

Sets the admin fee

*adminFee cannot be higher than 100% of the swap fee*


```solidity
function setAdminFee(FeeParams storage self, uint256 newAdminFee) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`self`|`FeeParams`|Swap struct to update|
|`newAdminFee`|`uint256`|new admin fee to be applied on future transactions|


### setSwapFee

update the swap fee

*fee cannot be higher than 1% of each swap*


```solidity
function setSwapFee(FeeParams storage self, uint256 newSwapFee) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`self`|`FeeParams`|Swap struct to update|
|`newSwapFee`|`uint256`|new swap fee to be applied on future transactions|


## Events
### Swap

```solidity
event Swap(address indexed buyer, IERC20 tokenSold, uint256 amountSold, uint256 amountReceived);
```

### AddLiquidity

```solidity
event AddLiquidity(
    address indexed provider, uint256[2] tokenAmounts, uint256[2] fees, uint256 invariant, uint256 lpTokenSupply
);
```

### RemoveLiquidity

```solidity
event RemoveLiquidity(address indexed provider, uint256[2] tokenAmounts, uint256 lpTokenSupply);
```

### RemoveLiquidityOne

```solidity
event RemoveLiquidityOne(
    address indexed provider, uint256 lpTokenAmount, uint256 lpTokenSupply, IERC20 tokenReceived, uint256 receivedAmount
);
```

### RemoveLiquidityImbalance

```solidity
event RemoveLiquidityImbalance(
    address indexed provider, uint256[2] tokenAmounts, uint256[2] fees, uint256 invariant, uint256 lpTokenSupply
);
```

### NewAdminFee

```solidity
event NewAdminFee(uint256 newAdminFee);
```

### NewSwapFee

```solidity
event NewSwapFee(uint256 newSwapFee);
```

### RampA

```solidity
event RampA(uint256 oldA, uint256 newA, uint256 initialTime, uint256 futureTime);
```

### StopRampA

```solidity
event StopRampA(uint256 currentA, uint256 time);
```

## Structs
### FeeParams

```solidity
struct FeeParams {
    uint256 swapFee;
    uint256 adminFee;
}
```

### PooledToken

```solidity
struct PooledToken {
    IERC20 token;
    uint256 precisionMultiplier;
}
```

### ManageLiquidityInfo

```solidity
struct ManageLiquidityInfo {
    uint256 d0;
    uint256 d1;
    uint256 d2;
    uint256 preciseA;
    LiquidityPoolToken lpToken;
    uint256 totalSupply;
    PooledToken[2] tokens;
    uint256[2] oldBalances;
    uint256[2] newBalances;
}
```

### CalculateWithdrawOneTokenDYInfo

```solidity
struct CalculateWithdrawOneTokenDYInfo {
    uint256 d0;
    uint256 d1;
    uint256 newY;
    uint256 feePerToken;
    uint256 preciseA;
}
```

### Amplification

```solidity
struct Amplification {
    uint256 initialA;
    uint256 futureA;
    uint256 initialATime;
    uint256 futureATime;
}
```


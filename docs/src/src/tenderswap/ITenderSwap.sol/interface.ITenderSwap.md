# ITenderSwap
[Git Source](https://github.com/thunderhead-labs/stflip-contracts/blob/a54a4561fa7129ea9a332ff80d4d3e8aee76ae43/src/tenderswap/ITenderSwap.sol)

*TenderSwap is a light-weight StableSwap implementation for two assets.
See the Curve StableSwap paper for more details (https://curve.fi/files/stableswap-paper.pdf).
that trade 1:1 with eachother (e.g. USD stablecoins or tenderToken derivatives vs their underlying assets).
It supports Elastic Supply ERC20 tokens, which are tokens of which the balances can change
as the total supply of the token 'rebases'.*


## Functions
### initialize

Initializes this Swap contract with the given parameters.
This will also clone a LPToken contract that represents users'
LP positions. The owner of LPToken will be this contract - which means
only this contract is allowed to mint/burn tokens.


```solidity
function initialize(
    IERC20 _token0,
    IERC20 _token1,
    string memory lpTokenName,
    string memory lpTokenSymbol,
    uint256 _a,
    uint256 _fee,
    uint256 _adminFee,
    LiquidityPoolToken lpTokenTargetAddress
) external returns (bool success);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_token0`|`IERC20`|First token in the pool|
|`_token1`|`IERC20`|Second token in the pool|
|`lpTokenName`|`string`|the long-form name of the token to be deployed|
|`lpTokenSymbol`|`string`|the short symbol for the token to be deployed|
|`_a`|`uint256`|the amplification coefficient * n * (n - 1). See the StableSwap paper for details|
|`_fee`|`uint256`|default swap fee to be initialized with|
|`_adminFee`|`uint256`|default adminFee to be initialized with|
|`lpTokenTargetAddress`|`LiquidityPoolToken`|the address of an existing LiquidityPoolToken contract to use as a target|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`success`|`bool`|true is successfully initialized|


### lpToken

VIEW FUNCTIONS **

Returns the liquidity pool token contract.


```solidity
function lpToken() external view returns (LiquidityPoolToken lpTokenContract);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`lpTokenContract`|`LiquidityPoolToken`|Liquidity pool token contract.|


### getA

Return A, the amplification coefficient * n * (n - 1)

*See the StableSwap paper for details*


```solidity
function getA() external view returns (uint256 a);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`a`|`uint256`|the amplifaction coefficient|


### getAPrecise

Return A in its raw precision form

*See the StableSwap paper for details*


```solidity
function getAPrecise() external view returns (uint256 aPrecise);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`aPrecise`|`uint256`|A parameter in its raw precision form|


### getToken0

Returns the contract address for token0

*EVM return type is IERC20*


```solidity
function getToken0() external view returns (IERC20 token0);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`token0`|`IERC20`|contract address|


### getToken1

Returns the contract address for token1

*EVM return type is IERC20*


```solidity
function getToken1() external view returns (IERC20 token1);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`token1`|`IERC20`|contract address|


### getToken0Balance

Return current balance of token0 (tender) in the pool


```solidity
function getToken0Balance() external view returns (uint256 token0Balance);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`token0Balance`|`uint256`|current balance of the pooled tendertoken|


### getToken1Balance

Return current balance of token1 (underlying) in the pool


```solidity
function getToken1Balance() external view returns (uint256 token1Balance);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`token1Balance`|`uint256`|current balance of the pooled underlying token|


### getVirtualPrice

Get the override price, to help calculate profit


```solidity
function getVirtualPrice() external view returns (uint256 virtualPrice);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`virtualPrice`|`uint256`|the override price, scaled to the POOL_PRECISION_DECIMALS|


### calculateSwap

Calculate amount of tokens you receive on swap


```solidity
function calculateSwap(IERC20 _tokenFrom, uint256 _dx) external view returns (uint256 tokensToReceive);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenFrom`|`IERC20`|the token the user wants to sell|
|`_dx`|`uint256`|the amount of tokens the user wants to sell. If the token charges a fee on transfers, use the amount that gets transferred after the fee.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`tokensToReceive`|`uint256`|amount of tokens the user will receive|


### calculateRemoveLiquidity

A simple method to calculate amount of each underlying
tokens that is returned upon burning given amount of LP tokens


```solidity
function calculateRemoveLiquidity(uint256 amount) external view returns (uint256[2] memory tokensToReceive);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|the amount of LP tokens that would be burned on withdrawal|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`tokensToReceive`|`uint256[2]`|array of token balances that the user will receive|


### calculateRemoveLiquidityOneToken

Calculate the amount of underlying token available to withdraw
when withdrawing via only single token


```solidity
function calculateRemoveLiquidityOneToken(uint256 tokenAmount, IERC20 tokenReceive)
    external
    view
    returns (uint256 tokensToReceive);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenAmount`|`uint256`|the amount of LP token to burn|
|`tokenReceive`|`IERC20`|the token to receive|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`tokensToReceive`|`uint256`|calculated amount of underlying token to be received. available to withdraw|


### calculateTokenAmount

A simple method to calculate prices from deposits or
withdrawals, excluding fees but including slippage. This is
helpful as an input into the various "min" parameters on calls
to fight front-running

*This shouldn't be used outside frontends for user estimates.*


```solidity
function calculateTokenAmount(uint256[] calldata amounts, bool deposit)
    external
    view
    returns (uint256 tokensToReceive);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amounts`|`uint256[]`|an array of token amounts to deposit or withdrawal, corresponding to pool cardinality of [token0, token1]. The amount should be in each pooled token's native precision.|
|`deposit`|`bool`|whether this is a deposit or a withdrawal|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`tokensToReceive`|`uint256`|token amount the user will receive|


### swap

POOL FUNCTIONALITY **

Swap two tokens using this pool

*revert is token being sold is not in the pool.*


```solidity
function swap(IERC20 _tokenFrom, uint256 _dx, uint256 _minDy, uint256 _deadline) external returns (uint256 _dy);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenFrom`|`IERC20`|the token the user wants to sell|
|`_dx`|`uint256`|the amount of tokens the user wants to swap from|
|`_minDy`|`uint256`|the min amount the user would like to receive, or revert|
|`_deadline`|`uint256`|latest timestamp to accept this transaction|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`_dy`|`uint256`|amount of tokens received|


### addLiquidity

Add liquidity to the pool with the given amounts of tokens


```solidity
function addLiquidity(uint256[2] calldata _amounts, uint256 _minToMint, uint256 _deadline)
    external
    returns (uint256 lpMinted);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_amounts`|`uint256[2]`|the amounts of each token to add, in their native precision according to the cardinality of the pool [token0, token1]|
|`_minToMint`|`uint256`|the minimum LP tokens adding this amount of liquidity should mint, otherwise revert. Handy for front-running mitigation|
|`_deadline`|`uint256`|latest timestamp to accept this transaction|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`lpMinted`|`uint256`|amount of LP token user minted and received|


### removeLiquidity

Burn LP tokens to remove liquidity from the pool.

*Liquidity can always be removed, even when the pool is paused.*


```solidity
function removeLiquidity(uint256 amount, uint256[2] calldata minAmounts, uint256 deadline)
    external
    returns (uint256[2] memory tokensReceived);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|the amount of LP tokens to burn|
|`minAmounts`|`uint256[2]`|the minimum amounts of each token in the pool acceptable for this burn. Useful as a front-running mitigation according to the cardinality of the pool [token0, token1]|
|`deadline`|`uint256`|latest timestamp to accept this transaction|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`tokensReceived`|`uint256[2]`|is the amounts of tokens user received|


### removeLiquidityOneToken

Remove liquidity from the pool all in one token.


```solidity
function removeLiquidityOneToken(uint256 _tokenAmount, IERC20 _tokenReceive, uint256 _minAmount, uint256 _deadline)
    external
    returns (uint256 tokensReceived);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenAmount`|`uint256`|the amount of the token you want to receive|
|`_tokenReceive`|`IERC20`|the  token you want to receive|
|`_minAmount`|`uint256`|the minimum amount to withdraw, otherwise revert|
|`_deadline`|`uint256`|latest timestamp to accept this transaction|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`tokensReceived`|`uint256`|amount of chosen token user received|


### removeLiquidityImbalance

Remove liquidity from the pool, weighted differently than the
pool's current balances.


```solidity
function removeLiquidityImbalance(uint256[2] calldata _amounts, uint256 _maxBurnAmount, uint256 _deadline)
    external
    returns (uint256 lpBurned);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_amounts`|`uint256[2]`|how much of each token to withdraw|
|`_maxBurnAmount`|`uint256`|the max LP token provider is willing to pay to remove liquidity. Useful as a front-running mitigation.|
|`_deadline`|`uint256`|latest timestamp to accept this transaction|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`lpBurned`|`uint256`|amount of LP tokens burned|


### setAdminFee

ADMIN FUNCTIONALITY **

Update the admin fee. Admin fee takes portion of the swap fee.


```solidity
function setAdminFee(uint256 newAdminFee) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newAdminFee`|`uint256`|new admin fee to be applied on future transactions|


### setSwapFee

Update the swap fee to be applied on swaps


```solidity
function setSwapFee(uint256 newSwapFee) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newSwapFee`|`uint256`|new swap fee to be applied on future transactions|


### rampA

Start ramping up or down A parameter towards given futureA and futureTime
Checks if the change is too rapid, and commits the new A value only when it falls under
the limit range.


```solidity
function rampA(uint256 futureA, uint256 futureTime) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`futureA`|`uint256`|the new A to ramp towards|
|`futureTime`|`uint256`|timestamp when the new A should be reached|


### stopRampA

Stop ramping A immediately. Reverts if ramp A is already stopped.


```solidity
function stopRampA() external;
```

### transferOwnership

Changes the owner of the contract


```solidity
function transferOwnership(address _newOwner) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_newOwner`|`address`|address of the new owner|


## Events
### Swap
EVENTS **

Swap gets emitted when an accounts exchanges tokens.


```solidity
event Swap(address indexed buyer, IERC20 tokenSold, uint256 amountSold, uint256 amountReceived);
```

### AddLiquidity
AddLiquidity gets emitted when liquidity is added to the pool.


```solidity
event AddLiquidity(
    address indexed provider, uint256[2] tokenAmounts, uint256[2] fees, uint256 invariant, uint256 lpTokenSupply
);
```

### RemoveLiquidity
RemoveLiquidity gets emitted when liquidity for both tokens
is removed from the pool.


```solidity
event RemoveLiquidity(address indexed provider, uint256[2] tokenAmounts, uint256 lpTokenSupply);
```

### RemoveLiquidityOne
RemoveLiquidityOne gets emitted when single-sided liquidity is removed


```solidity
event RemoveLiquidityOne(
    address indexed provider, uint256 lpTokenAmount, uint256 lpTokenSupply, IERC20 tokenReceived, uint256 receivedAmount
);
```

### RemoveLiquidityImbalance
RemoveLiquidityImbalance gets emitted when liquidity is removed weighted differently than the
pool's current balances.
with different weights than that of the pool.


```solidity
event RemoveLiquidityImbalance(
    address indexed provider, uint256[2] tokenAmounts, uint256[2] fees, uint256 invariant, uint256 lpTokenSupply
);
```

### NewAdminFee
NewAdminFee gets emitted when the admin fee is updated.


```solidity
event NewAdminFee(uint256 newAdminFee);
```

### NewSwapFee
NewSwapFee gets emitted when the swap fee is updated.


```solidity
event NewSwapFee(uint256 newSwapFee);
```

### RampA
RampA gets emitted when A has started ramping up.


```solidity
event RampA(uint256 oldA, uint256 newA, uint256 initialTime, uint256 futureTime);
```

### StopRampA
StopRampA gets emitted when ramping A is stopped manually


```solidity
event StopRampA(uint256 currentA, uint256 time);
```


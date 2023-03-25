 

# Aggregator

The `Aggregator` contract is used to handle the stake and unstake aggregation functions along with the associated calculations.

### Contract

`stakeAggregate` (swap and mint automatically) and the `unstakeAggregate` (instant burn, instant claim, )(inside the `Minter.sol` file) is used to calculate the maximum amount purchasable for a favorable price and to purchase/mint atomically.

**`constructor`**

```solidity
constructor(address minter_, 
			address liquidityPool_, 
			address stflip_, 
			address flip_
			)
```

Associates the relevant contracts and sets infinite approvals to the minter and curve pool

**Parameters:**

| Name             | Type      | Description                              |
| ---------------- | --------- | :--------------------------------------- |
| `minter_`        | `address` | Address of the minter contract           |
| `liquidityPool_` | `address` | Address of the TenderSwap liquidity pool |
| `stflip_`        | `address` | Address of the stFLIP token              |
| `flip_`          | `address` | Address of the FLIP token                |

**`stakeAggregate`**

Spends FLIP to mint and swap for stFLIP in the same transaction. 

```solidity
function stakeAggregate(uint256 amountTotal, 
						uint256 amountSwap, 
						uint256 minimumAmountSwapOut, 
						uint256 _deadline
						) external returns (uint256)
```

**Parameters:**

| Name                   | Type      | Description                                                  |
| ---------------------- | --------- | :----------------------------------------------------------- |
| `amountTotal`          | `uint256` | Total amount of FLIP user would like to spend for stFLIP     |
| `amountSwap`           | `uint256` | The amount of FLIP user would like to spend swapping for stFLIP |
| `minimumAmountSwapOut` | `uint256` | Minimum amount out after slippage from the swap leg          |
| `_deadline`            | `uint256` | The time after which the swap should expire.                 |

**Flow**:

1) Transfers `amountTotal` of `FLIP` from `msg.sender` to the contract
2) If `amountSwap` is greater than zero it will perform a swap for `amountSwap` amount of `FLIP`. The swap will revert if it does not receive at minimum `minimumAmountSwapOut` `stFLIP`
3) If `amountTotal - amountSwap` is greater than zero, the contract will use the rest of the `FLIP` to mint `stFLIP`
4) The contract transfers all of the `stFLIP` back to the user
5) Emits `event Aggregation (uint256 total, uint256 swapped, uint256 minted);`
6) Returns `total`

**Notes:**

- Contract will only swap if `_dx > 0`
- Contract will only mint if there is excess tokens after the swap (i.e `_dx < amount`)

Here is the documentation for the `unstakeAggregate` function in the provided format.

**`unstakeAggregate`**

Spends stFLIP to burn, instantly burn, and swap for FLIP in the same transaction.

```solidity
function unstakeAggregate(uint256 amountInstantBurn, 
                          uint256 amountBurn, 
                          uint256 amountSwap, 
                          uint256 minimumAmountSwapOut, 
                          uint256 deadline
                          ) external returns (uint256)
```

**Parameters:**

| Name                   | Type      | Description                                                  |
| ---------------------- | --------- | :----------------------------------------------------------- |
| `amountInstantBurn`    | `uint256` | Amount of stFLIP user wants to instantly burn                |
| `amountBurn`           | `uint256` | Amount of stFLIP user wants to burn normally                 |
| `amountSwap`           | `uint256` | Amount of stFLIP user wants to swap for FLIP                 |
| `minimumAmountSwapOut` | `uint256` | Minimum amount of FLIP to receive after slippage from the swap leg |
| `deadline`             | `uint256` | The time after which the swap should expire.                 |

**Flow:**

1. Transfers `total` amount of `stFLIP` from `msg.sender` to the contract, where `total = amountInstantBurn + amountBurn + amountSwap`
2. If `amountInstantBurn` is greater than zero, the contract burns the specified amount and immediately redeems the burn to `msg.sender`
3. If `amountBurn` is greater than zero, the contract burns the specified amount for `msg.sender`
4. If `amountSwap` is greater than zero, the contract swaps the specified amount of `stFLIP` for `FLIP`. The swap will revert if it does not receive at least `minimumAmountSwapOut` `FLIP`
5. If the swap in step 4 is successful, the contract transfers the received `FLIP` back to the user
6. Emits `event BurnAggregation (uint256 amountInstantBurn, uint256 amountBurn, uint256 received);`
7. Returns the total amount of `FLIP` received by the user (`amountInstantBurn + received`)

**Notes:**

- Contract will only perform instant burn if `amountInstantBurn > 0`
- Contract will only perform normal burn if `amountBurn > 0`
- Contract will only perform swap if `amountSwap > 0`

**`marginalCost`**

Calculates the marginal cost for the last unit of a swap of amount `amount`. This essentially calculates the virtual price of the pool after a hypothetical swap of size `amount` is performed.

```solidity
function marginalCost(uint256 amount) external view returns (uint256)
```

**Parameters:**

| Name     | Type      | Description                                                 |
| -------- | --------- | :---------------------------------------------------------- |
| `amount` | `uint256` | the amount for which the marginal cost should be calculated |

**Flow:**

1. Calculates the price of the pool (stFLIP/FLIP) after swapping the given `amount` of FLIP using the `_marginalCost` internal function.
2. Returns the marginal cost for the last unit of swap, which is essentially the price of the pool after the given input.

**Notes:**

- The function calculates the price of the pool (stFLIP/FLIP) after swapping a specific amount of FLIP.
- The returned value represents the marginal cost for the last unit of swap.

**`calculatePurchasable`**

Determines the maximum amount of FLIP to spend to purchase stFLIP for less than the `targetPrice`

```solidity
function calculatePurchasable(uint256 targetPrice, 
                              uint256 targetError, 
                              uint256 attempts
                              ) external view returns (uint256)
```

**Parameters:**

| Name          | Type      | Description                                                  |
| ------------- | --------- | :----------------------------------------------------------- |
| `targetPrice` | `uint256` | The price that the function will calculate the amount to purchase up until. This number should be `greater than 1`. (1 should be inputted as 10**18) |
| `targetError` | `uint256` | The acceptable error between the calculated marginal price and the target price (as a percentage, `10**18 = 1`) |
| `attempts`    | `uint256` | The maximum number of binary search attempts before giving up and reverting |

**Flow:**

1. The function checks if the `startPrice` (current price of the pool) is less than the `targetPrice`. If so, it returns 0 since no amount of stFLIP can be purchased for a favorable price.
2. Performs a binary search on `amountIn` to find where the `marginalCost(amountIn)` is within the `targetError` of `targetPrice` with maximum of `attempts` iterations. 
3. Returns the amount of FLIP that can be spent to achieve the target price within the acceptable error range.

**Notes:**

- The function uses binary search to find the amount of FLIP to spend. Thus, this is not a perfect calculation and the `targetError` determines the acceptable error range around `targetPrice`
- The function returns 0 if no stFLIP can be purchased for a favorable price.
- The function reverts if it cannot find an acceptable amount within the given number of attempts.

### Tests

**`testFuzz_Calculate`**

Ensures that `calculatePurchasable` succeeds for any LP amount

```solidity
function testFuzz_Calculate(uint256 lpAmount1_, 
							uint256 lpAmount2_, 
							uint256 targetPrice_, 
							uint256 targetError_) public 
```

**Parameters:**

| Name           | Type      | Description                                      |
| -------------- | --------- | :----------------------------------------------- |
| `lpAmount1_`   | `uint256` | Placeholder for the first liquidity pool amount  |
| `lpAmount2_`   | `uint256` | Placeholder for the second liquidity pool amount |
| `targetPrice_` | `uint256` | Placeholder for the target price                 |
| `targetError_` | `uint256` | Placeholder for the target error                 |

**Flow:**

1. Calculates the bound values for `lpAmount1`, `lpAmount2`, `targetPrice`, and `targetError` using the provided placeholders
2. Adds `[lpAmount1, lpAmount2]` in liquidity to `tenderSwap`
3. Calls `aggregator.calculatePurchasable(targetPrice, targetError, 1000)`

**`testFuzz_Aggregate`**

Ensures that `stakeAggregate` works for any permutation of the pool.

```
function testFuzz_Aggregate(uint256 amount_, 
							uint256 lpAmount1_, 
							uint256 lpAmount2_) public 
```

**Parameters:**

| Name         | Type      | Description                                      |
| ------------ | --------- | :----------------------------------------------- |
| `amount_`    | `uint256` | Placeholder for the amount to stake              |
| `lpAmount1_` | `uint256` | Placeholder for the first liquidity pool amount  |
| `lpAmount2_` | `uint256` | Placeholder for the second liquidity pool amount |

**Flow:**

1. Calculates the bound values for `amount`, `lpAmount1`, and `lpAmount2` using the provided placeholders
2. Starts the virtual machine (`vm`) prank and adds liquidity to the `tenderSwap`
3. Calculates the amount of purchasable tokens, `_dx`, and `_minDy`
4. Calls `aggregator.stakeAggregate(amount, _dx, _minDy, block.timestamp + 100)`

**`testFuzz_UnstakeAggregate`**

Ensures that `unstakeAggregate` works for any permutation of LP pool and amount claimable. 

```solidity
function testFuzz_UnstakeAggregate(	bool instantUnstake, 
									uint256 lpAmount1_, 
									uint256 lpAmount2_, 
									uint256 amountClaimable_, 
									uint256 amountUnstake_) public
```

**Parameters:**

| Name               | Type      | Description                                                  |
| ------------------ | --------- | ------------------------------------------------------------ |
| `instantUnstake`   | `bool`    | If true, will swap remaining stFLIP after instant burn rather than normal burn |
| `lpAmount1_`       | `uint256` | Initial stFLIP balance for liquidity provision               |
| `lpAmount2_`       | `uint256` | Initial FLIP balance for liquidity provision                 |
| `amountClaimable_` | `uint256` | Amount of FLIP instantly claimable in `Burner`               |
| `amountUnstake_`   | `uint256` | Amount of stFLIP user wants to unstake                       |

**Flow:**

1. Determines bounds for the input parameters.
2. Starts a prank, impersonating the `owner`.
3. Adds liquidity to the `tenderSwap` using `lpAmount1` and `lpAmount2`.
4. Deposits `amountClaimable` into the `burner`.
5. Calculates `amountInstantBurn`, `amountBurn`, `amountSwap`, and `amountSwapOut` based on the input parameters and conditions.
6. Calls `aggregator.unstakeAggregate` with the calculated values and `block.timestamp`.

### Scripts

**`run()`**

Deploys a new aggregator with the `Minter, Burner, TenderSwap, stFLIP, FLIP` addresses that are in the `.env`

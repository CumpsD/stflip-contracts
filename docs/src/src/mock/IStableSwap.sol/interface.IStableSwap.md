# IStableSwap
[Git Source](https://github.com/thunderhead-labs/stflip-contracts/blob/7cc8544d9ea72822b709c48cbb1ce3c466520cc8/src/mock/IStableSwap.sol)


## Functions
### get_virtual_price


```solidity
function get_virtual_price() external view returns (uint256);
```

### add_liquidity


```solidity
function add_liquidity(uint256[4] calldata amounts, uint256 min_mint_amount) external;
```

### remove_liquidity


```solidity
function remove_liquidity(uint256 amount, uint256[4] calldata min_amounts) external;
```

### exchange


```solidity
function exchange(int128 from, int128 to, uint256 amount, uint256 min_amount) external payable returns (uint256);
```

### calc_token_amount


```solidity
function calc_token_amount(uint256[4] calldata amounts, bool deposit) external view returns (uint256);
```

### get_dy


```solidity
function get_dy(int128 i, int128 j, uint256 _dx) external view returns (uint256);
```

### balances


```solidity
function balances(uint256 i) external view returns (uint256);
```


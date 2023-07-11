# Sweeper
[Git Source](https://github.com/thunderhead-labs/stflip-contracts/blob/7cc8544d9ea72822b709c48cbb1ce3c466520cc8/src/utils/Sweeper.sol)


## State Variables
### flip

```solidity
IERC20 public flip;
```


### burner

```solidity
BurnerV1 public burner;
```


### staker

```solidity
Staker public staker;
```


## Functions
### constructor


```solidity
constructor(address flip_, address burner_, address staker_);
```

### disperseToken


```solidity
function disperseToken(bytes32 nodeID, address[] calldata recipients, uint256[] calldata values, uint256 deposit)
    external;
```


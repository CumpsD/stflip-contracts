# StateChainGateway
[Git Source](https://github.com/thunderhead-labs/stflip-contracts/blob/7cc8544d9ea72822b709c48cbb1ce3c466520cc8/src/mock/StateChainGateway.sol)


## State Variables
### flip

```solidity
IERC20 public flip;
```


## Functions
### constructor


```solidity
constructor(address flip_);
```

### fundStateChainAccount


```solidity
function fundStateChainAccount(bytes32 nodeID, uint256 amount) external;
```

### executeRedemption


```solidity
function executeRedemption(bytes32 nodeID) external;
```


# StateChainGateway
[Git Source](https://github.com/thunderhead-labs/stflip-contracts/blob/a54a4561fa7129ea9a332ff80d4d3e8aee76ae43/src/mock/StateChainGateway.sol)


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


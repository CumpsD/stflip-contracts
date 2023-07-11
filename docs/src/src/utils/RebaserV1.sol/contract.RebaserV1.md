# RebaserV1
[Git Source](https://github.com/thunderhead-labs/stflip-contracts/blob/a54a4561fa7129ea9a332ff80d4d3e8aee76ae43/src/utils/RebaserV1.sol)

**Inherits:**
Initializable


## State Variables
### gov

```solidity
address public gov;
```


### pendingGov

```solidity
address public pendingGov;
```


### feeRecipient

```solidity
address public feeRecipient;
```


### manager

```solidity
address public manager;
```


### feeBps

```solidity
uint256 public feeBps;
```


### aprThresholdBps

```solidity
uint256 public aprThresholdBps;
```


### lastRebaseTime

```solidity
uint256 public lastRebaseTime;
```


### slashThresholdBps

```solidity
uint256 public slashThresholdBps;
```


### TIME_IN_YEAR

```solidity
uint256 constant TIME_IN_YEAR = 31536000;
```


### rebaseInterval

```solidity
uint256 public rebaseInterval;
```


### pendingFee

```solidity
uint256 public pendingFee;
```


### wrappedBurnerProxy

```solidity
BurnerV1 public wrappedBurnerProxy;
```


### wrappedOutputProxy

```solidity
OutputV1 public wrappedOutputProxy;
```


### wrappedMinterProxy

```solidity
MinterV1 public wrappedMinterProxy;
```


### flip

```solidity
IERC20 public flip;
```


### stflip

```solidity
stFlip public stflip;
```


## Functions
### constructor


```solidity
constructor();
```

### initialize


```solidity
function initialize(
    address[8] calldata addresses,
    uint256 feeBps_,
    uint256 aprThresholdBps_,
    uint256 slashThresholdBps_,
    uint256 rebaseInterval_
) public initializer;
```

### onlyGov


```solidity
modifier onlyGov();
```

### _setPendingGov

sets the pendingGov


```solidity
function _setPendingGov(address pendingGov_) external onlyGov;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pendingGov_`|`address`|The address of the rebaser contract to use for authentication.|


### _acceptGov

lets msg.sender accept governance


```solidity
function _acceptGov() external;
```

### onlyManager


```solidity
modifier onlyManager();
```

### setManager

Sets manager address, the EOA that can rebase


```solidity
function setManager(address manager_) external onlyGov;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`manager_`|`address`|The address to set the manager role to|


### setFeeRecipient

Sets fee recipient, the address that will receive fee claims


```solidity
function setFeeRecipient(address feeRecipient_) external onlyGov;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`feeRecipient_`|`address`|The address to set the fee recipient to|


### setFeeBps

Sets reward fee in bps, the percentage of rebase that will go to `pendingFee`


```solidity
function setFeeBps(uint256 feeBps_) external onlyGov;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`feeBps_`|`uint256`|The amount of bps to set the fee to|


### setAprThresholdBps

Sets the APR threshold in bps

*If the rebase exceeds this APR, then the rebase will revert*


```solidity
function setAprThresholdBps(uint256 aprThresholdBps_) external onlyGov;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`aprThresholdBps_`|`uint256`|The amount of bps to set apr threshold to|


### setSlashThresholdBps

Sets slash threshold in bps

*If the supply decreases by this threshold, then the rebase will revert*

*This is different from APR threshold because slashes would be much more serious*


```solidity
function setSlashThresholdBps(uint256 slashThresholdBps_) external onlyGov;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`slashThresholdBps_`|`uint256`|The number of bps to set slash threshold to|


### setRebaseInterval

Sets minimum rebase interval

*If a rebase occurs before this interval elapses, it will revert*


```solidity
function setRebaseInterval(uint256 rebaseInterval_) external onlyGov;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`rebaseInterval_`|`uint256`|The minimum unix time between rebases|


### rebase

Calculates the new rebase factor based on the stateChainBalance and whether
or not fee will be claimed

*Ideally we could have an oracle report the `stateChainBalance` to the contract
but Chainlink and larger oracle networks do not support Chainflip yet. Its also
very expensive and still very centralized. So we instead rely on the manager which is
an EOA to perform oracle reports. Manager will call this function with the `stateChainBalance`
and the following function will calculate what the new rebase factor will be including the onchain
balances in the output addess. If the supply change exceeds the APR or slash threshold, then the
rebase will revert, limiting the possible damage the EOA could commmit. We might disable `takeFee`
if there is a slash we need to make up for. Its also worth noting how `pendingFee` is a piece of the pool,
in the same way that pending burns are.*


```solidity
function rebase(uint256 epoch, uint256 stateChainBalance, bool takeFee) external onlyManager;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`epoch`|`uint256`|The epoch number of the rebase|
|`stateChainBalance`|`uint256`|The balance of the state chain validators|
|`takeFee`|`bool`|Whether or not to claim fee|


### forceRebase

just for testnet purposes. will be deprecated before mainnet


```solidity
function forceRebase(uint256 epoch, uint256 stateChainBalance, bool takeFee) external onlyGov;
```

### claimFee

Claims pending fees to the fee recipient in either stflip or flip

*`pendingFee` is a piece of the pool. When fee is claimed in FLIP, the
pool's decrease in FLIP aligns with the decrease in `pendingFee`. Similarly,
when stFLIP is claimed, the increase in stFLIP supply corresponds to the decrease
in `pendingFee`. When `max` is true, the entire `pendingFee` is claimed and the
`amount` does not matter.*


```solidity
function claimFee(uint256 amount, bool max, bool receiveFlip) external onlyManager;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|Amount of tokens to burn|
|`max`|`bool`|Whether or not to claim all pending fees|
|`receiveFlip`|`bool`|Whether or not to receive the fee in flip or stflip|


## Events
### FeeClaim

```solidity
event FeeClaim(address feeRecipient, uint256 amount, bool receivedFlip);
```

### RebaserRebase

```solidity
event RebaserRebase(uint256 apr, uint256 feeIncrement, uint256 previousSupply, uint256 newSupply);
```

### GovRebase

```solidity
event GovRebase(uint256 apr, uint256 feeIncrement, uint256 previousSupply, uint256 newSupply);
```

### NewPendingGov
Event emitted when pendingGov is changed


```solidity
event NewPendingGov(address oldPendingGov, address newPendingGov);
```

### NewGov
Event emitted when gov is changed


```solidity
event NewGov(address oldGov, address newGov);
```

### Burn
Tokens burned event


```solidity
event Burn(uint256 amount, uint256 burn_id);
```


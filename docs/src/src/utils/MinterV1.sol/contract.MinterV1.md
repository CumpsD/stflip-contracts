# MinterV1
[Git Source](https://github.com/thunderhead-labs/stflip-contracts/blob/7cc8544d9ea72822b709c48cbb1ce3c466520cc8/src/utils/MinterV1.sol)

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


### output

```solidity
address public output;
```


### rebaser

```solidity
address public rebaser;
```


### stflip

```solidity
stFlip public stflip;
```


### flip

```solidity
IERC20 public flip;
```


## Functions
### constructor


```solidity
constructor();
```

### initialize


```solidity
function initialize(address stflip_, address output_, address gov_, address flip_, address rebaser_)
    public
    initializer;
```

### onlyGov


```solidity
modifier onlyGov();
```

### _setPendingGov


```solidity
function _setPendingGov(address pendingGov_) external onlyGov;
```

### _acceptGov


```solidity
function _acceptGov() external;
```

### mint

Public mint function. Takes FLIP from users and returns stFLIP 1:1


```solidity
function mint(address to, uint256 amount) external returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`to`|`address`|The address to mint stFLIP to|
|`amount`|`uint256`|The amount of stFLIP to mint|


### mintStflipFee

Called by the rebaser to mint stflip fee


```solidity
function mintStflipFee(address to, uint256 amount) external returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`to`|`address`|Address to mint stflip to|
|`amount`|`uint256`|Amount of stflip to mint|


### _mint

Calls mint on stFLIP contract and emits event


```solidity
function _mint(address to, uint256 amount) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`to`|`address`|Address to mint stflip to|
|`amount`|`uint256`|Amount of stflip to mint|


## Events
### NewPendingGov

```solidity
event NewPendingGov(address oldPendingGov, address newPendingGov);
```

### NewGov

```solidity
event NewGov(address oldGov, address newGov);
```

### Mint

```solidity
event Mint(address to, uint256 amount);
```


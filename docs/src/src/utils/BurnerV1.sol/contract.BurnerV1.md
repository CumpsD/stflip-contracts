# BurnerV1
[Git Source](https://github.com/thunderhead-labs/stflip-contracts/blob/a54a4561fa7129ea9a332ff80d4d3e8aee76ae43/src/utils/BurnerV1.sol)

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


### balance

```solidity
uint256 public balance = 0;
```


### redeemed

```solidity
uint256 public redeemed = 0;
```


### burns

```solidity
burn_[] public burns;
```


### sums

```solidity
uint256[] public sums;
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
function initialize(address stflip_, address gov_, address flip_, address output_) public initializer;
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

### burn

Burns stflip tokens, transfers FLIP tokens from msg.sender, adds entry to burns/sums list


```solidity
function burn(address to, uint256 amount) external returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`to`|`address`||
|`amount`|`uint256`||


### redeem

redeems a burn, claiming native FLIP back to "to" field of burn entry


```solidity
function redeem(uint256 burnId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`burnId`|`uint256`||


### emergencyWithdraw


```solidity
function emergencyWithdraw(uint256 amount, address token) external onlyGov;
```

### totalPendingBurns

the sum of all unredeemed burns in the contract


```solidity
function totalPendingBurns() external view returns (uint256);
```

### _getBurnIds

all the burn ids associated with an address


```solidity
function _getBurnIds(address account) internal view returns (uint256[] memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|The address of the user to check|


### getBurnIds

public function to get all the burn ids associated with an address


```solidity
function getBurnIds(address account) external view returns (uint256[] memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|The address of the user to check|


### getBurns

get all the burns of an account, the the full structs, ids, and if they can be redeemed.


```solidity
function getBurns(address account) external view returns (burn_[] memory, uint256[] memory, bool[] memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|The address of the user to pull burns for|


### _redeemable

is a burn redeemable

*Firstly, burn can obviously not be redeemable if it has already been redeemed.
Secondly, we ensure that there is enough FLIP to satisfy all prior burns in the burn queue,
and the burn of `burnId` itself. `Sums[burnId]` is the sum of all burns up to and including `burnId`.
redeemed is the sum of all burns that have been redeemed. If the difference between the two is <= than the
balance of FLIP in the contract, then the burn is redeemable.*


```solidity
function _redeemable(uint256 burnId) internal view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`burnId`|`uint256`|The id of the burn to check|


### redeemable

Public getter for redeemable


```solidity
function redeemable(uint256 burnId) external view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`burnId`|`uint256`|The id of the burn to check|


### getAllBurns

Public getter for the burns struct list


```solidity
function getAllBurns() external view returns (burn_[] memory);
```

### subtract


```solidity
function subtract(uint256 a, uint256 b) public pure returns (uint256);
```

## Events
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
event Burn(uint256 amount, uint256 burnId);
```

## Structs
### burn_

```solidity
struct burn_ {
    address user;
    uint256 amount;
    bool completed;
}
```


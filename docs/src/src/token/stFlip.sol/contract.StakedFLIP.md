# StakedFLIP
[Git Source](https://github.com/thunderhead-labs/stflip-contracts/blob/7cc8544d9ea72822b709c48cbb1ce3c466520cc8/src/token/stFlip.sol)

**Inherits:**
[TokenStorage](/src/token/tStorage.sol/contract.TokenStorage.md)


## Functions
### constructor


```solidity
constructor();
```

### onlyGov


```solidity
modifier onlyGov();
```

### onlyRebaser


```solidity
modifier onlyRebaser();
```

### onlyMinter


```solidity
modifier onlyMinter();
```

### onlyBurner


```solidity
modifier onlyBurner();
```

### notFrozen


```solidity
modifier notFrozen();
```

### validRecipient


```solidity
modifier validRecipient(address to);
```

### initialize

Initializes the contract name, symbol, and decimals

*Limited to onlyGov modifier*


```solidity
function initialize(string memory name_, string memory symbol_, uint8 decimals_) public onlyGov;
```

### maxScalingFactor

Computes the current max scaling factor


```solidity
function maxScalingFactor() external view returns (uint256);
```

### _maxScalingFactor


```solidity
function _maxScalingFactor() internal view returns (uint256);
```

### freeze

Freezes any user transfers of the contract

*Limited to onlyGov modifier*


```solidity
function freeze(bool status) external onlyGov returns (bool);
```

### mint

Mints new tokens, increasing totalSupply, initSupply, and a users balance.

*Limited to onlyMinter modifier*


```solidity
function mint(address to, uint256 amount) external onlyMinter returns (bool);
```

### _mint


```solidity
function _mint(address to, uint256 amount) internal;
```

### transfer

*Transfer tokens to a specified address.*


```solidity
function transfer(address to, uint256 value) external validRecipient(to) notFrozen returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`to`|`address`|The address to transfer to.|
|`value`|`uint256`|The amount to be transferred.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|True on success, false otherwise.|


### burn


```solidity
function burn(uint256 value, address refundee) external notFrozen onlyBurner returns (bool);
```

### _burn


```solidity
function _burn(uint256 value, address refundee) internal;
```

### transferFrom

*Transfer tokens from one address to another.*


```solidity
function transferFrom(address from, address to, uint256 value) external validRecipient(to) notFrozen returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from`|`address`|The address you want to send tokens from.|
|`to`|`address`|The address you want to transfer to.|
|`value`|`uint256`|The amount of tokens to be transferred.|


### govTransferFrom

*Transfer tokens from one address to another.*


```solidity
function govTransferFrom(address from, address to, uint256 value) external validRecipient(to) onlyGov returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from`|`address`|The address you want to send tokens from.|
|`to`|`address`|The address you want to transfer to.|
|`value`|`uint256`|The amount of tokens to be transferred.|


### balanceOf


```solidity
function balanceOf(address who) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`who`|`address`|The address to query.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The balance of the specified address.|


### balanceOfUnderlying

Currently returns the internal storage amount


```solidity
function balanceOfUnderlying(address who) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`who`|`address`|The address to query.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The underlying balance of the specified address.|


### allowance

*Function to check the amount of tokens that an owner has allowed to a spender.*


```solidity
function allowance(address owner_, address spender) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`owner_`|`address`|The address which owns the funds.|
|`spender`|`address`|The address which will spend the funds.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The number of tokens still available for the spender.|


### approve

*Approve the passed address to spend the specified amount of tokens on behalf of
msg.sender. This method is included for ERC20 compatibility.
increaseAllowance and decreaseAllowance should be used instead.
Changing an allowance with this method brings the risk that someone may transfer both
the old and the new allowance - if they are both greater than zero - if a transfer
transaction is mined before the later approve() call is mined.*


```solidity
function approve(address spender, uint256 value) external returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`spender`|`address`|The address which will spend the funds.|
|`value`|`uint256`|The amount of tokens to be spent.|


### increaseAllowance

*Increase the amount of tokens that an owner has allowed to a spender.
This method should be used instead of approve() to avoid the double approval vulnerability
described above.*


```solidity
function increaseAllowance(address spender, uint256 addedValue) external notFrozen returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`spender`|`address`|The address which will spend the funds.|
|`addedValue`|`uint256`|The amount of tokens to increase the allowance by.|


### decreaseAllowance

*Decrease the amount of tokens that an owner has allowed to a spender.*


```solidity
function decreaseAllowance(address spender, uint256 subtractedValue) external notFrozen returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`spender`|`address`|The address which will spend the funds.|
|`subtractedValue`|`uint256`|The amount of tokens to decrease the allowance by.|


### permit


```solidity
function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
    external
    notFrozen;
```

### _setRebaser

sets the rebaser


```solidity
function _setRebaser(address rebaser_) external onlyGov;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`rebaser_`|`address`|The address of the rebaser contract to use for authentication.|


### _setMinter

sets the minter


```solidity
function _setMinter(address minter_) external onlyGov;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`minter_`|`address`|The address of the minter contract to use for authentication.|


### _setBurner

sets the burner


```solidity
function _setBurner(address burner_) external onlyGov;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`burner_`|`address`|The address of the burner contract to use for authentication.|


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

### rebase

Initiates a new rebase operation, provided the minimum time period has elapsed.

*The supply adjustment equals (totalSupply * DeviationFromTargetRate) / rebaseLag
Where DeviationFromTargetRate is (MarketOracleRate - targetRate) / targetRate
and targetRate is CpiOracleRate / baseCpi*


```solidity
function rebase(uint256 epoch, uint256 indexDelta, bool positive) external onlyRebaser returns (uint256);
```

### setRebase


```solidity
function setRebase(uint256 epoch, uint256 value) external onlyRebaser returns (uint256);
```

### yamToFragment


```solidity
function yamToFragment(uint256 yam) external view returns (uint256);
```

### fragmentToYam


```solidity
function fragmentToYam(uint256 value) external view returns (uint256);
```

### _yamToFragment


```solidity
function _yamToFragment(uint256 yam) internal view returns (uint256);
```

### _fragmentToYam


```solidity
function _fragmentToYam(uint256 value) internal view returns (uint256);
```

### rescueTokens


```solidity
function rescueTokens(address token, address to, uint256 amount) external onlyGov returns (bool);
```

## Events
### Rebase
Event emitted when tokens are rebased


```solidity
event Rebase(uint256 epoch, uint256 prevYamsScalingFactor, uint256 newYamsScalingFactor);
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

### NewRebaser
Sets the rebaser contract


```solidity
event NewRebaser(address oldRebaser, address newRebaser);
```

### NewMinter
Sets the minter contract


```solidity
event NewMinter(address oldMinter, address newMinter);
```

### NewBurner
sets the burner contract


```solidity
event NewBurner(address oldBurner, address newBurner);
```

### Transfer
EIP20 Transfer event


```solidity
event Transfer(address indexed from, address indexed to, uint256 amount);
```

### Approval
EIP20 Approval event


```solidity
event Approval(address indexed owner, address indexed spender, uint256 amount);
```

### Mint
Tokens minted event


```solidity
event Mint(address to, uint256 amount);
```

### Burn
Tokens burned event


```solidity
event Burn(address from, uint256 amount, address refundee);
```


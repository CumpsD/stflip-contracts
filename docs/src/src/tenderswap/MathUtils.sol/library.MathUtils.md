# MathUtils
[Git Source](https://github.com/thunderhead-labs/stflip-contracts/blob/7cc8544d9ea72822b709c48cbb1ce3c466520cc8/src/tenderswap/MathUtils.sol)


## State Variables
### PERC_DIVISOR

```solidity
uint256 public constant PERC_DIVISOR = 10 ** 21;
```


## Functions
### validPerc

*Returns whether an amount is a valid percentage out of PERC_DIVISOR*


```solidity
function validPerc(uint256 _amount) internal pure returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_amount`|`uint256`|Amount that is supposed to be a percentage|


### percOf

*Compute percentage of a value with the percentage represented by a fraction*


```solidity
function percOf(uint256 _amount, uint256 _fracNum, uint256 _fracDenom) internal pure returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_amount`|`uint256`|Amount to take the percentage of|
|`_fracNum`|`uint256`|Numerator of fraction representing the percentage|
|`_fracDenom`|`uint256`|Denominator of fraction representing the percentage|


### percOf

*Compute percentage of a value with the percentage represented by a fraction over PERC_DIVISOR*


```solidity
function percOf(uint256 _amount, uint256 _fracNum) internal pure returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_amount`|`uint256`|Amount to take the percentage of|
|`_fracNum`|`uint256`|Numerator of fraction representing the percentage with PERC_DIVISOR as the denominator|


### percPoints

*Compute percentage representation of a fraction*


```solidity
function percPoints(uint256 _fracNum, uint256 _fracDenom) internal pure returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_fracNum`|`uint256`|Numerator of fraction represeting the percentage|
|`_fracDenom`|`uint256`|Denominator of fraction represeting the percentage|


### within1

Compares a and b and returns true if the difference between a and b
is less than 1 or equal to each other.


```solidity
function within1(uint256 a, uint256 b) internal pure returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`a`|`uint256`|uint256 to compare with|
|`b`|`uint256`|uint256 to compare with|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|True if the difference between a and b is less than 1 or equal, otherwise return false|


### difference

Calculates absolute difference between a and b


```solidity
function difference(uint256 a, uint256 b) internal pure returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`a`|`uint256`|uint256 to compare with|
|`b`|`uint256`|uint256 to compare with|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Difference between a and b|



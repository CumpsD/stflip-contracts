# Multicall
[Git Source](https://github.com/thunderhead-labs/stflip-contracts/blob/a54a4561fa7129ea9a332ff80d4d3e8aee76ae43/src/tenderswap/Multicall.sol)

**Inherits:**
[IMulticall](/src/tenderswap/Multicall.sol/interface.IMulticall.md)

Enables calling multiple methods in a single call to the contract


## Functions
### multicall

Call multiple functions in the current contract and return the data from all of them if they all succeed

*The `msg.value` should not be trusted for any method callable from multicall.*


```solidity
function multicall(bytes[] calldata _data) external payable override returns (bytes[] memory results);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_data`|`bytes[]`|The encoded function data for each of the calls to make to this contract|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`results`|`bytes[]`|The results from each of the calls passed in via data|



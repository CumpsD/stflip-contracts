# stFlip
[Git Source](https://github.com/thunderhead-labs/stflip-contracts/blob/a54a4561fa7129ea9a332ff80d4d3e8aee76ae43/src/token/stFlip.sol)

**Inherits:**
[StakedFLIP](/src/token/stFlip.sol/contract.StakedFLIP.md)


## Functions
### initialize

Initialize the new money market


```solidity
function initialize(
    string memory name_,
    string memory symbol_,
    uint8 decimals_,
    address initial_owner,
    uint256 initTotalSupply_
) public onlyGov;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`name_`|`string`|ERC-20 name of this token|
|`symbol_`|`string`|ERC-20 symbol of this token|
|`decimals_`|`uint8`|ERC-20 decimal precision of this token|
|`initial_owner`|`address`||
|`initTotalSupply_`|`uint256`||



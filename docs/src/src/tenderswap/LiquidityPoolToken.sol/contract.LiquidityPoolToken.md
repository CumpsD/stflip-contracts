# LiquidityPoolToken
[Git Source](https://github.com/thunderhead-labs/stflip-contracts/blob/7cc8544d9ea72822b709c48cbb1ce3c466520cc8/src/tenderswap/LiquidityPoolToken.sol)

**Inherits:**
OwnableUpgradeable, ERC20BurnableUpgradeable, ERC20PermitUpgradeable


## Functions
### initialize

Initializes this LPToken contract with the given name and symbol

*The caller of this function will become the owner. A Swap contract should call this
in its initializer function.*


```solidity
function initialize(string memory name, string memory symbol) external initializer returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`name`|`string`|name of this token|
|`symbol`|`string`|symbol of this token|


### mint

Mints the given amount of LPToken to the recipient.

*only owner can call this mint function.*


```solidity
function mint(address recipient, uint256 amount) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`recipient`|`address`|address of account to receive the tokens|
|`amount`|`uint256`|amount of tokens to mint|



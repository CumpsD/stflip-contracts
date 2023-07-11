# ISelfPermit
[Git Source](https://github.com/thunderhead-labs/stflip-contracts/blob/7cc8544d9ea72822b709c48cbb1ce3c466520cc8/src/tenderswap/SelfPermit.sol)

Functionality to call permit on any EIP-2612-compliant token for use in the route


## Functions
### selfPermit

Permits this contract to spend a given token from `msg.sender`

*The `owner` is always msg.sender and the `spender` is always address(this).*


```solidity
function selfPermit(address _token, uint256 _value, uint256 _deadline, uint8 _v, bytes32 _r, bytes32 _s)
    external
    payable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_token`|`address`|The address of the token spent|
|`_value`|`uint256`|The amount that can be spent of token|
|`_deadline`|`uint256`|A timestamp, the current blocktime must be less than or equal to this timestamp|
|`_v`|`uint8`|Must produce valid secp256k1 signature from the holder along with `r` and `s`|
|`_r`|`bytes32`|Must produce valid secp256k1 signature from the holder along with `v` and `s`|
|`_s`|`bytes32`|Must produce valid secp256k1 signature from the holder along with `r` and `v`|


### selfPermitIfNecessary

Permits this contract to spend a given token from `msg.sender`

*The `owner` is always msg.sender and the `spender` is always address(this).
Can be used instead of #selfPermit to prevent calls from failing due to a frontrun of a call to #selfPermit*


```solidity
function selfPermitIfNecessary(address _token, uint256 _value, uint256 _deadline, uint8 _v, bytes32 _r, bytes32 _s)
    external
    payable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_token`|`address`|The address of the token spent|
|`_value`|`uint256`|The amount that can be spent of token|
|`_deadline`|`uint256`|A timestamp, the current blocktime must be less than or equal to this timestamp|
|`_v`|`uint8`|Must produce valid secp256k1 signature from the holder along with `r` and `s`|
|`_r`|`bytes32`|Must produce valid secp256k1 signature from the holder along with `v` and `s`|
|`_s`|`bytes32`|Must produce valid secp256k1 signature from the holder along with `r` and `v`|



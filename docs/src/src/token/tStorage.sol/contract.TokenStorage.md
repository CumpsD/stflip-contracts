# TokenStorage
[Git Source](https://github.com/thunderhead-labs/stflip-contracts/blob/7cc8544d9ea72822b709c48cbb1ce3c466520cc8/src/token/tStorage.sol)


## State Variables
### nonces

```solidity
mapping(address => uint256) public nonces;
```


### _notEntered
*Guard variable for re-entrancy checks. Not currently used*


```solidity
bool internal _notEntered;
```


### name
EIP-20 token name for this token


```solidity
string public name;
```


### symbol
EIP-20 token symbol for this token


```solidity
string public symbol;
```


### decimals
EIP-20 token decimals for this token


```solidity
uint8 public decimals;
```


### gov
Governor for this contract


```solidity
address public gov;
```


### pendingGov
Pending governance for this contract


```solidity
address public pendingGov;
```


### rebaser
Approved rebaser for this contract


```solidity
address public rebaser;
```


### burner
Approved burner for this contract


```solidity
address public burner;
```


### minter
Approved minter for this contract


```solidity
address public minter;
```


### totalSupply
Total supply of YAMs


```solidity
uint256 public totalSupply;
```


### internalDecimals
Internal decimals used to handle scaling factor


```solidity
uint256 public constant internalDecimals = 10 ** 24;
```


### BASE
Used for percentage maths


```solidity
uint256 public constant BASE = 10 ** 18;
```


### yamsScalingFactor
Scaling factor that adjusts everyone's balances


```solidity
uint256 public yamsScalingFactor = BASE;
```


### _yamBalances

```solidity
mapping(address => uint256) internal _yamBalances;
```


### _allowedFragments

```solidity
mapping(address => mapping(address => uint256)) internal _allowedFragments;
```


### initSupply

```solidity
uint256 public initSupply;
```


### frozen
Whether the contract is frozen


```solidity
bool public frozen;
```


### PERMIT_TYPEHASH

```solidity
bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
```


### DOMAIN_SEPARATOR

```solidity
bytes32 public DOMAIN_SEPARATOR;
```


### DOMAIN_TYPEHASH

```solidity
bytes32 public constant DOMAIN_TYPEHASH =
    keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
```



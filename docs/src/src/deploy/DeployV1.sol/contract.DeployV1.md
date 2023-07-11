# DeployV1
[Git Source](https://github.com/thunderhead-labs/stflip-contracts/blob/7cc8544d9ea72822b709c48cbb1ce3c466520cc8/src/deploy/DeployV1.sol)


## State Variables
### tenderSwap

```solidity
TenderSwap public tenderSwap;
```


### stflip

```solidity
stFlip public stflip;
```


### admin

```solidity
ProxyAdmin public admin;
```


### minter

```solidity
TransparentUpgradeableProxy public minter;
```


### minterV1

```solidity
MinterV1 public minterV1;
```


### wrappedMinterProxy

```solidity
MinterV1 public wrappedMinterProxy;
```


### burner

```solidity
TransparentUpgradeableProxy public burner;
```


### burnerV1

```solidity
BurnerV1 public burnerV1;
```


### wrappedBurnerProxy

```solidity
BurnerV1 public wrappedBurnerProxy;
```


### aggregator

```solidity
TransparentUpgradeableProxy public aggregator;
```


### aggregatorV1

```solidity
AggregatorV1 public aggregatorV1;
```


### wrappedAggregatorProxy

```solidity
AggregatorV1 public wrappedAggregatorProxy;
```


### output

```solidity
TransparentUpgradeableProxy public output;
```


### outputV1

```solidity
OutputV1 public outputV1;
```


### wrappedOutputProxy

```solidity
OutputV1 public wrappedOutputProxy;
```


### rebaser

```solidity
TransparentUpgradeableProxy public rebaser;
```


### rebaserV1

```solidity
RebaserV1 public rebaserV1;
```


### wrappedRebaserProxy

```solidity
RebaserV1 public wrappedRebaserProxy;
```


### decimals

```solidity
uint8 public decimals = 18;
```


### decimalsMultiplier

```solidity
uint256 public decimalsMultiplier = 10 ** decimals;
```


## Functions
### constructor


```solidity
constructor(
    address flip,
    address gov,
    address stateChainGateway,
    address liquidityPool,
    address manager,
    address feeRecipient
);
```


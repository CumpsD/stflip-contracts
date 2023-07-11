# Summary

This repository contains the forge project used to develop, test and deploy the mls-stflip contracts.

## Repository Structure

```
├── README.md						|	You are looking at it now :)
├── foundry.toml					|	Foundry configuration file
├── lib							|	Solidity libraries				
│   ├── forge-std 					|	Forge standard library. Cheatcodes, console.log, etc		
│   ├── openzeppelin-contracts				|	Openzeppelin library. SafeMath, ERC20, etc
│   └── openzeppelin-contracts-upgradeable		|	Upgradeable OpenZeppelin
├── node_modules					|
├── out 						|	Folder with all of the ABIs
├── package-lock.json					|
├── package.json					|
├── remappings.txt					|	Import remappings
├── docs						| 	documentation for each contract. Functions, tests and deploy.
│   ├── Aggregator.md					|
│   ├── TenderSwap.md 					|
│   ├── Minter.md					|	
│   └── Burner.md					|
├── script						|	Deployment scripts
│   ├── Aggregator.s.sol				|	
│   └── Burner.s.sol					|
├── src							|	Solidity contract source
│   ├── tenderswap					|	Liquidity pool items
│   │   ├── ITenderSwap.sol				|	
│   │   ├── LiquidityPoolToken.sol			|	
│   │   ├── MathUtils.sol				|	
│   │   ├── Multicall.sol				|
│   │   ├── SelfPermit.sol				|
│   │   ├── SwapUtils.sol				|	SwapUtils Library
│   │   └── TenderSwap.sol				|	TenderSwap Pool 
│   ├── token						|	Token related items
│   │   ├── Address.sol					|
│   │   ├── stFlip.sol					|	Main token contract
│   │   └── tStorage.sol				|	Token storage
│   └── utils						|	Extraneous items 
│       ├── Aggregator.sol				|	Aggregator contract
│       ├── Burner.sol					|	Burner contract
│       └── Minter.sol					|	Minter contract
└── test						|	All of the tests
    ├── Aggregator.t.sol				|	Aggregator test
    ├── Burner.t.sol					|	Burner test
    ├── MainMigration.sol				|	Migration that sets everything up for each test
    └── Minter.t.sol					|	Minter test
```

#### Docs

Please see `docs/` for the documentation of each contract and its functions, along with the tests and deploy methodology.

#### ABI

The ABIs are in `abi/`

The file structure is `abi/<ContractName>.json`. For example `abi/Aggregator.json` is the ABI of the `Aggregator` contract.

The script `filter_abi.py` reads through the `out` folder created by Foundry during the build process. As the files created during the build process contain significant redundant information, and change on every build, it does not make sense to push these to GitHub. Please run `filter_abi.py` after making contract changes and prior to committing. This can be made into an action or commit hook later. 
#### Addresses

The contracts are deployed at the following on Goerli

| `LiquidityPoolToken` | [0xE28586DDdeb8C6f2e7828578bBC0eA7B26B9484D](https://goerli.etherscan.io/address/0xE28586DDdeb8C6f2e7828578bBC0eA7B26B9484D) |
| -------------------- | :----------------------------------------------------------- |
| `SwapUtils`          | [0xa90aA02f642de61cFe9E7e81731D895f9E674ffA](https://goerli.etherscan.io/address/0xa90aA02f642de61cFe9E7e81731D895f9E674ffA) |
| `TenderSwap`         | [0x1b61874F49e63014865696e0A1CBa5926C516cDF](https://goerli.etherscan.io/address/0x1b61874F49e63014865696e0A1CBa5926C516cDF) |
| `Aggregator`         | [0x9d719e665da6e6affb4001b26402382e463344db](https://goerli.etherscan.io/address/0x9d719e665da6e6affb4001b26402382e463344db ) |
| `Burner`             | [0x2c3d29Ee44b71DF69c2284F67a0FD467a13b32b9](https://goerli.etherscan.io/address/0x2c3d29Ee44b71DF69c2284F67a0FD467a13b32b9) |
| `Minter`             | [0x9450A1Bf293084c5ad158237638C1361C4A1EE3C](https://goerli.etherscan.io/address/0x9450A1Bf293084c5ad158237638C1361C4A1EE3C) |

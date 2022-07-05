# Basic Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, a sample script that deploys that contract, and an example of a task implementation, which simply lists the available accounts.

Try running some of the following tasks:

```shell
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
node scripts/sample-script.js
npx hardhat help
```
In order to deploy and verify a contract use
```shell
npx hardhat run --network rinkeby scripts/run.js
npx hardhat verify <DEPLOYADDRESS> --network rinkeby --constructor-args utils/eivissa-arguments.js
```
Warning: set base to 6 decimals in case of using USDC.

I.e. If using 200$ value should be 200000000.

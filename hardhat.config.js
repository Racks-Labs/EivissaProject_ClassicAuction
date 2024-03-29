require("@nomiclabs/hardhat-etherscan");
require("@nomicfoundation/hardhat-chai-matchers");
require("dotenv").config();
require("solidity-coverage");
require("hardhat-contract-sizer");
require("hardhat-gas-reporter");

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
	const accounts = await hre.ethers.getSigners();

	for (const account of accounts) {
		console.log(account.address);
	}
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
	networks: {
		rinkeby: {
			url: `${process.env.ALCHEMY_URL_RINKEBY}`,
			accounts: [`0x${process.env.PRIVATE_KEY}`],
		},
		// polygon: {
		// 	url: `${process.env.ALCHEMY_URL_POLYGON}`,
		// 	accounts: [`0x${process.env.PRIVATE_KEY}`],
		// },
	},
	etherscan: {
		apiKey: {
			rinkeby: process.env.ETHERSCAN_KEY,
			mainnet: process.env.ETHERSCAN_KEY,
			// polygon: process.env.POLYGON_KEY
		},
	},
	gasReporter: {
		enabled: true,
		// coinmarketcap: process.env.COINMARKETCAP_API_KEY,
	},
	solidity: {
		version: "0.8.7",
		settings: {
			optimizer: {
				enabled: true,
				runs: 200,
			},
		},
	},
	paths: {
		sources: "./contracts",
		tests: "./test",
		cache: "./cache",
		artifacts: "./artifacts",
	},
	mocha: {
		timeout: 40000,
	},
};

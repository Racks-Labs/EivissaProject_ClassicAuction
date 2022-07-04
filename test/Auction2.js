const { expect, assert } = require("chai");
const { ethers } = require("hardhat");
const { handleRemainingComment } = require("prettier-plugin-solidity/src/comments/handler");
const { sleep, moveBlocks } = require("../utils/move-blocks");

describe("EivissaProject Mint Test", async function () {
	let auctionContract, eivissaContract;
	let usdc, mrc;
	let deployer, acc1, acc2, addrs;

	beforeEach(async () => {
		const Usd = await ethers.getContractFactory("MockErc20");
		const usdc = await Usd.deploy("test", "test");

		const Mrc = await ethers.getContractFactory("MRCRYPTO");
		const mrc = await Mrc.deploy();

		const EivissaContract = await ethers.getContractFactory("EivissaProject");
		eivissaContract = await EivissaContract.deploy();
	});
});

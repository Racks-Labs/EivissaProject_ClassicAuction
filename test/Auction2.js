const { expect, assert } = require("chai");
const { ethers } = require("hardhat");
const { isCallTrace } = require("hardhat/internal/hardhat-network/stack-traces/message-trace");
const { handleRemainingComment } = require("prettier-plugin-solidity/src/comments/handler");
const { sleep, moveBlocks } = require("../utils/move-blocks");

describe("EivissaProject Mint Test", async function () {
	let auctionContract, eivissaContract, saleContract;
	let usdc, mrc;
	let deployer, acc1, acc2, addrs;

	beforeEach(async () => {
		[deployer, acc1, acc2, ...addrs] = await ethers.getSigners();

		const Usd = await ethers.getContractFactory("MockErc20");
		usdc = await Usd.deploy("test", "test");

		const Mrc = await ethers.getContractFactory("MRCRYPTO");
		mrc = await Mrc.deploy("name", "symbol", "uri", "baseUri");

		const EivissaContract = await ethers.getContractFactory("EivissaProject");
		eivissaContract = await EivissaContract.deploy("uri", mrc.address, usdc.address, [10, 6, 3], [100, 200, 300]);

		// Generate a sale contract
		await eivissaContract.newSale([5, 3, 2], "sale1");
		const saleAddress = await eivissaContract.sales(0);
		const Sale = await ethers.getContractFactory("Sale");
		saleContract = Sale.attach(saleAddress);

		// generate auction contract
		await eivissaContract.newAuction([4, 2, 1], "auction1");
		const auctionAddress = await eivissaContract.auctions(0);
		const Auction = await ethers.getContractFactory("Auction");
		auctionContract = Auction.attach(auctionAddress);

		await auctionContract.playPause();
		await saleContract.playPause();

		// mint usdc and mrc for test addresses
		await mrc.mint(1);
		await mrc.connect(acc1).mint(1);
		await mrc.connect(acc2).mint(1);
		await usdc.connect(acc1).mintMore();
		await usdc.connect(acc2).mintMore();
		await eivissaContract.playPause();
	});

	describe("exceptions", () => {
		it("should revert if user not whitelisted", async () => {
			await usdc.connect(acc2).approve(auctionContract.address, 100);
			await expect(saleContract.buy(0)).to.be.revertedWith("whitelistErr");
			await expect(auctionContract.connect(acc2).bid(0, 100)).to.be.revertedWith("whitelistErr");
			//const transaction = await auctionContract.connect(acc2).bid(0, 100);
			//console.log(transaction);
		});
	});
});

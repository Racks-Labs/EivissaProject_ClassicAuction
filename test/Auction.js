const { expect, assert } = require("chai");
const { ethers } = require("hardhat");
const { sleep, moveBlocks } = require("../utils/move-blocks");

describe("EivissaProject Mint Test", async function () {
	let auctionContract, eivissaContract;
	let usdcContract, mrcContract;
	let deployer, acc1, acc2, addrs;

	describe("Setup", () => {
		it("Should deploy Auction, USDC and MRC", async () => {
			[deployer, acc1, acc2, ...addrs] = await ethers.getSigners();

			const Erc20 = await hre.ethers.getContractFactory("MockErc20");
			usdcContract = await Erc20.deploy("USC Coin", "USDC");
			await usdcContract.deployed();

			const MRC = await hre.ethers.getContractFactory("MRCRYPTO");
			mrcContract = await MRC.deploy("Mr. Crypto", "MRC", "baseURI/", "notRevURI/");
			await mrcContract.deployed();
			(await mrcContract.playPause()).wait();
			(await mrcContract.setWhitelistPhase()).wait();

			const Eivissa = await ethers.getContractFactory("EivissaProject");
			eivissaContract = await Eivissa.deploy(
				"uri",
				mrcContract.address,
				usdcContract.address,
				[6, 4, 2],
				[200, 500, 1000]
			);

			await eivissaContract.newAuction([3, 2, 1], "auction1");
			const auctionAddress = await eivissaContract.auctions(0);

			const Auction = await ethers.getContractFactory("Auction");
			auctionContract = Auction.attach(auctionAddress);
			await auctionContract.addAdmin([acc1.address]);
		});
		it("Should mint USDC and MRC", async () => {
			let balanceOf = await usdcContract.balanceOf(deployer.address);
			assert(balanceOf == 100000000000, `Balance is ${balanceOf} and should be 100000000000`);
			(await usdcContract.connect(acc1).mintMore()).wait();
			balanceOf = await usdcContract.balanceOf(acc1.address);
			assert(balanceOf == 10000000000, `Balance is ${balanceOf} and should be 10000`);
			(await usdcContract.connect(acc1).mintMore()).wait();
			(await mrcContract.connect(acc1).mint(1)).wait();
			assert((await mrcContract.balanceOf(acc1.address)) == 1);
		});
	});

	describe("Minting", () => {
		it("Should revert", async () => {
			await expect(auctionContract.connect(acc1).bid(0, 200)).to.be.revertedWith("Paused");
			(await auctionContract.connect(acc1).playPause()).wait();

			await expect(auctionContract.connect(acc1).bid(0, 200)).to.be.revertedWith("Whitelist");
			(await auctionContract.connect(acc1).addToWhitelist([acc1.address])).wait();

			(await usdcContract.connect(acc1).approve(auctionContract.address, 800)).wait();
			await expect(auctionContract.connect(acc1).bid(0, 1)).to.be.revertedWith("Price");
		});
		it("Should bid and override bid", async () => {
			let transaction = await auctionContract.connect(acc1).bid(0, 200);
			transaction.wait();
			await usdcContract.connect(addrs[0]).mintMore();
			await usdcContract.connect(addrs[1]).mintMore();
			await usdcContract.connect(addrs[0]).approve(auctionContract.address, 1000);
			await usdcContract.connect(addrs[1]).approve(auctionContract.address, 1000);

			await mrcContract.connect(addrs[0]).mint(1);
			await mrcContract.connect(addrs[1]).mint(1);
			await auctionContract.connect(acc1).addToWhitelist([addrs[0].address, addrs[1].address]);

			await auctionContract.connect(addrs[0]).bid(0, 200);
			await auctionContract.connect(addrs[1]).bid(0, 200);

			assert((await auctionContract.getRank(0, acc1.address)) == 2, "Rank should be 0");
			assert((await auctionContract.getRank(0, addrs[0].address)) == 1, "Rank should be 1");
			assert((await auctionContract.getRank(0, addrs[1].address)) == 0, "Rank should be 2");
		});
	});

	describe("claim", () => {
		it("should claim the nfts", async () => {
			await eivissaContract.playPause();
			await auctionContract.finish();

			await auctionContract.connect(addrs[0]).claim(0);

			assert((await eivissaContract.balanceOf(addrs[0].address, 0)) == 1);
		});
	});

	describe("Finalize contract", () => {
		it("Should destruct the contract, send funds to eivissa and mint tokens to holders", async () => {});
	});
});

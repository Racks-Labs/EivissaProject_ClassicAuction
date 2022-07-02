const { expect, assert } = require("chai");
const { ethers } = require("hardhat");
const { sleep, moveBlocks } = require("../utils/move-blocks");

describe("EivissaProject Mint Test", async function () {
	let auctionContract, eivissaContract;
	let usdcContract, mrcContract;
	let deployer, acc1, acc2;

	describe("Setup", () => {
		it("Should deploy Auction, USDC and MRC", async () => {
			[deployer, acc1, acc2] = await ethers.getSigners();

			const Erc20 = await hre.ethers.getContractFactory("MockErc20");
			usdcContract = await Erc20.deploy("USC Coin", "USDC");
			await usdcContract.deployed();

			const MRC = await hre.ethers.getContractFactory("MRCRYPTO");
			mrcContract = await MRC.deploy("Mr. Crypto", "MRC", "baseURI/", "notRevURI/");
			await mrcContract.deployed();
			(await mrcContract.playPause()).wait();
			(await mrcContract.setWhitelistPhase()).wait();

			const Auction = await hre.ethers.getContractFactory("Auction");
			auctionContract = await Auction.deploy(ethers.constants.AddressZero, [3, 2, 1], [200, 500, 1000], "name", mrcContract.address, usdcContract.address, acc1.address);
			await auctionContract.deployed();
		});
		it("Should mint USDC and MRC", async () => {
			let balanceOf = await usdcContract.balanceOf(deployer.address);
			assert(balanceOf == 100000000000, `Balance is ${balanceOf} and should be 100000000000`);
			(await usdcContract.connect(acc1).mintMore()).wait();
			balanceOf = await usdcContract.balanceOf(acc1.address);
			assert(balanceOf == 10000000000, `Balance is ${balanceOf} and should be 10000`);
			(await usdcContract.connect(acc2).mintMore()).wait();
			(await mrcContract.connect(acc2).mint(1)).wait();
		});
	});

	describe("Minting", () => {
		it("Should revert", async () => {
			await expect(auctionContract.connect(acc1).bid(0, 3)).to.be.revertedWith("This auction is not running at the moment");
			(await auctionContract.connect(acc1).playPause()).wait();

			await expect(auctionContract.connect(acc1).bid(0, 3)).to.be.revertedWith("You are not whitelisted");
			(await auctionContract.connect(acc1).addToWhitelist([acc1.address])).wait();

			await expect(auctionContract.connect(acc1).bid(0, 3)).to.be.revertedWith("Not enough price");
			await expect(auctionContract.connect(acc1).bid(0, 200)).to.be.revertedWith("ERC20: insufficient allowance");
			(await usdcContract.connect(acc1).approve(auctionContract.address, 800)).wait();
			(await usdcContract.connect(acc2).approve(auctionContract.address, 800)).wait();
		});
		it("Should bid and override bid", async () => {
			let transaction = await auctionContract.connect(acc1).bid(0, 200);
			transaction.wait();
			await auctionContract.connect(acc1).bid(0, 200);
			await auctionContract.connect(acc1).bid(0, 200);
			(await auctionContract.connect(acc1).addToWhitelist([acc2.address])).wait();
			await expect(auctionContract.connect(acc2).bid(0, 200)).to.be.revertedWith("Not enough price");
			await auctionContract.connect(acc2).bid(0, 300);
			assert((await auctionContract.getRank(0, acc1.address)) == 1, "Rank should be 1");
			assert((await auctionContract.getRank(0, acc2.address)) == 0, "Rank should be 0");
		});
		it("Should revert", async () => {
			await expect(auctionContract.connect(acc1).bid(0, 200)).to.be.revertedWith("Not enough price");
			await expect(auctionContract.finish()).to.be.revertedWith("This can only be done from the Eivissa contract");
		});
	});
});

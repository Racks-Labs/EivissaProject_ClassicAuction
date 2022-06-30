const { expect, assert } = require("chai");
const { ethers } = require("hardhat");
const { sleep, moveBlocks } = require("../utils/move-blocks");

describe("EivissaProject Mint Test", async function () {
	let eivissaContract;
	let usdcContract, mrcContract;
	let deployer, acc1, acc2;

	describe("Setup", () => {
		it("Should deploy Eivssa, USDC and MRC", async () => {
			[deployer, acc1, acc2] = await ethers.getSigners();

			const Erc20 = await hre.ethers.getContractFactory("MockErc20");
			usdcContract = await Erc20.deploy("USC Coin", "USDC");
			await usdcContract.deployed();

			const MRC = await hre.ethers.getContractFactory("MRCRYPTO");
			mrcContract = await MRC.deploy("Mr. Crypto", "MRC", "baseURI/", "notRevURI/");
			await mrcContract.deployed();
			(await mrcContract.playPause()).wait();
			(await mrcContract.setWhitelistPhase()).wait();

			const Eivissa = await hre.ethers.getContractFactory("EivissaProject");
			eivissaContract = await Eivissa.deploy("uri", usdcContract.address, mrcContract.address);
			await eivissaContract.deployed();
		});
		it("Should mint USDC", async () => {
			let balanceOf = await usdcContract.balanceOf(deployer.address);
			assert(balanceOf == 100000000000, `Balance is ${balanceOf} and should be 100000000000`);
			(await usdcContract.connect(acc1).mintMore()).wait();
			balanceOf = await usdcContract.balanceOf(acc1.address);
			assert(balanceOf == 10000000000, `Balance is ${balanceOf} and should be 10000`);
		});
	});

	describe("Minting", () => {
		it("Should revert", async () => {
			await expect(eivissaContract.connect(acc1).mint(0)).to.be.revertedWith("Contract is paused");
		});
		it("Shoud start auction", async () => {
			(await eivissaContract.playPause()).wait();

			const auctionSupplies = [1, 2, 3];
			(await eivissaContract.newAuction(2, auctionSupplies)).wait();

			assert((await eivissaContract.auction()) == true, "Auction should be true");
			assert((await eivissaContract.paused()) == false, "Should not be paused");
		});
		it("Should revert", async () => {
			await expect(eivissaContract.connect(acc1).mint(0)).to.be.revertedWith("Only Mr. Crypto holders can mint");
			(await mrcContract.connect(acc1).mint(1, { value: ethers.utils.parseEther("20.0") })).wait();
			assert((await mrcContract.balanceOf(acc1.address)) == 1, "Balance is not 1");

			await expect(eivissaContract.connect(acc1).mint(0)).to.be.revertedWith("You are not whitelisted");
			(await eivissaContract.addToWhitelist([acc1.address])).wait();

			await expect(eivissaContract.connect(acc1).mint(0)).to.be.revertedWith("ERC20: insufficient allowance");

			const price = parseInt(await eivissaContract.getPrice(0));
			await usdcContract.connect(acc1).approve(eivissaContract.address, price);
		});
		it("Should mint only one", async () => {
			(await eivissaContract.connect(acc1).mint(0)).wait();
		});
		it("Should mint the rest", async () => {
			const usdcAmount =
				parseInt(await eivissaContract.getPrice(1)) + parseInt(await eivissaContract.getPrice(2));
			(await usdcContract.connect(acc1).approve(eivissaContract.address, usdcAmount)).wait();

			(await eivissaContract.connect(acc1).mint(2)).wait();
			await expect(eivissaContract.connect(acc1).mint(2)).to.be.revertedWith("ERC20: insufficient allowance");

			(await eivissaContract.connect(acc1).mint(1)).wait();

			for (let i = 0; i < 3; ++i)
				assert(((await eivissaContract.balanceOf(acc1.address, i)) == 1, "Balance is not 1"));
		});
		it("Should revert", async () => {
			await expect(eivissaContract.connect(acc1).mint(0)).to.be.revertedWith(
				"This id has been sold in this auction"
			);
		});
	});
});

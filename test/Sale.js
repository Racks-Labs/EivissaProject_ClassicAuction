const { expect, assert } = require("chai");
const { ethers } = require("hardhat");
const { sleep, moveBlocks } = require("../utils/move-blocks");

describe("EivissaProject Mint Test", async function () {
	let saleContract, eivissaContract;
	let usdcContract, mrcContract;
	let deployer, acc1, acc2;

	describe("Setup", () => {
		it("Should deploy Auction, USDC and MRC", async () => {
			[deployer, acc1, acc2] = await ethers.getSigners();

			const Erc20 = await ethers.getContractFactory("MockErc20");
			usdcContract = await Erc20.deploy("USC Coin", "USDC");
			await usdcContract.deployed();

			const MRC = await ethers.getContractFactory("MRCRYPTO");
			mrcContract = await MRC.deploy("Mr. Crypto", "MRC", "baseURI/", "notRevURI/");
			await mrcContract.deployed();
			(await mrcContract.playPause()).wait();
			(await mrcContract.setWhitelistPhase()).wait();

			const Eivissa = await ethers.getContractFactory("EivissaProject");
			eivissaContract = await Eivissa.deploy("uri/", usdcContract.address, mrcContract.address, [6, 4, 2], [200, 500, 1000]);
			eivissaContract.deployed();
		});
		it("Should deploy a sale", async () => {
			const address = await eivissaContract.newSale([3, 2, 1], "saleee");

			const Sale = await ethers.getContractFactory("Sale");
			saleContract = Sale.attach(address);
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
			await expect(saleContract.connect(acc1).buy(0)).to.be.revertedWith("This sale is not running at the moment");
			(await saleContract.connect(acc1).playPause()).wait();

			await expect(saleContract.connect(acc1).buy(0, 3)).to.be.revertedWith("You are not whitelisted");
			(await saleContract.connect(acc1).addToWhitelist([acc1.address])).wait();

			await expect(saleContract.connect(acc1).buy(0, 3)).to.be.revertedWith("Not enough price");
			await expect(saleContract.connect(acc1).buy(0, 200)).to.be.revertedWith("ERC20: insufficient allowance");
			(await usdcContract.connect(acc1).approve(saleContract.address, 800)).wait();
			(await usdcContract.connect(acc2).approve(saleContract.address, 800)).wait();
		});
		/* it("Should buy and override buy", async () => {
			let transaction = await saleContract.connect(acc1).buy(0, 200);
			transaction.wait();
			await saleContract.connect(acc1).bid(0, 200);
			await saleContract.connect(acc1).bid(0, 200);
			(await saleContract.connect(acc1).addToWhitelist([acc2.address])).wait();
			await expect(saleContract.connect(acc2).bid(0, 200)).to.be.revertedWith("Not enough price");
			await saleContract.connect(acc2).bid(0, 300);
			assert((await saleContract.getRank(0, acc1.address)) == 1, "Rank should be 1");
			assert((await saleContract.getRank(0, acc2.address)) == 0, "Rank should be 0");
		});
		it("Should revert", async () => {
			await expect(saleContract.connect(acc1).bid(0, 200)).to.be.revertedWith("Not enough price");
			await expect(saleContract.finish()).to.be.revertedWith("This can only be done from the Eivissa contract");
		}); */
	});
});

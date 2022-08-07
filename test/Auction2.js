const { expect, assert } = require("chai");
const { ethers } = require("hardhat");
const { isCallTrace } = require("hardhat/internal/hardhat-network/stack-traces/message-trace");
const { handleRemainingComment } = require("prettier-plugin-solidity/src/comments/handler");
const { sleep, moveBlocks } = require("../utils/move-blocks");

describe("Auction2 Test", async function () {
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
		await eivissaContract.newSale([2, 2, 1], "sale1");
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
			await expect(saleContract.buy(0)).to.be.revertedWithCustomError(saleContract, "whitelistErr");
			await expect(auctionContract.connect(acc2).bid(0, 100)).to.be.revertedWithCustomError(
				auctionContract,
				"whitelistErr"
			);
			await auctionContract.addToWhitelist([acc1.address, acc2.address]);
			await saleContract.addToWhitelist([acc2.address]);
			await expect(auctionContract.connect(acc2).bid(0, 100)).to.be.revertedWith("ERC20: insufficient allowance");
			await expect(saleContract.connect(acc2).buy(0)).to.be.revertedWith("ERC20: insufficient allowance");
		});
	});

	describe("bid logic", () => {
		it("should bid correctly", async () => {
			// mint usd mrc and approve
			await usdc.connect(addrs[0]).mintMore();
			await usdc.connect(addrs[1]).mintMore();
			await mrc.connect(addrs[0]).mint(1);
			await mrc.connect(addrs[1]).mint(1);
			await usdc.approve(auctionContract.address, 1000);
			await usdc.connect(acc1).approve(auctionContract.address, 1000);
			await usdc.connect(acc2).approve(auctionContract.address, 1000);
			await usdc.connect(addrs[0]).approve(auctionContract.address, 1000);
			await usdc.connect(addrs[1]).approve(auctionContract.address, 1000);

			await auctionContract.addToWhitelist([
				deployer.address,
				acc1.address,
				acc2.address,
				addrs[0].address,
				addrs[1].address,
			]);

			await auctionContract.connect(acc1).bid(0, 105);
			await auctionContract.connect(acc2).bid(0, 110);
			await auctionContract.connect(addrs[0]).bid(0, 100);
			await auctionContract.connect(addrs[1]).bid(0, 108);

			// check minPrice of id has been updated correctly
			expect(await auctionContract.minPrices(0)).to.be.equal(105);

			// check that usd is transfered back to user outbid
			expect(await auctionContract.bid(0, 105))
				.to.emit(usdc, "Transfer")
				.withArgs(auctionContract.address, acc1.address, 100);

			// bid left ranges
			await auctionContract.connect(addrs[1]).bid(1, 200);
			await auctionContract.connect(addrs[0]).bid(1, 200);
			await auctionContract.connect(acc1).bid(2, 300);

			// check auction contract has received the correct usdc amount
			expect(await usdc.balanceOf(auctionContract.address)).to.be.equal(1128);

			// finish auction + send balance to eivissa
			expect(await auctionContract.finish())
				.to.emit(usdc, "Transfer")
				.withArgs(auctionContract.address, eivissaContract.address, 1128);

			// claim nfts foreach user
			await auctionContract.connect(acc1).claim(0);

			expect(await eivissaContract.balanceOf(acc1.address, 0)).to.be.equal(1);
		});
	});

	describe("Sale", () => {
		it("should buy all nfts of a sale", async () => {
			// mint usdc for left addresses
			await usdc.connect(addrs[0]).mintMore();
			await usdc.connect(addrs[1]).mintMore();
			await mrc.connect(addrs[0]).mint(1);
			await mrc.connect(addrs[1]).mint(1);

			// Add to whitelist test addresses
			await saleContract.addToWhitelist([
				deployer.address,
				acc1.address,
				acc2.address,
				addrs[0].address,
				addrs[1].address,
			]);

			await usdc.approve(saleContract.address, 100);
			await usdc.connect(acc1).approve(saleContract.address, 100);
			await usdc.connect(acc2).approve(saleContract.address, 200);
			await usdc.connect(addrs[0]).approve(saleContract.address, 200);
			await usdc.connect(addrs[1]).approve(saleContract.address, 300);

			//mint nfts
			await saleContract.buy(0);
			await saleContract.connect(acc1).buy(0);
			await saleContract.connect(acc2).buy(1);
			await saleContract.connect(addrs[0]).buy(1);
			await saleContract.connect(addrs[1]).buy(2);

			// revert if user already minted
			await expect(saleContract.buy(0)).to.be.reverted;

			// check minter balances
			expect(await eivissaContract.balanceOf(deployer.address, 0)).to.be.equal(1);
			expect(await eivissaContract.balanceOf(acc1.address, 0)).to.be.equal(1);
			expect(await eivissaContract.balanceOf(acc2.address, 1)).to.be.equal(1);
			expect(await eivissaContract.balanceOf(addrs[0].address, 1)).to.be.equal(1);
			expect(await eivissaContract.balanceOf(addrs[1].address, 2)).to.be.equal(1);

			// check usdc has been transfered to eivissa
			expect(await usdc.balanceOf(eivissaContract.address)).to.be.equal(900);

			// check withdraw of the funds
			const balOfDeployer = Number(await usdc.balanceOf(deployer.address));
			const balOfEivissa = Number(await usdc.balanceOf(eivissaContract.address));
			await eivissaContract.withdraw();
			const balAfterWithdraw = Number(await usdc.balanceOf(deployer.address));

			expect(balAfterWithdraw).to.be.equal(balOfDeployer + balOfEivissa);
		});
	});
});

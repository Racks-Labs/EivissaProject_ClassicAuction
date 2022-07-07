const { expect, assert } = require("chai");
const { ethers } = require("hardhat");
const { isCallTrace } = require("hardhat/internal/hardhat-network/stack-traces/message-trace");
const { handleRemainingComment } = require("prettier-plugin-solidity/src/comments/handler");
const { sleep, moveBlocks } = require("../utils/move-blocks");

describe("Auction Gas Test", async function () {
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
		eivissaContract = await EivissaContract.deploy("uri", mrc.address, usdc.address, [100, 6, 3], [100, 200, 300]);

		// generate auction contract
		await eivissaContract.newAuction([100, 2, 1], "auction1");
		const auctionAddress = await eivissaContract.auctions(0);
		const Auction = await ethers.getContractFactory("Auction");
		auctionContract = Auction.attach(auctionAddress);

		await auctionContract.playPause();

		// mint usdc and mrc for test addresses
		await mrc.mint(1);
		await mrc.connect(acc1).mint(1);
		await usdc.connect(acc1).mintMore();
		await eivissaContract.playPause();
	});

	describe("exceptions", () => {
		it("should revert if user not whitelisted", async () => {
			//await expect(saleContract.buy(0)).to.be.revertedWith("whitelistErr");
			//await expect(auctionContract.connect(acc2).bid(0, 100)).to.be.revertedWith("whitelistErr");
			await auctionContract.addToWhitelist([acc1.address, acc2.address]);
			//await expect(auctionContract.connect(acc2).bid(0, 100)).to.be.revertedWith("ERC20: insufficient allowance");
			//await expect(saleContract.connect(acc2).buy(0)).to.be.revertedWith("ERC20: insufficient allowance");
		});
	});

	describe("bid logic", () => {
		it("should bid correctly", async () => {
			await usdc.connect(acc1).approve(auctionContract.address, 100000);
			await auctionContract.addToWhitelist([acc1.address]);

			for (let i = 0; i < 65; ++i) {
				//console.log(i)
				await auctionContract.connect(acc1).bid(0, 100);
			}
			let transaction = await (await auctionContract.connect(acc1).bid(0, 200)).wait();
			//console.log("gas ===== ", transaction)

			/* // check range has been added correctly
			expect(await auctionContract.getRank(0, acc1.address)).to.be.equal(0);
			expect(await auctionContract.getRank(0, acc2.address)).to.be.equal(1);
			expect(await auctionContract.getRank(0, addrs[0].address)).to.be.equal(2);
			expect(await auctionContract.getRank(0, addrs[1].address)).to.be.equal(3);

			// check minPrice of id has been updated correctly
			expect(await auctionContract.minPrices(0)).to.be.equal(105);

			// check that usd is transfered back to user outbid
			expect(await auctionContract.bid(0, 105))
				.to.emit(usdc, "Transfer")
				.withArgs(auctionContract.address, acc1.address, 100);

			//check new bidder has correct possition
			expect(await auctionContract.getRank(0, deployer.address)).to.be.equal(0);

			// bid left ranges
			await auctionContract.connect(addrs[1]).bid(1, 200);
			await auctionContract.connect(addrs[0]).bid(1, 200);
			await auctionContract.connect(acc1).bid(2, 300);

			// check auction contract has received the correct usdc amount
			expect(await usdc.balanceOf(auctionContract.address)).to.be.equal(1105);

			// finish auction + send balance to eivissa
			expect(await auctionContract.finish())
				.to.emit(usdc, "Transfet")
				.withArgs(auctionContract.address, eivissaContract.address, 1105);

			// claim nfts foreach user
			await auctionContract.connect(acc1).claim(0);

			expect(await eivissaContract.balanceOf(acc1.address, 0)).to.be.equal(1); */
		});
	});
});

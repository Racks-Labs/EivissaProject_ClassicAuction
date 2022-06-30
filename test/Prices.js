const { expect, assert } = require("chai");
const { ethers } = require("hardhat");
const { sleep, moveBlocks } = require("../utils/move-blocks");

const tickets = [
	{ startPrice: 800, endPrice: 200, maxSupply: 80 },
	{ startPrice: 1500, endPrice: 800, maxSupply: 20 },
	{ startPrice: 3000, endPrice: 1500, maxSupply: 10 },
];

describe("EivissaProject Prices Test", async function () {
	let eivissaContract;
	let deployer, acc1, acc2;

	describe("Setup", () => {
		it("Should deploy Eivssa and USDC", async () => {
			[deployer, acc1, acc2] = await ethers.getSigners();

			const Eivissa = await hre.ethers.getContractFactory("EivissaProject");
			eivissaContract = await Eivissa.deploy("uri", acc1.address, acc2.address);
			await eivissaContract.deployed();
		});
	});

	describe("Token prices", () => {
		it("Shoud start auction", async () => {
			let transtaction = await eivissaContract.playPause();
			transtaction.wait();

			const auctionSupplies = [1, 2, 3];
			transtaction = await eivissaContract.newAuction(2, auctionSupplies);
			transtaction.wait();

			assert((await eivissaContract.auction()) == true, "Auction should be true");
			assert((await eivissaContract.paused()) == false, "Should not be paused");
		});
		it("Should decrease price of nfts correctly", async () => {
			const blocksToMove = 1000;
			await moveBlocks(blocksToMove);

			for (let i = 0; i < 3; ++i) {
				const decrementRatio = await eivissaContract.decrementRatio(i);
				const targetPrice = tickets[i].startPrice * 1000000 - decrementRatio * 1000;
				const price = await eivissaContract.getPrice(i);
				console.log(`	Price of id ${i} = ${price}`);
				assert(price == targetPrice, `Price on id ${i} is ${price} and should be ${targetPrice}`);
			}
			//assert(price.toString() === `${targetPrice.toFixed() - 1}`);
		});
		it("Price should not go below endPrice", async () => {
			const blocksToMove = 13000;
			await moveBlocks(blocksToMove);
			const targetPrice = (80000 - 5 * blocksToMove) / 100;

			for (let i = 0; i < 3; ++i) {
				let price = await eivissaContract.getPrice(i);
				assert(price == tickets[i].endPrice * 1000000, `Price (${price}) in id = ${i} should be ${tickets[i].endPrice}`);
			}
		});
	});
});

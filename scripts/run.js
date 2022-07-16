const hre = require("hardhat");

const main = async () => {
	const [deployer, add1, add2] = await hre.ethers.getSigners();

	const Eivissa = await hre.ethers.getContractFactory("EivissaProject");
	const contract = await Eivissa.deploy(
		"https://apinft.racksmafia.com/eivissa-project/metadata",
		"0xeF453154766505FEB9dBF0a58E6990fd6eB66969",
		"0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174",
		[40, 40, 20],
		[340000000, 590000000, 1290000000]
	);
	await contract.deployed();

	console.log("contract deployed to", contract.address);
};

main()
	.then(() => process.exit(0))
	.catch((err) => {
		console.log(err);
		process.exit(1);
	});

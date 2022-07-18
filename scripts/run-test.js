const hre = require("hardhat");

const main = async () => {
	const [deployer, add1, add2] = await hre.ethers.getSigners();

	const Eivissa = await hre.ethers.getContractFactory("EivissaProject");
	const contract = await Eivissa.deploy(
		"https://apinft.racksmafia.com/eivissa-project/metadata",
		"0x66fce2bF6f40deC0Af3F9E8018B11125bb62ed82", //mrc rinkeby
		"0xeb8f08a975Ab53E34D8a0330E0D34de942C95926", //usdc
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

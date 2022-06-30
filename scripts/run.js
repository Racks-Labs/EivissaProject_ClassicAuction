const hre = require("hardhat");

const main = async () => {
	const [deployer, add1, add2] = await hre.ethers.getSigners();

	const Eivissa = await hre.ethers.getContractFactory("EivissaProject");
	const contract = await Eivissa.deploy(
		"uri",
		"0xeb8f08a975Ab53E34D8a0330E0D34de942C95926",
		"0x66fce2bF6f40deC0Af3F9E8018B11125bb62ed82"
	);
	await contract.deployed();

	console.log("contract deployed to", contract.address);
	const price = await contract.getPrice(0);
	console.log(price.toString());
};

main()
	.then(() => process.exit(0))
	.catch((err) => {
		console.log(err);
		process.exit(1);
	});

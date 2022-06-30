//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";



struct Ticket {
	uint256 startPrice;
	uint256 endPrice;
	uint256 maxSupply;
}

//TODO: set values
contract Base {
	uint256 base = 1000000;
	IERC20 USDC; // = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
	IMRC MRC; // = IMRC(0xeF453154766505FEB9dBF0a58E6990fd6eB66969);

	//NOTE:	royalty must be set between 0 and 100
	uint256[3] royalties;
	address royaltyWallet;

	Ticket[3] tickets;
	// al modificar esta variable podemos ir dropeando n numero de entradas
	// por rango,
	uint16[3] currMaxSupply = [0, 0, 0];
	uint256 maxPerWallet = 3;

	constructor(address usdc, address mrc) {
		USDC = IERC20(usdc);
		MRC = IMRC(mrc);
		tickets[0].startPrice = 800 * base;
		tickets[0].endPrice = 200 * base;

		tickets[1].startPrice = 1500 * base;
		tickets[1].endPrice = 800 * base;

		tickets[2].startPrice = 3000 * base;
		tickets[2].endPrice = 1500 * base;

		tickets[0].maxSupply = 80;
		tickets[1].maxSupply = 20;
		tickets[2].maxSupply = 15;
	}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./System.sol";

contract Sale is System {
	uint256[3] public currentSupply;
	mapping(address => bool) private userMints;

	event saleEvent(address sender, uint256 id);

	constructor(
		IEivissaProject eivissa_,
		uint256[3] memory maxSupplies_,
		uint256[3] memory minPrices_,
		string memory name_,
		IMRC mrc_,
		IERC20 usd_,
		address newAdmin
	) System(eivissa_, maxSupplies_, minPrices_, name_, mrc_, usd_, newAdmin) {}

	//PUBLIC

	function buy(uint256 id) public isNotPaused onlyHolder isWhitelisted {
		if (id >= 3) revert invalidIndex();
		if (currentSupply[id] >= maxSupplies[id]) revert noTokensLeftErr();
		require(!userMints[msg.sender]);

		unchecked {
			++(currentSupply[id]);
		}
		userMints[msg.sender] = true;
		emit saleEvent(msg.sender, id);
		eivissa.mint(msg.sender, id, 1);

		if (!usd.transferFrom(msg.sender, address(eivissa), minPrices[id])) revert usdTransferFailed();
	}
}

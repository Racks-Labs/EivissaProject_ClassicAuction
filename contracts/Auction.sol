//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./System.sol";
import "./Bidder.sol";
import "./Err.sol";

contract Auction is System {
	Bidder[][3] public bidders;
	mapping(address => uint256[3]) public claimable;
	bool internal locked;

	modifier noReentrant() {
		require(!locked);
		locked = true;
		_;
		locked = false;
	}

	event auctionEvent(address sender, uint256 id, uint256 price);

	constructor(
		IEivissaProject eivissa_,
		uint256[3] memory maxSupplies_,
		uint256[3] memory minPrices_,
		string memory name_,
		IMRC mrc_,
		IERC20 usd_,
		address newAdmin
	) System(eivissa_, maxSupplies_, minPrices_, name_, mrc_, usd_, newAdmin) {
		locked = false;
	}

	//PUBLIC

	function bid(uint256 id, uint256 price) public isNotPaused onlyHolder isWhitelisted noReentrant {
		if (finished) revert auctionFinished();
		if (id > 3) revert invalidIndex();
		if (price < minPrices[id]) revert invalidPrice();

		emit auctionEvent(msg.sender, id, price);
		addBidder(msg.sender, price, id);
		if (!usd.transferFrom(msg.sender, address(this), price)) revert usdTransferFailed();
	}

	function biddersAmount(uint256 id) external view returns (uint256) {
		return bidders[id].length;
	}

	function isInBid(address wallet, uint256 id) external view returns (bool) {
		for (uint256 i = 0; i < bidders[id].length; ++i) if (bidders[id][i].wallet == wallet) return true;
		return false;
	}

	function claim(uint256 id) public {
		if (!finished) revert auctionFinished();
		uint256 claimableNum = claimable[msg.sender][id];
		if (claimableNum <= 0) revert auctionNoClaimableLeft();

		claimable[msg.sender][id] = 0;
		eivissa.mint(msg.sender, id, claimableNum);
	}

	//INTERNAL

	function addBidder(
		address newOne,
		uint256 amount,
		uint256 id
	) private {
		claimable[msg.sender][id] += 1;
		Bidder memory tmp = Bidder(newOne, amount);
		bool newEntered = false;

		for (uint256 i = 0; i < bidders[id].length; ++i) {
			if (
				(newEntered == false && tmp.amount > bidders[id][i].amount) ||
				(newEntered == true && tmp.amount >= bidders[id][i].amount)
			) {
				newEntered = true;
				Bidder memory aux = bidders[id][i];
				bidders[id][i] = tmp;
				tmp = aux;
			}
		}

		if (bidders[id].length < maxSupplies[id]) {
			bidders[id].push(tmp);
		} else {
			claimable[tmp.wallet][id] -= 1;
			if (!usd.transfer(tmp.wallet, tmp.amount)) revert usdTransferFailed();
		}

		if (bidders[id].length == maxSupplies[id]) {
			uint256 increment = (bidders[id][bidders[id].length - 1].amount * 5) / 100;
			minPrices[id] = bidders[id][bidders[id].length - 1].amount + increment;
		}
	}
}

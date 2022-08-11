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

	function bid(uint256 id, uint256 price) external isNotPaused onlyHolder isWhitelisted noReentrant {
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
		unchecked {
			claimable[msg.sender][id] += 1;
		}
		Bidder memory tmp = Bidder(newOne, amount);
		uint256 biddersLenght = bidders[id].length;
		uint256 _maxSupply = maxSupplies[id];

		if (biddersLenght < _maxSupply) {
			bidders[id].push(tmp);
			if ((biddersLenght + 1) == _maxSupply) {
				insertionSort(id);
				unchecked {
					minPrices[id] = bidders[id][0].amount + (bidders[id][0].amount * 5) / 100;
				}
			}
		} else {
			insertionSort(id);
			Bidder memory lowestBidder = bidders[id][0];
			if (tmp.amount > lowestBidder.amount) {
				unchecked {
					claimable[lowestBidder.wallet][id] -= 1;
					bidders[id][0] = tmp;

					minPrices[id] = bidders[id][1].amount + (bidders[id][1].amount * 5) / 100;
				}
				if (!usd.transfer(lowestBidder.wallet, lowestBidder.amount)) revert usdTransferFailed();
			} else {
				unchecked {
					claimable[tmp.wallet][id] -= 1;
					minPrices[id] = lowestBidder.amount + (lowestBidder.amount * 5) / 100;
				}
				if (!usd.transfer(tmp.wallet, tmp.amount)) revert usdTransferFailed();
			}
		}
	}

	function insertionSort(uint256 id) internal {
		unchecked {
			uint256 length = bidders[id].length;
			uint256 j;
			for (uint256 i = 1; i < length; i++) {
				Bidder memory key = bidders[id][i];
				j = i - 1;
				while ((int256(j) >= 0) && (bidders[id][j].amount > key.amount)) {
					bidders[id][j + 1] = bidders[id][j];
					j--;
				}
				bidders[id][j + 1] = key;
			}
		}
	}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/* import "./IEivissaProject.sol";
import "./Err.sol";
import "./IMRC.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; */
import "./System.sol";
import "./Bidder.sol";


contract Auction is System {
	Bidder[][3] public bidders;
	mapping(address => uint256[3]) public claimable;

	event auctionEvent(address sender, uint256 id, uint256 price);

	constructor(IEivissaProject eivissa_,
				uint256[3] memory maxSupplies_,
				uint256[3] memory minPrices_,
				string memory name_,
				IMRC mrc_,
				IERC20 usd_,
				address newAdmin) System(
					eivissa_,
					maxSupplies_,
					minPrices_,
					name_,
					mrc_,
					usd_,
					newAdmin) {}

	//PUBLIC

	function bid(uint256 id, uint256 price) public isNotPaused onlyHolder isWhitelisted {
		require(finished == false, "Has finished");
		require(id < 3, "Invalid index");
		require(price >= minPrices[id], "Price");

		usd.transferFrom(msg.sender, address(this), price);
		addBidder(msg.sender, price, id);
	}

	function getRank(uint256 id, address wallet) public view returns(uint256) {
		for (uint256 i = 0; i < bidders[id].length; ++i)
			if (bidders[id][i].wallet == wallet)
				return i;
		return bidders[id].length;
	}

	function claim(uint256 id) public {
		uint256 claimableNum = claimable[msg.sender][id];

		require(finished == true, "Not finished");
		require(claimableNum > 0, "No left");
		claimable[msg.sender][id] = 0;
		eivissa.mint(msg.sender, id, claimableNum);
	}

	//INTERNAL

	function addBidder(address newOne, uint256 amount, uint256 id) private {
		claimable[msg.sender][id] += 1;
		Bidder memory tmp = Bidder(newOne, amount);
		for (uint256 i = 0; i < bidders[id].length; ++i) {
			if (tmp.amount >= bidders[id][i].amount) {
				Bidder memory aux = bidders[id][i];
				bidders[id][i] = tmp;
				tmp = aux;
			}
		}

		if (bidders[id].length < maxSupplies[id]) {
			bidders[id].push(tmp);
		} else {
			claimable[tmp.wallet][id] -= 1;
			usd.transfer(tmp.wallet, tmp.amount);
		}

		if (bidders[id].length == maxSupplies[id]) {
			uint256 increment = bidders[id][bidders.length - 1].amount * 5 / 100;
			minPrices[id] = bidders[id][bidders.length - 1].amount + increment;
		}
	}
}

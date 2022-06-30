//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./EivissaProject.sol";
import "./Bidder.sol";
import "./IMRC.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "hardhat/console.sol";

contract ClassicAuction {
	uint256[3] public maxSupplies;
	uint256[3] public minPrices;
	Bidder[3][] bidders;
	IMRC mrc;
	IERC20 usd;
	string name;
	bool public paused = true;
	mapping(address => bool) isAdmin;
	mapping(address => bool) whitelist;
	EivissaProject eivissa;

	modifier isNotPaused() {
		require(paused == false, "No auction running at the moment");
		_;
	}

	modifier isNotFinished() {
		require(finished == false, "Auction has finished");
	}

	modifier onlyAdmin {
		require(isAdmin[msg.sender] == true, "Only admins can do this");
		_;
	}

	modifier whitelisted {
		require(whitelist[msg.sender] == true, "You are not whitelisted");
		_;
	}

	modifier onlyHolder {
		require(mrc.balanceOf(msg.sender) > 0 || isAdmin[msg.sender] == true, "Only holders can do this");
		_;
	}

	modifier onlyEivissa {
		require(msg.sender == address(eivissa), "This can be done only from the Eivissa contract");
		_;
	}

	constructor(EivissaProject eivissa_, uint256[3] memory maxSupplies_, uint256[3] memory minPrices_, string name_, IMRC mrc_, IERC20 usd_) {
		eivissa = eivissa_;
		maxSupplies = maxSupplies_;
		minPrices = minPrices_;
		mrc = mrc_;
		usd = usd_;
		name = name_;
		isAdmin[address(eivissa)] = true;
	}

	//PUBLIC

	function bid(uint256 id, uint256 amount) public onlyHolder whitelisted {
		require(id < 3, "Invalid index");
		require(amount > minPrices[id]);
		usd.transferFrom(msg.sender, address(this), amount);
		addBidder(msg.sender, amount, id);
	}

	function playPause() public onlyAdmin {
		paused = !paused;
	}

	function finish() public onlyEivissa {
		for (uint256 id = 0; id < 3; ++id)
			for (uint256 i = 0; i < bidders[id].length; ++i)
				eivissa.mint(bidders[id].wallet, id);
		usd.transfer(address(eivissa), usd.balanceOf(address(this)));
		selfdestruct(address(eivissa));
	}

	function addAdmin(address[] newOnes) onlyAdmin {
		for (uint256 i = 0; i < newOnes.length; ++i)
			isAdmin[newOnes[i]] = true;
	}

	function removeAdmin(address[] newOnes) onlyAdmin {
		for (uint256 i = 0; i < newOnes.length; ++i) {
			if (newOnes[i] != msg.sender)
				isAdmin[newOnes[i]] = false;
		}
	}

	function addToWhitelist(address[] newOnes) onlyAdmin {
		for (uint256 i = 0; i < newOnes.length; ++i)
			whitelist[newOnes[i]] = true;
	}

	function removeFromWhitelist(address[] newOnes) onlyAdmin {
		for (uint256 i = 0; i < newOnes.length; ++i)
			whitelist[newOnes[i]] = false;
	}

	//INTERNAL

	function addBidder(address newOne, uint256 amount, uint256 id) private {
		if (bidders[id].length < maxSupplies[id]) {
			bidders[id].push(Bidder(msg.sender, amount));
			if (bidders[id].length == maxSupplies[id])
				minPrices[id] = amount;
		} else {
			Bidder tmp = Bidder(msg.sender, amount);
			for (uint256 i = 0; i < bidders[id].length; ++i) {
				if (tmp.amount > bidders[id][i].amount) {
					Bidder aux = bidders[id][i];
					bidders[id][i] = tmp;
					tmp = aux;
				}
			}
			usd.transfer(tmp.wallet, tmp.amount);
		}
	}

	receive() external payable {}
}

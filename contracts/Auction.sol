//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./EivissaProject.sol";
import "./Bidder.sol";
import "./IMRC.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "hardhat/console.sol";

contract Auction {
	uint256[3] public maxSupplies;
	uint256[3] public minPrices;
	Bidder[][3] public bidders;
	IMRC mrc;
	IERC20 usd;
	string public name;
	bool public paused = true;
	mapping(address => bool) isAdmin;
	mapping(address => bool) whitelist;
	EivissaProject eivissa;

	modifier isNotPaused() {
		require(paused == false, "This auction is not running at the moment");
		_;
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
		require(msg.sender == address(eivissa), "This can only be done from the Eivissa contract");
		_;
	}

	constructor(EivissaProject eivissa_,
				uint256[3] memory maxSupplies_,
				uint256[3] memory minPrices_,
				string memory name_,
				IMRC mrc_,
				IERC20 usd_,
				address newAdmin) {
		eivissa = eivissa_;
		maxSupplies = maxSupplies_;
		minPrices = minPrices_;
		mrc = mrc_;
		usd = usd_;
		name = name_;
		isAdmin[address(eivissa)] = true;
		isAdmin[newAdmin] = true;
	}

	//PUBLIC

	function bid(uint256 id, uint256 price) public isNotPaused onlyHolder whitelisted {
		require(id < 3, "Invalid index");
		if (bidders[id].length == maxSupplies[id])
			require(price > minPrices[id], "Not enough price");
		else
			require(price >= minPrices[id], "Not enough price");

		usd.transferFrom(msg.sender, address(this), price);
		addBidder(msg.sender, price, id);
	}

	function getRank(uint256 id, address wallet) public view returns(uint256) {
		for (uint256 i = 0; i < bidders[id].length; ++i)
			if (bidders[id][i].wallet == wallet)
				return i;
		return bidders[id].length;
	}

	function playPause() public onlyAdmin {
		paused = !paused;
	}

	function finish() public onlyEivissa {
		for (uint256 id = 0; id < 3; ++id)
			for (uint256 i = 0; i < bidders[id].length; ++i)
				eivissa.mint(bidders[id][i].wallet, id, bidders[id][i].amount);
		usd.transfer(address(eivissa), usd.balanceOf(address(this)));
		selfdestruct(payable(address(eivissa)));
	}

	function addAdmin(address[] memory newOnes) public onlyAdmin {
		for (uint256 i = 0; i < newOnes.length; ++i)
			isAdmin[newOnes[i]] = true;
	}

	function removeAdmin(address[] memory newOnes) public onlyAdmin {
		for (uint256 i = 0; i < newOnes.length; ++i) {
			if (newOnes[i] != msg.sender)
				isAdmin[newOnes[i]] = false;
		}
	}

	function addToWhitelist(address[] memory newOnes) public onlyAdmin {
		for (uint256 i = 0; i < newOnes.length; ++i)
			whitelist[newOnes[i]] = true;
	}

	function removeFromWhitelist(address[] memory newOnes) public onlyAdmin {
		for (uint256 i = 0; i < newOnes.length; ++i)
			whitelist[newOnes[i]] = false;
	}

	//INTERNAL

	function addBidder(address newOne, uint256 amount, uint256 id) private {
		if (bidders[id].length < maxSupplies[id]) {
			bidders[id].push(Bidder(newOne, amount));
		} else {
			Bidder memory tmp = Bidder(newOne, amount);
			for (uint256 i = 0; i < bidders[id].length; ++i) {
				if (tmp.amount >= bidders[id][i].amount) {
					Bidder memory aux = bidders[id][i];
					bidders[id][i] = tmp;
					tmp = aux;
				}
			}
			usd.transfer(tmp.wallet, tmp.amount);
		}
		if (bidders[id].length == maxSupplies[id])
			minPrices[id] = amount;
	}

	receive() external payable {}
}
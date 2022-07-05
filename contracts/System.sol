//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IEivissaProject.sol";
import "./Err.sol";
import "./IMRC.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract System {
	uint256[3] public maxSupplies;
	uint256[3] public minPrices;
	IMRC mrc;
	IERC20 usd;
	string public name;
	bool public paused = true;
	bool public whitelistEnabled = true;
	bool public finished = false;
	mapping(address => bool) public isAdmin;
	mapping(address => bool) public whitelist;
	IEivissaProject eivissa;

	modifier isNotPaused() {
		if (isAdmin[msg.sender] == false && paused == true)
			revert pausedErr();
		_;
	}

	modifier onlyAdmin() {
		//require(isAdmin[msg.sender] == true, "adminErr");
		if (isAdmin[msg.sender] == false)
			revert adminErr();
		_;
	}

	modifier isWhitelisted() {
		if (whitelistEnabled == true && whitelist[msg.sender] == false)
			revert whitelistErr();
		_;
	}

	modifier onlyHolder() {
		if (mrc.balanceOf(msg.sender) == 0 && isAdmin[msg.sender] == false)
			revert holderErr();
		_;
	}

	constructor(IEivissaProject eivissa_,
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

	function playPause() public onlyAdmin {
		paused = !paused;
	}

	function finish() public onlyAdmin {
		finished = !finished;
		usd.transfer(address(eivissa), usd.balanceOf(address(this)));
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

	function switchWhitelist() public onlyAdmin {
		whitelistEnabled = !whitelistEnabled;
	}

	receive() external payable {}
}

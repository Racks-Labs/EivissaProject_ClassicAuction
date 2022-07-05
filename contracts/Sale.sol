//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./EivissaProject.sol";
import "./IMRC.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

	error Sale_pausedErr();
	error Sale_whitelistErr();
	error Sale_transferibleErr();
	error Sale_adminErr();
	error Sale_holderErr();

contract Sale {
	uint256[3] public currentSupply;
	uint256[3] public maxSupplies;
	uint256[3] public minPrices;
	IMRC mrc;
	IERC20 usd;
	string public name;
	bool public paused = true;
	bool public whitelistEnabled = true;
	mapping(address => bool) public isAdmin;
	mapping(address => bool) public whitelist;
	mapping(address => bool) userMints;
	EivissaProject eivissa;

	modifier isNotPaused() {
		if (isAdmin[msg.sender] == false && paused == true)
			revert Sale_pausedErr();
		_;
	}

	modifier onlyAdmin() {
		if (isAdmin[msg.sender] == false)
			revert Sale_adminErr();
		_;
	}

	modifier isWhitelisted() {
		if (whitelistEnabled == true && whitelist[msg.sender] == false)
			revert Sale_whitelistErr();
		_;
	}

	modifier onlyHolder() {
		if (mrc.balanceOf(msg.sender) == 0 && isAdmin[msg.sender] == false)
			revert Sale_holderErr();
		_;
	}

	

	event saleEvent(address sender, uint256 id);

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

	function buy(uint256 id) public isNotPaused onlyHolder isWhitelisted {
		require(id < 3, "Invalid index");
		require(currentSupply[id] < maxSupplies[id]);
		require(userMints[msg.sender] == false);

		usd.transferFrom(msg.sender, address(eivissa), minPrices[id]);
		++(currentSupply[id]);

		userMints[msg.sender] = true;
		eivissa.mint(msg.sender, id, 1);
		emit saleEvent(msg.sender, id);
	}

	function playPause() public onlyAdmin {
		paused = !paused;
	}

	function finish() public onlyAdmin {
		usd.transfer(address(eivissa), usd.balanceOf(address(this)));
		//selfdestruct(payable(address(eivissa)));
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

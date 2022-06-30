//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./DutchAuction.sol";

//              ▟██████████   █████    ▟███████████   █████████████
//            ▟████████████   █████  ▟█████████████   █████████████   ███████████▛
//           ▐█████████████   █████▟███████▛  █████   █████████████   ██████████▛
//            ▜██▛    █████   ███████████▛    █████       ▟██████▛    █████████▛
//              ▀     █████   █████████▛      █████     ▟██████▛
//                    █████   ███████▛      ▟█████▛   ▟██████▛
//   ▟█████████████   ██████              ▟█████▛   ▟██████▛   ▟███████████████▙
//  ▟██████████████   ▜██████▙          ▟█████▛   ▟██████▛   ▟██████████████████▙
// ▟███████████████     ▜██████▙      ▟█████▛   ▟██████▛   ▟█████████████████████▙
//                        ▜██████▙            ▟██████▛          ┌────────┐
//                          ▜██████▙        ▟██████▛            │  LABS  │
//                                                              └────────┘

contract EivissaProject is Ownable, ERC1155Supply {
	bool public paused = true;
	bool public transferible = true;
	mapping(address => bool) whitelist;
	mapping(address => bool) public isAdmin;
	string public baseURI;

	modifier isNotPaused() {
		if (isAdmin[msg.sender] == false)
			require(paused == false, "Contract is paused");
		_;
	}

	modifier isTransferible() {
		require(transferible == true, "Contract is not transferible");
		_;
	}

	modifier onlyAdmin() {
		require(isAdmin[msg.sender] == true, "You're not an admin");
		_;
	}

	modifier onlyHolder() {
		require(IMRC.balanceOf(msg.sender) > 0, "Only Mr. Crypto holders can mint");
		_;
	}

	event sale(address buyer, uint256 id, uint256 price);

	constructor(
		string memory uri_,
		address usdc,
		address mrc
	) ERC1155(uri_) DutchAuction(usdc, mrc) {
		addAdmin(msg.sender);
		setBaseURI(uri_);
	}

	function newAuction(uint256 timeInHours, uint256[3] memory auctionSupplies_) public onlyOwner {
		if (auction == false)
			auction = true;
		startAuction(timeInHours, auctionSupplies_);
	}

	function stopAuction() public onlyAdmin {
		auction = false;
	}

	//Note: Mint using USDC
	function mint(uint256 id) public isNotPaused onlyHolder {
		require(totalSupply(id) < tickets[id].maxSupply, "There are no tokens left in this id");
		require(balanceOf(msg.sender, id) < maxPerWallet, "You have reached max amount in this wallet");

		if (auction == true) {
			require(whitelist[msg.sender] == true, "You are not whitelisted");
			require(block.timestamp < finishTimestamp, "Auction has finished");
			require(totalSupply(id) < auctionSupplies[id], "This id has been sold in this auction");
		}

		if (msg.sender != owner())
			USDC.transferFrom(msg.sender, address(this), getPrice(id));
		_mint(msg.sender, id, 1, "");
		emit sale(msg.sender, id, getPrice(id));
	}

	function playPause() public onlyAdmin {
		paused = !paused;
	}

	function isWhitelisted(address user) public view returns (bool) {
		return whitelist[user];
	}

	function switchTransferible() public onlyOwner {
		transferible = !transferible;
	}

	function addAdmin(address new_) public onlyOwner {
		isAdmin[new_] = true;
	}

	function removeAdmin(address new_) public onlyOwner {
		isAdmin[new_] = false;
	}

	function addToWhitelist(address[] memory newOnes) public onlyAdmin {
		for (uint256 i = 0; i < newOnes.length; ++i)
			whitelist[newOnes[i]] = true;
	}

	function removeFromWhitelist(address[] memory newOnes) public onlyAdmin {
		for (uint256 i = 0; i < newOnes.length; ++i)
			whitelist[newOnes[i]] = false;
	}

	function uri(uint256 _id) public view override returns (string memory) {
		require(exists(_id), "URI: nonexistent token");
		return string(abi.encodePacked(baseURI, "/", Strings.toString(_id), ".json"));
	}

	function setBaseURI(string memory _uri) public onlyAdmin {
		baseURI = _uri;
	}

	function royaltyInfo(uint256 tokenId, uint256 salePrice)
		external
		view
		returns (address receiver, uint256 royaltyAmount)
	{
		royaltyAmount = (salePrice * royalties[tokenId]) / 100;
		return (royaltyWallet, royaltyAmount);
	}

	function setRoyaltyInfo(uint256[3] memory royalties_, address royaltyWallet_) external onlyOwner {
		royalties = royalties_;
		royaltyWallet = royaltyWallet_;
	}

	function withdraw() public onlyOwner {
		USDC.transfer(owner(), USDC.balanceOf(address(this)));
	}

	//FUNCTION OVERRIDING

	function safeTransferFrom(
		address from,
		address to,
		uint256 id,
		uint256 amount,
		bytes memory data
	) public virtual override isTransferible {
		require(
			from == _msgSender() || isApprovedForAll(from, _msgSender()),
			"ERC1155: caller is not owner nor approved"
		);
		_safeTransferFrom(from, to, id, amount, data);
	}

	function safeBatchTransferFrom(
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) public virtual override isTransferible {
		require(
			from == _msgSender() || isApprovedForAll(from, _msgSender()),
			"ERC1155: transfer caller is not owner nor approved"
		);
		_safeBatchTransferFrom(from, to, ids, amounts, data);
	}

	receive() external payable {}
}

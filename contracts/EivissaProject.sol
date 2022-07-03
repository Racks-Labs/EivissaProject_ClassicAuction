//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Auction.sol";
import "./Sale.sol";
import "./IMRC.sol";

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
	uint256[3] public maxSupplies;
	uint256[3] public minPrices;
	mapping(address => bool) public whitelist;
	mapping(address => bool) public isAdmin;
	Sale[] public sales;
	Auction[] public auctions;
	string public baseURI;
	IMRC mrc;
	IERC20 usd;
	uint256[3] royalties;
	address royaltyWallet;

	modifier isNotPaused() {
		if (isAdmin[msg.sender] == false)
			require(paused == false, "Contract is paused");
		_;
	}

	modifier isWhitelisted() {
		require(whitelist[msg.sender] == true);
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

	event mintEvent(address buyer, uint256 id, uint256 price);

	constructor(
		string memory uri_,
		IERC20 usd_,
		IMRC mrc_,
		uint256[3] memory maxSupplies_,
		uint256[3] memory minPrices_
	) ERC1155(uri_) {
		usd = usd_;
		mrc = mrc_;
		maxSupplies = maxSupplies_;
		minPrices = minPrices_;
		isAdmin[msg.sender] = true;
		whitelist[msg.sender] = true;
		setBaseURI(uri_);
	}

	//Note: Mint using USDC
	function mint(address to, uint256 id, uint256 price) public isNotPaused isWhitelisted {
		require(totalSupply(id) < maxSupplies[id], "There are no tokens left in this id");
		_mint(to, id, 1, "");
		emit mintEvent(to, id, price);
	}

	function newSale(uint256[3] memory supplies, string memory name) public onlyAdmin returns(address) {
		for (uint256 i = 0; i < 3; ++i)
			require(totalSupply(i) + supplies[i] <= maxSupplies[i], "One of the parameters exceds the requirements");
		Sale sale = new Sale(this, supplies, minPrices, name, mrc, usd, owner());
		sales.push(sale);
		whitelist[address(sale)] = true;
		return address(sale);
	}

	function newAuction(uint256[3] memory supplies, string memory name) public onlyAdmin returns(address) {
		for (uint256 i = 0; i < 3; ++i)
			require(totalSupply(i) + supplies[i] <= maxSupplies[i], "One of the parameters exceds the requirements");
		Auction auction = new Auction(this, supplies, minPrices, name, mrc, usd, owner());
		auctions.push(auction);
		whitelist[address(auction)] = true;
		return address(auction);
	}

	function finishSale(uint256 index) public onlyAdmin {
		sales[index].finish();
	}

	function finishAuction(uint256 index) public onlyAdmin {
		auctions[index].finish();
	}

	function currentSales() public view returns(uint256) {
		return sales.length;
	}

	function currentAuctions() public view returns(uint256) {
		return auctions.length;
	}

	function playPause() public onlyAdmin {
		paused = !paused;
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

	function setMaxSupplies(uint256[3] memory maxSupplies_) external onlyOwner {
		maxSupplies = maxSupplies_;
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
		usd.transfer(owner(), usd.balanceOf(address(this)));
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

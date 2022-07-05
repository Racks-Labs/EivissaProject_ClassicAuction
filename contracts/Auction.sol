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
	/* uint256[3] public maxSupplies;
	uint256[3] public minPrices;
	IMRC mrc;
	IERC20 usd;
	string public name;
	bool public paused = true;
	bool public whitelistEnabled = true;
	bool public finished = false;
	mapping(address => bool) public isAdmin;
	mapping(address => bool) public whitelist; */
	mapping(address => uint256[3]) claimable;
	//IEivissaProject eivissa;

	/* modifier isNotPaused() {
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
	} */

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
					newAdmin) {
		/* eivissa = eivissa_;
		maxSupplies = maxSupplies_;
		minPrices = minPrices_;
		mrc = mrc_;
		usd = usd_;
		name = name_;
		isAdmin[address(eivissa)] = true;
		isAdmin[newAdmin] = true; */
	}

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

	/* function playPause() public onlyAdmin {
		paused = !paused;
	}

	function finish() public onlyAdmin {
		finished = !finished;
		usd.transfer(address(eivissa), usd.balanceOf(address(this)));
	} */

	function claim(uint256 id) public {
		uint256 claimableNum = claimable[msg.sender][id];

		require(finished == true, "Not finished");
		require(claimableNum > 0, "No left");
		claimable[msg.sender][id] = 0;
		eivissa.mint(msg.sender, id, claimableNum);
	}

	/* function addAdmin(address[] memory newOnes) public onlyAdmin {
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
	} */

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
			uint256 increment = (bidders[id][bidders.length - 1].amount * 5 / 100);
			minPrices[id] = bidders[id][bidders.length - 1].amount + increment;
			claimable[tmp.wallet][id] -= 1;
			usd.transfer(tmp.wallet, tmp.amount);
		}
	}

	//receive() external payable {}
}

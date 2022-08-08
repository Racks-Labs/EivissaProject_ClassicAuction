# EIVISSA PROJECT OPTIMIZATION

# Gas Report Comparation

<!-- ![plot](./Gas%20Report/EIVISSA%20PREVIOUS%20GAS%20REPORT.png)
![plot](./Gas%20Report/EIVISSA%20IMPROVED%20GAS%20REPORT.png) -->
<img src="Gas Report/EIVISSA PREVIOUS GAS REPORT.png" width="300"/>
<img src="Gas Report/EIVISSA IMPROVED GAS REPORT.png" width="300"/>


# Static Analisys with Slither

```shell
npx run slither
```
## Reporte:

<span style="color:red;">
Auction.bid(uint256,uint256) (contracts/Auction.sol#31-39) ignores return value by usd.transferFrom(msg.sender,address(this),price) (contracts/Auction.sol#36)
Auction.addBidder(address,uint256,uint256) (contracts/Auction.sol#63-89) ignores return value by usd.transfer(tmp.wallet,tmp.amount) (contracts/Auction.sol#82)
EivissaProject.withdraw() (contracts/EivissaProject.sol#175-179) ignores return value by usd.transfer(owner(),usd.balanceOf(address(this))) (contracts/EivissaProject.sol#176)
Sale.buy(uint256) (contracts/Sale.sol#30-41) ignores return value by usd.transferFrom(msg.sender,address(eivissa),minPrices[id]) (contracts/Sale.sol#35)
System.finish() (contracts/System.sol#69-72) ignores return value by usd.transfer(address(eivissa),usd.balanceOf(address(this))) (contracts/System.sol#71)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#unchecked-transfer
</span>

<span style="color:yellow;">
System.onlyHolder() (contracts/System.sol#40-44) uses a dangerous strict equality:
</span>
        - mrc.balanceOf(msg.sender) == 0 && isAdmin[msg.sender] == false 
		(contracts/System.sol#41)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#dangerous-strict-equalities
<span style="color:yellow;">
Reentrancy in Auction.bid(uint256,uint256) (contracts/Auction.sol#31-39):
</span>
        External calls:
        - usd.transferFrom(msg.sender,address(this),price) (contracts/Auction.sol#36)
        - addBidder(msg.sender,price,id) (contracts/Auction.sol#37)
                - usd.transfer(tmp.wallet,tmp.amount) (contracts/Auction.sol#82)
        State variables written after the call(s):
        - addBidder(msg.sender,price,id) (contracts/Auction.sol#37)
                - minPrices[id] = bidders[id][bidders[id].length - 1].amount + increment (contracts/Auction.sol#87)
<span style="color:yellow;">
Reentrancy in Sale.buy(uint256) (contracts/Sale.sol#30-41):
</span>
        External calls:
        - usd.transferFrom(msg.sender,address(eivissa),minPrices[id]) (contracts/Sale.sol#35)
        State variables written after the call(s):
        - ++ (currentSupply[id]) (contracts/Sale.sol#36)
        - userMints[msg.sender] = true (contracts/Sale.sol#38)
<span style="color:yellow;">
Reentrancy in MRCRYPTO.reservedMint(uint256) (contracts/mock/MRC.sol#96-118):
</span>
        External calls:
        - _safeMint(msg.sender,supply + 1) (contracts/mock/MRC.sol#109)
                - IERC721Receiver(to).onERC721Received(_msgSender(),from,tokenId,data) (node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol#401-412)
        State variables written after the call(s):
        - reservedMints[_tokenId] = true (contracts/mock/MRC.sol#110)
<span style="color:yellow;">
Reentrancy in MRCRYPTO.reservedMint(uint256) (contracts/mock/MRC.sol#96-118):
</span>
        External calls:
        - _safeMint(msg.sender,supply + 1) (contracts/mock/MRC.sol#115)
                - IERC721Receiver(to).onERC721Received(_msgSender(),from,tokenId,data) (node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol#401-412)
        State variables written after the call(s):
        - reservedMints[_tokenId] = true (contracts/mock/MRC.sol#116)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities-1

<span style="color:green;">
EivissaProject.setBaseURI(string)._uri (contracts/EivissaProject.sol#149) shadows:
</span>
        - ERC1155._uri (node_modules/@openzeppelin/contracts/token/ERC1155/ERC1155.sol#30) (state variable)
<span style="color:green;">
EivissaProject.setRoyaltyInfo(uint256[3],address).royaltyWallet_ (contracts/EivissaProject.sol#170) lacks a zero-check on :
</span>
                - royaltyWallet = royaltyWallet_ (contracts/EivissaProject.sol#172)
<span style="color:green;">
Reentrancy in Auction.addBidder(address,uint256,uint256) (contracts/Auction.sol#63-89):
</span>
        External calls:
        - usd.transfer(tmp.wallet,tmp.amount) (contracts/Auction.sol#82)
        State variables written after the call(s):
        - minPrices[id] = bidders[id][bidders[id].length - 1].amount + increment (contracts/Auction.sol#87)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities-2
<span style="color:green;">
Reentrancy in Auction.bid(uint256,uint256) (contracts/Auction.sol#31-39):
</span>
        External calls:
        - usd.transferFrom(msg.sender,address(this),price) (contracts/Auction.sol#36)
        - addBidder(msg.sender,price,id) (contracts/Auction.sol#37)
                - usd.transfer(tmp.wallet,tmp.amount) (contracts/Auction.sol#82)
        Event emitted after the call(s):
        - auctionEvent(msg.sender,id,price) (contracts/Auction.sol#38)
<span style="color:green;">
Reentrancy in Sale.buy(uint256) (contracts/Sale.sol#30-41):
</span>
        External calls:
        - usd.transferFrom(msg.sender,address(eivissa),minPrices[id]) (contracts/Sale.sol#35)
        - eivissa.mint(msg.sender,id,1) (contracts/Sale.sol#39)
        Event emitted after the call(s):
        - saleEvent(msg.sender,id) (contracts/Sale.sol#40)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities-3

<span style="color:green;">
Auction.bid(uint256,uint256) (contracts/Auction.sol#31-39) compares to a boolean constant:
        -require(bool,string)(finished == false,Has finished) (contracts/Auction.sol#32)
Auction.claim(uint256) (contracts/Auction.sol#52-59) compares to a boolean constant:
        -require(bool,string)(finished == true,Not finished) (contracts/Auction.sol#55)
Auction.addBidder(address,uint256,uint256) (contracts/Auction.sol#63-89) compares to a boolean constant:
        -(newEntered == false && tmp.amount > bidders[id][i].amount) || (newEntered == true && tmp.amount >= bidders[id][i].amount) (contracts/Auction.sol#69-70)
EivissaProject.isNotPaused() (contracts/EivissaProject.sol#43-46) compares to a boolean constant:
        -isAdmin[msg.sender] == false && paused == true (contracts/EivissaProject.sol#44)
EivissaProject.isWhitelisted() (contracts/EivissaProject.sol#48-51) compares to a boolean constant:
        -whitelist[msg.sender] == false (contracts/EivissaProject.sol#49)
EivissaProject.isTransferible() (contracts/EivissaProject.sol#53-56) compares to a boolean constant:
        -transferible == false || isCollab[msg.sender] == true (contracts/EivissaProject.sol#54)
EivissaProject.onlyAdmin() (contracts/EivissaProject.sol#58-61) compares to a boolean constant:
        -isAdmin[msg.sender] == false (contracts/EivissaProject.sol#59)
Sale.buy(uint256) (contracts/Sale.sol#30-41) compares to a boolean constant:
        -require(bool)(userMints[msg.sender] == false) (contracts/Sale.sol#33)
System.isNotPaused() (contracts/System.sol#22-26) compares to a boolean constant:
        -isAdmin[msg.sender] == false && paused == true (contracts/System.sol#23)
System.onlyAdmin() (contracts/System.sol#28-32) compares to a boolean constant:
        -isAdmin[msg.sender] == false (contracts/System.sol#29)
System.isWhitelisted() (contracts/System.sol#34-38) compares to a boolean constant:
        -whitelistEnabled == true && whitelist[msg.sender] == false (contracts/System.sol#35)
System.onlyHolder() (contracts/System.sol#40-44) compares to a boolean constant:
        -mrc.balanceOf(msg.sender) == 0 && isAdmin[msg.sender] == false (contracts/System.sol#41)
MRCRYPTO.reservedMint(uint256) (contracts/mock/MRC.sol#96-118) compares to a boolean constant:
        -require(bool,string)(reservedMints[_tokenId] == false,Token alredy used to mint at reserved price) (contracts/mock/MRC.sol#103)
MRCRYPTO.tokenURI(uint256) (contracts/mock/MRC.sol#150-156) compares to a boolean constant:
        -revealed == false && tokenId > previousMaxSupply (contracts/mock/MRC.sol#153)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#boolean-equality
</span>

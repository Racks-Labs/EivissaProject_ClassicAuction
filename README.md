# EIVISSA PROJECT OPTIMIZATION

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
<span style="color:yellow;">
MRCRYPTO.walletOfOwner(address).i (contracts/mock/MRC.sol#140) is a local variable never initialized
</span>  
```shell
ERC1155._doSafeTransferAcceptanceCheck(address,address,address,uint256,uint256,bytes).response (node_modules/@openzeppelin/contracts/token/ERC1155/ERC1155.sol#476) is a local variable never initialized

ERC1155._doSafeBatchTransferAcceptanceCheck(address,address,address,uint256[],uint256[],bytes).reason (node_modules/@openzeppelin/contracts/token/ERC1155/ERC1155.sol#503) is a local variable never initialized

ERC1155._doSafeTransferAcceptanceCheck(address,address,address,uint256,uint256,bytes).reason (node_modules/@openzeppelin/contracts/token/ERC1155/ERC1155.sol#480) is a local variable never initialized

ERC1155._doSafeBatchTransferAcceptanceCheck(address,address,address,uint256[],uint256[],bytes).response (node_modules/@openzeppelin/contracts/token/ERC1155/ERC1155.sol#498) is a local variable never initialized

Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#uninitialized-local-variables

ERC1155._doSafeTransferAcceptanceCheck(address,address,address,uint256,uint256,bytes) (node_modules/@openzeppelin/contracts/token/ERC1155/ERC1155.sol#467-486) ignores return value by

IERC1155Receiver(to).onERC1155Received(operator,from,id,amount,data) (node_modules/@openzeppelin/contracts/token/ERC1155/ERC1155.sol#476-484)
ERC1155._doSafeBatchTransferAcceptanceCheck(address,address,address,uint256[],uint256[],bytes) (node_modules/@openzeppelin/contracts/token/ERC1155/ERC1155.sol#488-509) ignores return value by

IERC1155Receiver(to).onERC1155BatchReceived(operator,from,ids,amounts,data) (node_modules/@openzeppelin/contracts/token/ERC1155/ERC1155.sol#497-507)

ERC721._checkOnERC721Received(address,address,uint256,bytes) (node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol#394-416) ignores return value by IERC721Receiver(to).onERC721Received(_msgSender(),from,tokenId,data) (node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol#401-412)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#unused-return
```

<span style="color:green;">
EivissaProject.setBaseURI(string)._uri (contracts/EivissaProject.sol#149) shadows:
</span>
        - ERC1155._uri (node_modules/@openzeppelin/contracts/token/ERC1155/ERC1155.sol#30) (state variable)
<span style="color:green;">
MockErc20.constructor(string,string)._name (contracts/mock/Erc20.sol#7) shadows:
</span>
        - ERC20._name (node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#42) (state variable)
<span style="color:green;">
MockErc20.constructor(string,string)._symbol (contracts/mock/Erc20.sol#7) shadows:
</span>
        - ERC20._symbol (node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#43) (state variable)
<span style="color:green;">
MRCRYPTO.constructor(string,string,string,string)._name (contracts/mock/MRC.sol#45) shadows:
</span>
        - ERC721._name (node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol#24) (state variable)
<span style="color:green;">
MRCRYPTO.constructor(string,string,string,string)._symbol (contracts/mock/MRC.sol#46) shadows:
</span>
        - ERC721._symbol (node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol#27) (state variable)
<span style="color:green;">
MRCRYPTO.walletOfOwner(address)._owner (contracts/mock/MRC.sol#137) shadows:
</span>
        - Ownable._owner (node_modules/@openzeppelin/contracts/access/Ownable.sol#21) (state variable)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#local-variable-shadowing
<span style="color:green;">
EivissaProject.setRoyaltyInfo(uint256[3],address).royaltyWallet_ (contracts/EivissaProject.sol#170) lacks a zero-check on :
</span>
                - royaltyWallet = royaltyWallet_ (contracts/EivissaProject.sol#172)
<span style="color:green;">
MRCRYPTO.changeLiquidity(address)._new (contracts/mock/MRC.sol#225) lacks a zero-check on :
</span>
                - liquidity = _new (contracts/mock/MRC.sol#226)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#missing-zero-address-validation

ERC721._checkOnERC721Received(address,address,uint256,bytes) (node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol#394-416) has external calls inside a loop: IERC721Receiver(to).onERC721Received(_msgSender(),from,tokenId,data) (node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol#401-412)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation/#calls-inside-a-loop
<span style="color:green;">
Variable 'ERC1155._doSafeTransferAcceptanceCheck(address,address,address,uint256,uint256,bytes).response (node_modules/@openzeppelin/contracts/token/ERC1155/ERC1155.sol#476)' in ERC1155._doSafeTransferAcceptanceCheck(address,address,address,uint256,uint256,bytes) (node_modules/@openzeppelin/contracts/token/ERC1155/ERC1155.sol#467-486) potentially used before declaration: response != IERC1155Receiver.onERC1155Received.selector (node_modules/@openzeppelin/contracts/token/ERC1155/ERC1155.sol#477)
Variable 'ERC1155._doSafeTransferAcceptanceCheck(address,address,address,uint256,uint256,bytes).reason (node_modules/@openzeppelin/contracts/token/ERC1155/ERC1155.sol#480)' in ERC1155._doSafeTransferAcceptanceCheck(address,address,address,uint256,uint256,bytes) (node_modules/@openzeppelin/contracts/token/ERC1155/ERC1155.sol#467-486) potentially used before declaration: revert(string)(reason) (node_modules/@openzeppelin/contracts/token/ERC1155/ERC1155.sol#481)
Variable 'ERC1155._doSafeBatchTransferAcceptanceCheck(address,address,address,uint256[],uint256[],bytes).response (node_modules/@openzeppelin/contracts/token/ERC1155/ERC1155.sol#498)' in ERC1155._doSafeBatchTransferAcceptanceCheck(address,address,address,uint256[],uint256[],bytes) (node_modules/@openzeppelin/contracts/token/ERC1155/ERC1155.sol#488-509) potentially used before declaration: response != IERC1155Receiver.onERC1155BatchReceived.selector (node_modules/@openzeppelin/contracts/token/ERC1155/ERC1155.sol#500)
Variable 'ERC1155._doSafeBatchTransferAcceptanceCheck(address,address,address,uint256[],uint256[],bytes).reason (node_modules/@openzeppelin/contracts/token/ERC1155/ERC1155.sol#503)' in ERC1155._doSafeBatchTransferAcceptanceCheck(address,address,address,uint256[],uint256[],bytes) (node_modules/@openzeppelin/contracts/token/ERC1155/ERC1155.sol#488-509) potentially used before declaration: revert(string)(reason) (node_modules/@openzeppelin/contracts/token/ERC1155/ERC1155.sol#504)
Variable 'ERC721._checkOnERC721Received(address,address,uint256,bytes).retval (node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol#401)' in ERC721._checkOnERC721Received(address,address,uint256,bytes) (node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol#394-416) potentially used before declaration: retval == IERC721Receiver.onERC721Received.selector (node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol#402)
Variable 'ERC721._checkOnERC721Received(address,address,uint256,bytes).reason (node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol#403)' in ERC721._checkOnERC721Received(address,address,uint256,bytes) (node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol#394-416) potentially used before declaration: reason.length == 0 (node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol#404)
Variable 'ERC721._checkOnERC721Received(address,address,uint256,bytes).reason (node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol#403)' in ERC721._checkOnERC721Received(address,address,uint256,bytes) (node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol#394-416) potentially used before declaration: revert(uint256,uint256)(32 + reason,mload(uint256)(reason)) (node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol#409)  
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#pre-declaration-usage-of-local-variables
</span>
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
ERC721._checkOnERC721Received(address,address,uint256,bytes) (node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol#394-416) uses assembly
</span>
        - INLINE ASM (node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol#408-410)
<span style="color:green;">
Address.verifyCallResult(bool,bytes,string) (node_modules/@openzeppelin/contracts/utils/Address.sol#201-221) uses assembly
</span>
        - INLINE ASM (node_modules/@openzeppelin/contracts/utils/Address.sol#213-216)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#assembly-usage
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
<span style="color:green;">
Different versions of Solidity are used:
</span>
        - Version used: ['>=0.7.0<0.9.0', '^0.8.0', '^0.8.1', '^0.8.7']
        - ^0.8.0 (node_modules/@openzeppelin/contracts/access/Ownable.sol#4)
        - ^0.8.0 (node_modules/@openzeppelin/contracts/token/ERC1155/ERC1155.sol#4)
        - ^0.8.0 (node_modules/@openzeppelin/contracts/token/ERC1155/IERC1155.sol#4)
        - ^0.8.0 (node_modules/@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol#4)
        - ^0.8.0 (node_modules/@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol#4)
        - ^0.8.0 (node_modules/@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol#4)
        - ^0.8.0 (node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#4)
        - ^0.8.0 (node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol#4)
        - ^0.8.0 (node_modules/@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol#4)
        - ^0.8.0 (node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol#4)
        - ^0.8.0 (node_modules/@openzeppelin/contracts/token/ERC721/IERC721.sol#4)
        - ^0.8.0 (node_modules/@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol#4)
        - ^0.8.0 (node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol#4)
        - ^0.8.0 (node_modules/@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol#4)
        - ^0.8.0 (node_modules/@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol#4)
        - ^0.8.1 (node_modules/@openzeppelin/contracts/utils/Address.sol#4)
        - ^0.8.0 (node_modules/@openzeppelin/contracts/utils/Context.sol#4)
        - ^0.8.0 (node_modules/@openzeppelin/contracts/utils/Strings.sol#4)
        - ^0.8.0 (node_modules/@openzeppelin/contracts/utils/introspection/ERC165.sol#4)
        - ^0.8.0 (node_modules/@openzeppelin/contracts/utils/introspection/IERC165.sol#4)
        - ^0.8.7 (contracts/Auction.sol#2)
        - ^0.8.7 (contracts/Bidder.sol#2)
        - ^0.8.7 (contracts/EivissaProject.sol#2)
        - ^0.8.7 (contracts/Err.sol#2)
        - ^0.8.7 (contracts/IEivissaProject.sol#2)
        - ^0.8.7 (contracts/IMRC.sol#2)
        - ^0.8.7 (contracts/Sale.sol#2)
        - ^0.8.7 (contracts/System.sol#2)
        - ^0.8.7 (contracts/mock/Erc20.sol#2)
        - >=0.7.0<0.9.0 (contracts/mock/MRC.sol#17)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#different-pragma-directives-are-used
<span style="color:green;">
ERC721Enumerable._removeTokenFromAllTokensEnumeration(uint256) (node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol#144-162) has costly operations inside a loop:
</span>
        - delete _allTokensIndex[tokenId] (node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol#160)
<span style="color:green;">
ERC721Enumerable._removeTokenFromAllTokensEnumeration(uint256) (node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol#144-162) has costly operations inside a loop:
</span>
        - _allTokens.pop() (node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol#161)
<span style="color:green;">
ERC721Enumerable._removeTokenFromOwnerEnumeration(address,uint256) (node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol#119-137) has costly operations inside a loop:
</span>
        - delete _ownedTokensIndex[tokenId] (node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol#135)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#costly-operations-inside-a-loop
<span style="color:green;">
MRCRYPTO._baseURI() (contracts/mock/MRC.sol#75-77) is never used and should be removed
MRCRYPTO.checkPhase(uint256) (contracts/mock/MRC.sol#131-135) is never used and should be removed
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#dead-code
</span>
<span style="color:green;">
Pragma version^0.8.0 (node_modules/@openzeppelin/contracts/access/Ownable.sol#4) allows old versions
Pragma version^0.8.0 (node_modules/@openzeppelin/contracts/token/ERC1155/ERC1155.sol#4) allows old versions
Pragma version^0.8.0 (node_modules/@openzeppelin/contracts/token/ERC1155/IERC1155.sol#4) allows old versions
Pragma version^0.8.0 (node_modules/@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol#4) allows old versions
Pragma version^0.8.0 (node_modules/@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol#4) allows old versions
Pragma version^0.8.0 (node_modules/@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol#4) allows old versions
Pragma version^0.8.0 (node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#4) allows old versions
Pragma version^0.8.0 (node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol#4) allows old versions
Pragma version^0.8.0 (node_modules/@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol#4) allows old versions
Pragma version^0.8.0 (node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol#4) allows old versions
Pragma version^0.8.0 (node_modules/@openzeppelin/contracts/token/ERC721/IERC721.sol#4) allows old versions
Pragma version^0.8.0 (node_modules/@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol#4) allows old versions
Pragma version^0.8.0 (node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol#4) allows old versions
Pragma version^0.8.0 (node_modules/@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol#4) allows old versions
Pragma version^0.8.0 (node_modules/@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol#4) allows old versions
Pragma version^0.8.1 (node_modules/@openzeppelin/contracts/utils/Address.sol#4) allows old versions
Pragma version^0.8.0 (node_modules/@openzeppelin/contracts/utils/Context.sol#4) allows old versions
Pragma version^0.8.0 (node_modules/@openzeppelin/contracts/utils/Strings.sol#4) allows old versions
Pragma version^0.8.0 (node_modules/@openzeppelin/contracts/utils/introspection/ERC165.sol#4) allows old versions
Pragma version^0.8.0 (node_modules/@openzeppelin/contracts/utils/introspection/IERC165.sol#4) allows old versions
Pragma version>=0.7.0<0.9.0 (contracts/mock/MRC.sol#17) is too complex
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#incorrect-versions-of-solidity
</span>
<span style="color:green;">
MRCRYPTO (contracts/mock/MRC.sol#22-228) should inherit from IMRC (contracts/IMRC.sol#6-8)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#missing-inheritance
</span>
<span style="color:green;">
MockErc20.constructor(string,string) (contracts/mock/Erc20.sol#7-9) uses literals with too many digits:
</span>
        - _mint(msg.sender,100000000000) (contracts/mock/Erc20.sol#8)
<span style="color:green;">
MockErc20.mintMore() (contracts/mock/Erc20.sol#11-13) uses literals with too many digits:
</span>
        - _mint(msg.sender,10000000000) (contracts/mock/Erc20.sol#12)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#too-many-digits
<span style="color:green;">
MRCRYPTO.lockExt (contracts/mock/MRC.sol#37) should be constant
MRCRYPTO.lockURI (contracts/mock/MRC.sol#36) should be constant
MRCRYPTO.totalMaxSupply (contracts/mock/MRC.sol#29) should be constant
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#state-variables-that-could-be-declared-constant
</span>
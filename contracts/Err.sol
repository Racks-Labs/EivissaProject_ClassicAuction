//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

error pausedErr();
error whitelistErr();
error transferibleErr();
error adminErr();
error holderErr();
error usdTransferFailed();
error withdrawFailed();
error auctionFinished();
error auctionNoClaimableLeft();
error invalidIndex();
error invalidPrice();
error nonexistentTokenURI();
error noTokensLeftErr(uint256 totalSupply, uint256 maxSupply);
error ERC1155CallerNotOwnerNorApproved(address caller);

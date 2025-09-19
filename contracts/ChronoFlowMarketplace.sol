// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title ChronoFlowMarketplace
 * @author Gemini
 * @notice A simple marketplace to buy and sell StreamNFTs for the native coin.
 */
contract ChronoFlowMarketplace is ReentrancyGuard {
    IERC721 public streamNFT;

    struct Listing {
        address seller;
        uint256 price; // Price in native coin (wei)
    }

    mapping(uint256 => Listing) public listings;

    event Listed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event Sold(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 price);
    event Unlisted(uint256 indexed tokenId, address indexed seller);

    constructor(address _streamNFTAddress) {
        streamNFT = IERC721(_streamNFTAddress);
    }
    
    /**
     * @notice List an NFT for sale on the marketplace.
     * @param tokenId The ID of the StreamNFT to list.
     * @param price The selling price in wei.
     */
    function listNFT(uint256 tokenId, uint256 price) external {
        require(streamNFT.ownerOf(tokenId) == msg.sender, "Marketplace: You are not the owner");
        require(price > 0, "Marketplace: Price must be greater than zero");

        // The seller must approve the marketplace to transfer the NFT on their behalf
        require(streamNFT.getApproved(tokenId) == address(this), "Marketplace: Contract not approved to manage this NFT");

        listings[tokenId] = Listing(msg.sender, price);
        emit Listed(tokenId, msg.sender, price);
    }

    /**
     * @notice Unlist an NFT from the marketplace.
     * @param tokenId The ID of the StreamNFT to unlist.
     */
    function unlistNFT(uint256 tokenId) external {
        Listing storage listing = listings[tokenId];
        require(listing.seller == msg.sender, "Marketplace: You are not the seller");
        
        delete listings[tokenId];
        emit Unlisted(tokenId, msg.sender);
    }

    /**
     * @notice Buy a listed StreamNFT.
     * @param tokenId The ID of the StreamNFT to purchase.
     */
    function buyNFT(uint256 tokenId) external payable nonReentrant {
        Listing storage listing = listings[tokenId];
        require(listing.price > 0, "Marketplace: NFT not listed for sale");
        require(msg.value == listing.price, "Marketplace: Incorrect amount of funds sent");

        address seller = listing.seller;
        delete listings[tokenId]; // Remove listing before transfer to prevent re-entrancy issues

        // Transfer NFT from seller to buyer (msg.sender)
        streamNFT.safeTransferFrom(seller, msg.sender, tokenId);

        // Send payment to the seller
        (bool success, ) = seller.call{value: msg.value}("");
        require(success, "Marketplace: Payment to seller failed");

        emit Sold(tokenId, seller, msg.sender, msg.value);
    }
}
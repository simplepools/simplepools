pragma solidity ^0.8.17;
// SPDX-License-Identifier: GPL-3.0-or-later
// Simple Pools smart contract DeFi exchange.
// Copyright (C) 2023 Simple Pools

// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software 
// Foundation, either version 3 of the License, or (at your option) any later version.

// This program is distributed in the hope that it will be useful, but WITHOUT 
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
// FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

// You should have received a copy of the GNU General Public License along with this 
// program. If not, see <https://www.gnu.org/licenses/>.

/**
 * Simple Pools NFT Marketplace
 * https://simplepools.org/
 * DeFi made simple.
 */
interface IERC721Receiver {
    function onERC721Received(address,address,
            uint256, bytes calldata) external returns (bytes4);
}

interface IERC1155Receiver {
    function onERC1155BatchReceived(address, address, 
        uint256[] calldata, uint256[] calldata, bytes calldata
    ) external returns (bytes4);
}

/**
 * The marketplace contract.
 */
contract SimplePoolsNftMarketplace is IERC721Receiver, IERC1155Receiver {

    struct NftListing {
        uint256 listingId;
        address listingOwner;
        address nftContractAddress;
        NftType nftType;
        uint256[] tokenIds;
        uint256[] tokenAmounts; // in case of ERC1155 listing
        IERC20 erc20Token;
        uint256 highestBid; // only for offer nft listings
        uint256 buyoutPrice;
        address currentHighestBidder; // only for offer nft listings
        ListingStatus listingStatus;
        ListingType listingType;
    }

    enum ListingType {
        OFFER_NFT_FOR_ERC20,
        OFFER_ERC20_FOR_NFT
    }

    enum NftType {
        ERC721,
        ERC1155
    }

    // TODO In version 2 add listings for whole collections (IERC1155) where there is price set
    // for one token and users can buy only one token from the whole listing
    // for preset price (price can be set by the owner in the process).

    // TODO In version 2 add listings to exchange NFT for NFT

    enum ListingStatus { 
        IN_PROGRESS,
        FINISHED_WITH_BUYOUT,
        FINISHED_WITH_BID_ACCEPTED,
        FINISHED_CANCELLED
    }

    NftListing[] public _listings;
    uint256[] _allTransactionsListingIds;

    function onERC721Received(address, address,
            uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function onERC1155BatchReceived(address, address,
            uint256[] calldata, uint256[] calldata, bytes calldata
    ) external pure returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    function getListingsForTransactionsWithIndexesBetween(
            uint256 startTransactionIndex,
            uint256 endTransactionIndex
    ) external view returns (uint256[] memory) {
        require(endTransactionIndex > startTransactionIndex && 
                endTransactionIndex <= _allTransactionsListingIds.length, "invalid indexes");
        uint[] memory listingsIndexes = new uint[](endTransactionIndex - startTransactionIndex);
        for (uint i = startTransactionIndex; i < endTransactionIndex; ++i) {
            listingsIndexes[i - startTransactionIndex] = _allTransactionsListingIds[i];
        }
        return listingsIndexes;
    }

    function getListings(
            uint256 startListingIndex, 
            uint256 endListingIndex
    ) external view returns (NftListing[] memory) {
       require(endListingIndex > startListingIndex && endListingIndex <= _listings.length, "invalid indexes");
       NftListing[] memory listings = new NftListing[](endListingIndex - startListingIndex);
       for (uint i = startListingIndex; i < endListingIndex; ++i) {
            listings[i - startListingIndex] = _listings[i];
       }
       return listings;
    }

    function listNft(
        address nftContractAddress,
        NftType nftType,
        uint256[] calldata tokenIds,
        uint256[] calldata tokenAmounts, // used in case of ERC1155 listing otherwise it should be 1
        IERC20 erc20Token,
        uint256 startingPrice,
        uint256 buyoutPrice
    ) external {
        uint256 listingId =_listings.length;
        _allTransactionsListingIds.push(listingId);

        _listings.push().listingId = listingId;
        _listings[listingId].listingOwner = msg.sender;
        _listings[listingId].nftContractAddress = nftContractAddress;
        _listings[listingId].nftType = nftType;
        _listings[listingId].tokenIds = tokenIds;
        _listings[listingId].tokenAmounts = tokenAmounts;
        _listings[listingId].erc20Token = erc20Token;
        require(startingPrice >= 0, 'Invalid starting price. Only non-negative values.');
        _listings[listingId].highestBid = startingPrice;
        _listings[listingId].buyoutPrice = buyoutPrice;
        _listings[listingId].listingStatus = ListingStatus.IN_PROGRESS;
        _listings[listingId].listingType = ListingType.OFFER_NFT_FOR_ERC20;

        // transfer NFT from msg.sender to this contract
        _transferNft(
            _listings[listingId].nftContractAddress,
            msg.sender, address(this), 
            _listings[listingId].tokenIds,
            _listings[listingId].tokenAmounts, 
            _listings[listingId].nftType
        );
    }

    function listErc20(
        IERC20 erc20Token,
        uint256 offeredPrice,
        address nftContractAddress,
        NftType nftType,
        uint256[] calldata tokenIds,
        uint256[] calldata tokenAmounts // used in case of ERC1155 listing otherwise it should be 1
    ) external {
        uint256 listingId =_listings.length;
        _allTransactionsListingIds.push(listingId);
        
        _listings.push().listingId = listingId;
        _listings[listingId].listingOwner = msg.sender;
        _listings[listingId].nftContractAddress = nftContractAddress;
        _listings[listingId].nftType = nftType;
        _listings[listingId].tokenIds = tokenIds;
        _listings[listingId].tokenAmounts = tokenAmounts;
        _listings[listingId].erc20Token = erc20Token;
        _listings[listingId].buyoutPrice = offeredPrice;
        _listings[listingId].currentHighestBidder = address(0);

        _listings[listingId].listingStatus = ListingStatus.IN_PROGRESS;
        _listings[listingId].listingType = ListingType.OFFER_ERC20_FOR_NFT;

        // transfer ERC20 from msg.sender to this contract
        IERC20(erc20Token).transferFrom(msg.sender, address(this), offeredPrice);
    }

    function buyoutErc20(uint256 listingId) external {
        _allTransactionsListingIds.push(listingId);
        NftListing storage listing = _listings[listingId];
        require (listing.listingType == ListingType.OFFER_ERC20_FOR_NFT,
            "buyoutErc20 supports only listings that offer ERC20 for NFT");
        require (listing.listingStatus == ListingStatus.IN_PROGRESS,
            "This NFT listing is finished");
        // Transfer the requested NFT to listing owner.
        _transferNft(listing.nftContractAddress,
            msg.sender, listing.listingOwner, listing.tokenIds,
            listing.tokenAmounts, listing.nftType);

        // Transfer the offered ERC20 to msg.sender
        IERC20(listing.erc20Token)
            .transferFrom(address(this), msg.sender, listing.buyoutPrice);

        listing.listingStatus = ListingStatus.FINISHED_WITH_BUYOUT;
    }

    function buyoutNft(
        uint256 listingId
    ) external {
        _allTransactionsListingIds.push(listingId);
        NftListing storage listing = _listings[listingId];
        require (listing.listingType == ListingType.OFFER_NFT_FOR_ERC20,
                "buyoutNft supports only listings that offer NFT for ERC20");
        require (listing.listingStatus == ListingStatus.IN_PROGRESS,
            "This NFT listing is finished");
        // Transfer current highest bid to the current highest bidder.
        if (listing.currentHighestBidder != address(0)) {
            IERC20(listing.erc20Token)
                .transferFrom(address(this), listing.currentHighestBidder, 
                    listing.highestBid);
        }

        // Try to transfer the money from msg.sender to the listing owner.
        IERC20(listing.erc20Token)
            .transferFrom(
                msg.sender, 
                listing.listingOwner,
                listing.buyoutPrice
            );
        // Try to transfer the NFT to the msg.sender
        _transferNft(listing.nftContractAddress,
            address(this), msg.sender, listing.tokenIds,
            listing.tokenAmounts, listing.nftType);
        listing.listingStatus = ListingStatus.FINISHED_WITH_BUYOUT;
    }

    function bidOnNft(uint256 listingId, uint256 bidAmount) external {
        _allTransactionsListingIds.push(listingId);
        NftListing storage listing = _listings[listingId];
        require (listing.listingType == ListingType.OFFER_NFT_FOR_ERC20,
             "bitOnNft supports only listings that offer NFT for ERC20");
        require (listing.listingStatus == ListingStatus.IN_PROGRESS,
             "This NFT listing is finished");
        require(bidAmount > listing.highestBid,
             "The bidAmount must be higher than startingPrice or currentHighestBid");
        // Transfer old highest bid to the old highest bidder.
        if (listing.currentHighestBidder != address(0)) {
            IERC20(listing.erc20Token)
                .transferFrom(address(this), listing.currentHighestBidder, 
                    listing.highestBid);
        }
        // Transfer the bid to the contract
        IERC20(listing.erc20Token)
            .transferFrom(msg.sender, address(this), bidAmount);
        listing.highestBid = bidAmount;
        listing.currentHighestBidder = msg.sender;
    }

    function acceptBidOnNft(uint256 listingId) external {
        _allTransactionsListingIds.push(listingId);
        NftListing storage listing = _listings[listingId];
        require (listing.listingType == ListingType.OFFER_NFT_FOR_ERC20,
            "acceptBidOnNft supports only listings that offer ECR20 for NFT");
        require(listing.listingStatus == ListingStatus.IN_PROGRESS,
            "This NFT listing is finished");
        require(listing.listingOwner == msg.sender, 
            "Only the listing owner can accept bids.");
        require(listing.currentHighestBidder != address(0),
            "There is no bid on the listing.");
        // Transfer current highest bid to listing owner
        IERC20(listing.erc20Token)
            .transferFrom(address(this), listing.listingOwner, listing.highestBid);

        // Transfer NFT to msg.sender
        _transferNft(listing.nftContractAddress,
            address(this), listing.currentHighestBidder,
            listing.tokenIds, listing.tokenAmounts, listing.nftType);

        listing.listingStatus = ListingStatus.FINISHED_WITH_BID_ACCEPTED;
    }

    function cancelListingErcForNft(uint256 listingId) external {
        _allTransactionsListingIds.push(listingId);
        NftListing storage listing = _listings[listingId];
        require (listing.listingType == ListingType.OFFER_ERC20_FOR_NFT,
            "cancelListing supports only listings that offer ERC20 for NFT");
        require(listing.listingStatus == ListingStatus.IN_PROGRESS,
            "This NFT listing is finished");
        require(listing.listingOwner == msg.sender, 
            "Only the listing owner can cancel listings.");
        // Return the money to the listing owner
        IERC20(listing.erc20Token)
            .transferFrom(address(this), listing.listingOwner, listing.buyoutPrice);

        listing.listingStatus = ListingStatus.FINISHED_CANCELLED;
    }

    function cancelListingNftForErc(uint256 listingId) external {
        _allTransactionsListingIds.push(listingId);
        NftListing storage listing = _listings[listingId];
        require (listing.listingType == ListingType.OFFER_NFT_FOR_ERC20,
            "cancelListing supports only listings that offer ECR20 for NFT");
        require(listing.listingStatus == ListingStatus.IN_PROGRESS,
            "This NFT listing is finished");
        require(listing.listingOwner == msg.sender, 
            "Only the listing owner can cancel listings");
        // Return the money to current highest bidder
        if (listing.currentHighestBidder != address(0)) {
            IERC20(listing.erc20Token)
                .transferFrom(address(this), listing.currentHighestBidder, listing.highestBid);
        }
        _transferNft(listing.nftContractAddress, 
                address(this), msg.sender, listing.tokenIds, 
                listing.tokenAmounts, listing.nftType);
        listing.listingStatus = ListingStatus.FINISHED_CANCELLED;
    }

    function _transferNft(address nftContractAddress,
        address from,
        address to,
        uint256[] storage tokenIds,
        uint256[] storage tokenAmounts,
        NftType nftType
    ) private {
        if (nftType == NftType.ERC721) {
            for (uint i = 0; i < tokenIds.length; ++i) {
                IERC721(nftContractAddress).safeTransferFrom(
                    from, to, tokenIds[i]);
            }
        } else if (nftType == NftType.ERC1155) {
            IERC1155(nftContractAddress).safeBatchTransferFrom(
                from, to, tokenIds, tokenAmounts, "");
        } else {
            require(false, "Invalid NFT type, only ERC721 and ERC1155 are supported");
        }
    }
}

interface IERC721 {
    function safeTransferFrom(address _from, address _to, 
            uint256 _tokenId) external payable;
}

interface IERC1155 {
    function safeBatchTransferFrom(address _from, address _to, 
            uint256[] calldata _ids, uint256[] calldata _values,  
            bytes calldata _data) external;
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

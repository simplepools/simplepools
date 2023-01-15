pragma solidity ^0.8.17;
// SPDX-License-Identifier: MIT

/**
 * Simple Pools NFT Marketplace
 *
 * https://simplepools.org/
 * DeFi pools with simple code and zero tax.
 */
interface IERC721Receiver {
    function onERC721Received(address,address,
        uint256, bytes calldata) external returns (bytes4);
}

/**
 * The marketplace contract.
 */
contract SimplePoolsNftMarketplace is IERC721Receiver {

    struct NftListing {
        uint256 listingId;
        address listingOwner;
        IERC20 requestedTokenForBidAndBuyout;
        uint256 highestBid;
        uint256 buyoutRequestPrice;
        address currentHighestBidder;
        bool isFinished;
        address nftContractAddress;
        uint256 tokenId;
        ListingStatus listingStatus;
        NftType nftType;
    }

    enum NftType {
        ERC721,
        ERC1155
    }

    enum ListingStatus { 
        IN_PROGRESS,
        FINISHED_WITH_BUYOUT,
        FINISHED_WITH_BID_ACCEPTED,
        FINISHED_CANCELLED
    }

    function onERC721Received(address, address,
         uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    NftListing[] public _listings;
    uint256[] _allTransactionsListingIds;

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
        IERC20 requestedTokenForBidAndBuyout,
        uint256 startingPrice,
        uint256 buyoutPrice,
        address nftContractAddress,
        uint256 tokenId,
        NftType nftType
    ) external {
        uint256 listingId =_listings.length;
        _allTransactionsListingIds.push(listingId);
        // transfer NFT from msg.sender to this contract
        IERC721(nftContractAddress).safeTransferFrom(
                msg.sender, address(this), tokenId);        

        _listings.push().listingId = listingId;
        _listings[listingId].listingOwner = msg.sender;
        _listings[listingId].requestedTokenForBidAndBuyout = requestedTokenForBidAndBuyout;
        require(startingPrice > 0, 'invalid starting price');
        _listings[listingId].highestBid = startingPrice - 1;
        _listings[listingId].buyoutRequestPrice = buyoutPrice;
        _listings[listingId].isFinished = false;
        _listings[listingId].nftContractAddress = nftContractAddress;
        _listings[listingId].tokenId = tokenId;
        _listings[listingId].nftType = nftType;
    }

    function buyoutNft(
        uint256 listingId
    ) external {
        NftListing storage listing = _listings[listingId];
        if (listing.nftType == NftType.ERC721) {
            IERC721(listing.nftContractAddress).safeTransferFrom(
                address(this), msg.sender, listing.tokenId);
        } else {
            require(false, "ERC1155 in development");
        }

        IERC20(listing.requestedTokenForBidAndBuyout)
            .transferFrom(
                msg.sender, 
                listing.listingOwner,
                listing.buyoutRequestPrice
                );
        // transfer listing request price from msg.sender to
        // listing owner

        // transfer nft token from this to msg.sender
    }

}

interface IERC721 {
    function safeTransferFrom(address _from, address _to, 
            uint256 _tokenId) external payable;
}

interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view returns (uint8);
}
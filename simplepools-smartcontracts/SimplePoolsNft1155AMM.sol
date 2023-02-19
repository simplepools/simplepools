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
 * Simple Pools NFT AMM (Automated Market Maker)
 * https://simplepools.org/
 * DeFi made simple.
 */

interface IERC1155Receiver {
    function onERC1155BatchReceived(
        address, address, uint256[] calldata, uint256[] calldata, bytes calldata
    ) external returns (bytes4);
    function onERC1155Received(
        address, address, uint256, uint256, bytes calldata
    ) external returns (bytes4);
}

/**
 * The marketplace contract.
 */
contract SimplePoolsNft1155AMM is IERC1155Receiver {

    struct NftListing {
        uint256 listingId;
        address listingOwner;
        address nftContractAddress;
        IERC20 erc20Token;

        uint256 nftTokenIdForAMM;

        uint256 leftNftTokenAmount;

        /**
         * The number of tokens when sold - increment the price 
         * and when bought - decrement the price.
         */
        uint256 incrementNumber;

        uint256 leftTokensForIncrement;
        uint256 soldTokens;

        /**
         * The percent price is incremented/decremented when increment numbers are ticked.
         */
        uint8 incrementPricePercent;

        uint256 currentPrice;

        uint256 currentListingErc20Balance;

        ListingStatus listingStatus;
    }

    enum ListingStatus { 
        IN_PROGRESS,
        CLOSED
    }

    NftListing[] public _listings;
    uint256[] _allTransactionsListingIds;

    function onERC1155BatchReceived(
        address, address, uint256[] calldata, uint256[] calldata, bytes calldata
    ) external pure returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }
    function onERC1155Received(
        address, address, uint256, uint256, bytes calldata
    ) external pure returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
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

    function listNftForAMM(
        address nftContractAddress,
        uint256 nftTokenIdForAMM,
        uint256 tokenAmount,
        IERC20 erc20Token,
        uint256 startingPrice,
        uint256 incrementNumber,
        uint8 incrementPricePercent
    ) external {
        uint256 listingId =_listings.length;
        _allTransactionsListingIds.push(listingId);

        _listings.push().listingId = listingId;
        _listings[listingId].listingOwner = msg.sender;
        _listings[listingId].nftContractAddress = nftContractAddress;
        _listings[listingId].erc20Token = erc20Token;

        _listings[listingId].nftTokenIdForAMM = nftTokenIdForAMM;
        _listings[listingId].leftNftTokenAmount = tokenAmount;
        
        _listings[listingId].incrementNumber = incrementNumber;
        require(incrementNumber > 0, "incrementNumber should be positive");
        _listings[listingId].leftTokensForIncrement = incrementNumber;
        _listings[listingId].incrementPricePercent = incrementPricePercent;
        require(incrementPricePercent > 0, "incrementPrice should be positive");

        _listings[listingId].currentPrice = startingPrice;

        _listings[listingId].listingStatus = ListingStatus.IN_PROGRESS;

        // transfer NFT from msg.sender to this contract
        _transferNft(
            nftContractAddress,
            msg.sender, 
            address(this), 
            nftTokenIdForAMM,
            tokenAmount
        );
    }

    function buyNfts(uint256 listingId, uint256 amount) external {
        _allTransactionsListingIds.push(listingId);
        NftListing storage listing = _listings[listingId];
        require(listing.listingStatus == ListingStatus.IN_PROGRESS, "This NFT listing is finished");
        require(amount <= listing.leftNftTokenAmount, "not enough tokens left in the pool");
        require(amount <= listing.incrementNumber && amount > 0,
                "invalid amount - should be positive and less than or equal to incrementNumber");
        uint256 amountErc20ToTake;
        if (listing.leftTokensForIncrement >= amount) {
            // constant current price
            listing.leftTokensForIncrement -= amount;
            amountErc20ToTake = listing.currentPrice * amount;

        } else { // amount > listing.leftTokensForIncrement
            uint256 onOldPrice = listing.leftTokensForIncrement;
            amountErc20ToTake = onOldPrice * listing.currentPrice;
            listing.currentPrice = Math.mulDiv(listing.currentPrice, 100 + listing.incrementPricePercent, 100);
            uint256 onNewPrice = amount - onOldPrice;
            amountErc20ToTake += onNewPrice * listing.currentPrice;
            listing.leftTokensForIncrement = listing.incrementNumber - (onNewPrice);
        }

        IERC20(listing.erc20Token).transferFrom(msg.sender, address(this), amountErc20ToTake);
        listing.currentListingErc20Balance += amountErc20ToTake;
        // Try to transfer the NFT to the msg.sender
        _transferNft(listing.nftContractAddress,
            address(this), msg.sender, listing.nftTokenIdForAMM,
            amount);
        listing.leftNftTokenAmount -= amount;
        listing.soldTokens += amount;
    }

    function sellNfts(uint256 listingId, uint256 amount) external {
        _allTransactionsListingIds.push(listingId);
        NftListing storage listing = _listings[listingId];
        require(listing.listingStatus == ListingStatus.IN_PROGRESS, "This NFT listing is finished");
        require(amount <= listing.soldTokens, "not enough tokens left in the pool");
        require(amount <= listing.incrementNumber && amount > 0,
                "invalid amount - should be positive and less than or equal to incrementNumber");
        uint256 amountErc20ToGive;
        uint256 leftTokensForPriceDecrement = listing.incrementNumber - listing.leftTokensForIncrement;
        if (leftTokensForPriceDecrement >= amount) {
            // constant current price
            listing.leftTokensForIncrement += amount;
            amountErc20ToGive = listing.currentPrice * amount;

        } else { // amount > leftTokensForPriceDecrement
            uint256 onOldPrice = leftTokensForPriceDecrement;
            amountErc20ToGive = onOldPrice * listing.currentPrice;
            listing.currentPrice = Math.mulDiv(listing.currentPrice, 100, 100 + listing.incrementPricePercent);
            uint256 onNewPrice = amount - onOldPrice;
            amountErc20ToGive += onNewPrice * listing.currentPrice;
            listing.leftTokensForIncrement = onNewPrice;
        }

        // require(currentListingErc20Balance >= amountErc20ToGive,
        //         "currentListingErc20Balance should be >= amountErc20ToGive. DEBUG THIS!");
        amountErc20ToGive = Math.min(listing.currentListingErc20Balance, amountErc20ToGive);
        // Try to transfer the NFT to the this
        _transferNft(listing.nftContractAddress,
            msg.sender, address(this), listing.nftTokenIdForAMM,
            amount);
        IERC20(listing.erc20Token).transferFrom(address(this), msg.sender, amountErc20ToGive);
        listing.currentListingErc20Balance -= amountErc20ToGive;

        listing.leftNftTokenAmount += amount;
        listing.soldTokens -= amount;
    }

    function cancelListing(uint256 listingId) external {
        _allTransactionsListingIds.push(listingId);
        NftListing storage listing = _listings[listingId];

        require(listing.listingStatus == ListingStatus.IN_PROGRESS, "listing is already cancelled");
        require(listing.listingOwner == msg.sender, 
                "Only the listing owner can cancel listings");
        // give everything to listing owner
        IERC20(listing.erc20Token).transferFrom(address(this), msg.sender, listing.currentListingErc20Balance);
        listing.currentListingErc20Balance = 0;
        _transferNft(listing.nftContractAddress, address(this), msg.sender, 
                listing.nftTokenIdForAMM, listing.leftNftTokenAmount);
        listing.leftNftTokenAmount = 0;
        listing.listingStatus = ListingStatus.CLOSED;

        // // Return the money to current highest bidder
        // if (listing.currentHighestBidder != address(0)) {
        //     IERC20(listing.erc20Token)
        //         .transferFrom(address(this), listing.currentHighestBidder, listing.highestBid);
        // }
        // _transferNft(listing.nftContractAddress, 
        //         address(this), msg.sender, listing.tokenIds, 
        //         listing.tokenAmounts, listing.nftType);
        // listing.listingStatus = ListingStatus.FINISHED_CANCELLED;
    }

    function _transferNft(
        address nftContractAddress,
        address from,
        address to,
        uint256 tokenId,
        uint256 tokenAmount
    ) private {
        IERC1155(nftContractAddress).safeTransferFrom(
            from, to, tokenId, tokenAmount, "");
    }
}

interface IERC1155 {
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
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

library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }
}

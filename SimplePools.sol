pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT

contract SimplePools {

    /*
     * First ECR20 token contract have to approve token for spending by the pool contract and then the pool contract can deposit the token
     */
    struct Pool {
        IERC20 token1;
        IERC20 token2;
        uint token1Amount;
        uint token2Amount;
        uint token2VirtualAmount;
        // For example when we want to use a pool for limit sell then maxtxpercent can be 100%
        // so someone can buy all the bitcoin/eth for sell with one transaction.
        // For new tokens that are only traded in one pool it can be 1% or 10% or 50%.
        uint maxPercentPerTransaction;
        uint constantProduct; // (T1*(T2+VT2))=ConstantProduct
        bool constantPrice;
        uint initialToken1Amount;
    }

    address[] public _poolOwnerById;
    mapping(uint => bool) public _lockedPools;
    mapping(uint => bool) public _emptyPools;

    Pool[] public _pools;

    // when we sync the state of all pools (from indexed DB node) we get the current number of all transactions
    // then we get only the latest transactions (that are not indexed) and sync the pools only from them
    // array of the pool ids of all transactions
    uint[] _allTransactionsPoolIds;

    constructor() {

    }

    function createPool(IERC20 token1, IERC20 token2,
            uint token1Amount, uint matchingPriceInToken2,
            uint maxPercentPerTransaction, bool constantPrice) external {
        // matchingPriceInToken2 is the requested initial amount for token2 that match token1
        uint poolId = _pools.length;
        _allTransactionsPoolIds.push(poolId);
        _poolOwnerById.push(msg.sender);
        token1.transferFrom(msg.sender, address(this), token1Amount);
        _pools.push().token1 = token1;
        _pools[poolId].token2 = token2;
        _pools[poolId].token1Amount = token1Amount;
        _pools[poolId].token2Amount = 0;
        _pools[poolId].token2VirtualAmount = matchingPriceInToken2;
        _pools[poolId].constantProduct = token1Amount * matchingPriceInToken2;
        _pools[poolId].maxPercentPerTransaction = maxPercentPerTransaction;
        _pools[poolId].constantPrice = constantPrice;
        _pools[poolId].initialToken1Amount = token1Amount;
    }

    function exchangeToken(
        IERC20 tokenToBuy, 
        uint poolId, 
        uint tokenToSellAmount, 
        uint minReceiveTokenToBuyAmount
    ) external returns (uint) { 
        require(!_emptyPools[poolId], "Pool is empty");
        // returns the amount of token bought.
        // tokenToSell must be the same as one of the tokens in the _pools[poolId]
        // tokenToBuy must be the same as one of the tokens in the pool
        Pool storage pool = _pools[poolId];
        require(tokenToBuy == pool.token1 || tokenToBuy == pool.token2, "trying to buy from wrong pool");
        _allTransactionsPoolIds.push(poolId);
        if (tokenToBuy == pool.token1) {
            uint amountOut;
            if (pool.constantPrice) {
                amountOut = Math.mulDiv(tokenToSellAmount, pool.initialToken1Amount, pool.token2VirtualAmount);
            } else {
                amountOut = pool.token1Amount -
                    Math.ceilDiv(pool.constantProduct,
                             pool.token2VirtualAmount + pool.token2Amount + tokenToSellAmount);
            }
            amountOut = Math.min(amountOut, Math.mulDiv(pool.token1Amount, pool.maxPercentPerTransaction, 100));
            require(pool.token2.allowance(msg.sender, address(this)) >= tokenToSellAmount, "trying to sell more than allowance");
            require(minReceiveTokenToBuyAmount <= amountOut,"minReceive is less than calcualted amount");
            // complete the transaction now
            require(pool.token2.transferFrom(msg.sender, address(this), tokenToSellAmount), "cannot transfer tokenToSellAmount");
            pool.token2Amount += tokenToSellAmount;
            require(pool.token1.transfer(msg.sender, amountOut), "cannot transfer from amountOut from pool");
            pool.token1Amount -= amountOut;
            return amountOut;
        } else if (tokenToBuy == pool.token2) {
            require(pool.token2Amount > 0, "zero amount of token for buy in pool");
            uint amountOut;
            if (pool.constantPrice) {
                amountOut = Math.mulDiv(tokenToSellAmount, pool.token2VirtualAmount, pool.initialToken1Amount);
            } else {
                amountOut = pool.token2VirtualAmount + pool.token2Amount 
                        - Math.ceilDiv(pool.constantProduct,
                               pool.token1Amount + tokenToSellAmount);
            }
            amountOut = Math.min(amountOut, Math.mulDiv(pool.token2Amount, pool.maxPercentPerTransaction, 100));
            require(pool.token1.allowance(msg.sender, address(this)) >= tokenToSellAmount, "trying to sell more than allowance");
            require(minReceiveTokenToBuyAmount <= amountOut,"minReceive is more than calcualted amount");
            // complete the transaction now
            require(pool.token1.transferFrom(msg.sender, address(this), tokenToSellAmount), "cannot transfer tokenToSellAmount");
            pool.token1Amount += tokenToSellAmount;
            require(pool.token2.transfer(msg.sender, amountOut), "cannot transfer from amountOut from pool");
            pool.token2Amount -= amountOut;
            return amountOut;
        }
        require(false, "Wrong token address or poolId");
        return 0;
    }

    function getAllTokensFromPool(uint poolId) external {
        require(_pools.length > poolId, "invalid pool id");
        require(!_lockedPools[poolId], "pool is locked");
        require(!_emptyPools[poolId], "pool is empty");
        require(_poolOwnerById[poolId] == msg.sender, "only the pool owner can empty pool");
        _allTransactionsPoolIds.push(poolId);
        Pool storage pool = _pools[poolId];
        pool.token1.transferFrom(address(this), msg.sender, pool.token1Amount);
        pool.token1Amount = 0;
        pool.token2.transferFrom(address(this), msg.sender, pool.token2Amount);
        pool.token2Amount = 0;
        pool.token2VirtualAmount = 0;
        _emptyPools[poolId] = true;
    }

    function lockPool(uint poolId) external returns (bool) {
        require(!_lockedPools[poolId], "pool is already locked");
        require(_pools.length > poolId, "invalid pool id");
        require(_poolOwnerById[poolId] == msg.sender, "only the pool owner can lock pool");
        _allTransactionsPoolIds.push(poolId);
        _lockedPools[poolId] = true;
        return true;
    }

    // if owner gets compromised and is fast enough or if you want to make 0 address the owner.
    function changeOwner(uint poolId, address newPoolOwner) external returns (bool) {
        require(poolId < _pools.length, "invalid poolId");
        require(!_lockedPools[poolId], "pool is locked");
        require(_poolOwnerById[poolId] == msg.sender, "only the pool owner can change ownership");
        _poolOwnerById[poolId] = newPoolOwner;
        _allTransactionsPoolIds.push(poolId);
        return true;
    }

    function changePoolMaxPercentPerTransaction(uint poolId, uint newMaxPercentPerTransaction) external returns (bool) {
        require(poolId < _pools.length, "invalid poolId");
        require(!_lockedPools[poolId], "pool is locked");
        require(_poolOwnerById[poolId] == msg.sender, "only the pool owner can change newMaxPercentPerTransaction");
        require(newMaxPercentPerTransaction <= 100 && newMaxPercentPerTransaction > 0, "invalid max percent per transaction");
        _pools[poolId].maxPercentPerTransaction = newMaxPercentPerTransaction;
        _allTransactionsPoolIds.push(poolId);
        return true;
    }

    function changeContantProduct(uint poolId, uint newConstnatProduct) external returns (bool) {
        require(poolId < _pools.length, "invalid poolId");
        require(!_lockedPools[poolId], "pool is locked");
        require(_poolOwnerById[poolId] == msg.sender, "only the pool owner can change the constant product");
        require(newConstnatProduct > 0, "invalid constant product (only positive numbers)");
        _pools[poolId].constantProduct = newConstnatProduct;
        _allTransactionsPoolIds.push(poolId);
        return true;
    }

    function isPoolLocked(uint poolId) external view returns (bool) {
        return _lockedPools[poolId];
    }

    function getPoolsCount() external view returns (uint) {
        return _pools.length;
    }

    // Get pools from start index to end index [startPoolIndex, ..., endPoolIndex)
    // start included, end not included
    function getPools(uint startPoolIndex, uint endPoolIndex) external view returns (Pool[] memory) {
       require(endPoolIndex > startPoolIndex && endPoolIndex <= _pools.length, "invalid indexes");
       Pool[] memory pools = new Pool[](endPoolIndex - startPoolIndex);
       for (uint i = startPoolIndex; i < endPoolIndex; ++i) {
            pools[i - startPoolIndex] = _pools[i];
        }
        return pools;
    }
    
    // till end
    function getPoolsFrom(uint startPoolIndex) external view returns (Pool[] memory) {
       require(startPoolIndex < _pools.length, "invalid index");
       Pool[] memory pools = new Pool[](_pools.length - startPoolIndex);
       for (uint i = startPoolIndex; i < _pools.length; ++i) {
            pools[i - startPoolIndex] = _pools[i];
        }
        return pools;
    }

    // Get pools specified in indexes array
    function getPools(uint[] memory indexes) external view returns (Pool[] memory) {
        Pool[] memory pools = new Pool[](indexes.length);
        for (uint i = 0; i < indexes.length; ++i) {
            Pool storage pool = _pools[indexes[i]];
            pools[i] = pool;
        }
        return pools;
    }

    function getPool(uint poolId) external view returns (Pool memory) {
        return _pools[poolId];
    }

    function getTransactionsCount() external view returns (uint) {
        return _allTransactionsPoolIds.length;
    }

    // [startPoolIndex, ..., endPoolIndex)
    // start included, end not included
    function getPoolsForTransactionsWithIndexesBetween(
            uint startTransactionIndex, uint endTransactionIndex) external view returns (uint[] memory) {
        require(endTransactionIndex > startTransactionIndex && endTransactionIndex <= _allTransactionsPoolIds.length, "invalid indexes");
        uint[] memory poolIndexes = new uint[](endTransactionIndex - startTransactionIndex);
        for (uint i = startTransactionIndex; i < endTransactionIndex; ++i) {
            poolIndexes[i - startTransactionIndex] = _allTransactionsPoolIds[i];
        }
        return poolIndexes;
    }

    function getPoolsForTransactionsWithIndexesFrom(
            uint startTransactionIndex) external view returns (uint[] memory) {
        require(startTransactionIndex < _allTransactionsPoolIds.length, "invalid index");
        uint[] memory poolIndexes = new uint[](_allTransactionsPoolIds.length - startTransactionIndex);
        for (uint i = startTransactionIndex; i < _allTransactionsPoolIds.length; ++i) {
            poolIndexes[i - startTransactionIndex] = _allTransactionsPoolIds[i];
        }
        return poolIndexes;
    }
}

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
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
}

pragma solidity ^0.8.17;
// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2023 simplepools.org

// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

// You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

/**
 * Simple Pools
 * https://simplepools.org/
 * DeFi made simple.
 */
contract CallContractWithTax {

    /**
     * The owner of the contract (the receiver of the taxes).
     */
    address payable public contractOwner;

    /**
     * Set the initial contract owner to the msg.sender.
     */
    constructor() {
        contractOwner = payable(msg.sender);
    }

    /**
     * Function to receive native asset, msg.data must be empty.
     */
    receive() external payable {}

    /**
     * Fallback function is called when msg.data is not empty.
     */
    fallback() external payable {}

    /**
     * Gets the current native asset balance of contract.
     */
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    /**
     * Sets a new contract owner. Only callable by the current contract owner.
     */
    function setNewOwner(address newOwner) external {
        require(msg.sender == contractOwner, "only the current owner can change the owner");
        contractOwner = payable(newOwner);
    }

    uint256 contractTransactionTax = 10 ** 15;

    uint256[] validContractTransactionTaxes = [10**13, 10**14, 10**15, 10**16, 10**17];

    /**
     * Sets a new contractTransactionNax. Only callable by the current contract owner.
     * The list of valid transaction taxes which can be set is validContractTransactionTaxes.
     */
    function setNewGlobalTax(uint8 newTaxIndexFromValidContractTransactionTaxes) external {
        require(msg.sender == contractOwner, "only the current owner can change the tax");
        require(newTaxIndexFromValidContractTransactionTaxes < validContractTransactionTaxes.length &&
                newTaxIndexFromValidContractTransactionTaxes >= 0, 
                "invalid newTaxIndexFromValidContractTransactionTaxes");
        contractTransactionTax = validContractTransactionTaxes[newTaxIndexFromValidContractTransactionTaxes];
    }

    function exchange(
        SimplePools simplePoolsContract,
        address personExecutingTheExchange,
        uint64 poolId, 
        bool isBuyingAsset1, 
        uint256 sellAmount, 
        uint256 minReceiveAssetToBuyAmount
    ) external payable { 
        uint256 tax = 2 * contractTransactionTax;
        require(msg.value >= tax,
           "require transaction tax > 0.003 eth");

        uint256 forTax = simplePoolsContract.exchangeAsset{value: tax}(
                address(this),
                0,
                true,
                tax - contractTransactionTax,
                0
        );
        SimplePools.Pool memory pool = simplePoolsContract.getPool(0);
        IERC20(pool.asset1).transferFrom(address(this), contractOwner, forTax);

        simplePoolsContract.exchangeAsset{value: msg.value - tax}(
                personExecutingTheExchange,
                poolId,
                isBuyingAsset1,
                sellAmount,
                minReceiveAssetToBuyAmount
        );
    }

    function createPool(
        SimplePools simplePoolsContract,
        address poolCreatorAddress,
        bool isAsset1Native,
        IERC20 asset1,
        bool isAsset2Native,
        IERC20 asset2,
        uint256 asset1Amount,
        uint256 asset2InitiallyAskedAmount,
        uint8 maxBuyAsset1PercentPerTransaction, 
        bool isConstantPrice
    ) external payable {
        uint256 tax = 2 * contractTransactionTax;
        require(msg.value >= tax,
           "require transaction tax > 0.003 eth");

        uint256 forTax = simplePoolsContract.exchangeAsset{value: tax}(
                address(this),
                0,
                true,
                tax - contractTransactionTax,
                0
        );
        SimplePools.Pool memory pool = simplePoolsContract.getPool(0);
        IERC20(pool.asset1).transferFrom(address(this), contractOwner, forTax);

        contractOwner.transfer(tax);
        simplePoolsContract.createPool{value: msg.value - tax}(
                poolCreatorAddress,
                isAsset1Native,
                asset1,
                isAsset2Native,
                asset2,
                asset1Amount,
                asset2InitiallyAskedAmount, 
                maxBuyAsset1PercentPerTransaction,
                isConstantPrice
        );
    }
}


interface SimplePools {

    struct Pool {
        uint64 poolId;
        bool isAsset1NativeBlockchainCurrency;
        address asset1;
        bool isAsset2NativeBlockchainCurrency;
        address asset2;
        uint256 asset1Amount;
        uint256 asset2Amount;
        uint256 asset2InitiallyAskedAmount;
        uint8 maxBuyAsset1PercentPerTransaction;
        uint256 constantProduct; // (A1*(A2+IA2)) = constantProduct
        bool isConstantPrice;
        uint256 initialAsset1Amount;
        address payable poolOwner;
        bool isLocked;
        bool isEmpty;
    }

    function exchangeAsset(
        address personExecutingTheExchange,
        uint64 poolId,
        bool isBuyingAsset1,
        uint256 sellAmount, 
        uint256 minReceiveAssetToBuyAmount
    ) external payable returns (uint256);

    function createPool(
        address poolCreatorAddress,
        bool isAsset1Native,
        IERC20 asset1,
        bool isAsset2Native,
        IERC20 asset2,
        uint256 asset1Amount,
        uint256 asset2InitiallyAskedAmount,
        uint8 maxBuyAsset1PercentPerTransaction, 
        bool isConstantPrice
    ) external payable;

    function getPool(uint64 poolId) external view returns (Pool memory);
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

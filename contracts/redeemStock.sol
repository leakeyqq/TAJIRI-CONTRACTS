// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./mintStock.sol";

contract RedeemStock is MintStock {

    constructor(address initialOwner) MintStock(initialOwner) {}

    function redeemStock(address stockContractAddress, uint256 stockAmountInTokens) external payable{
        
        StockInterface stockContract;

        stockContract = StockInterface(stockContractAddress);

        // Check if the contract is allowed to burn the specified amount of tokens
        uint256 allowance = stockContract.allowance(msg.sender, address(this));
        require(allowance >= stockAmountInTokens, "Insufficient token allowance");

        stockContract.burnFrom(msg.sender, stockAmountInTokens);

        // Find the equivalent ETH value of the burned stocks
        uint256 ethToSendBack = findEquivalentEthValue(stockAmountInTokens, stockContractAddress);

        // Ensure that the contract has enough ETH to send back to the user
        require(address(this).balance >= ethToSendBack, "Not enough ETH to redeem stocks");

        // Transfer the equivalent ETH value to the user
        payable(msg.sender).transfer(ethToSendBack);
    }

    function findEquivalentEthValue(uint256 stockAmountInTokens, address stockContractAddress) internal view returns (uint256) {
        // Find the stock using the contractAddress
        uint stockIndex = findStockIndexByAddress(stockContractAddress);

        // Get the stock's price in ETH
        uint256 stockPriceEth = stocks[stockIndex].stockPriceEth;

        // Calculate the equivalent ETH value by multiplying the stock amount by the stock price
        uint256 ethValue = (stockAmountInTokens * stockPriceEth) / (10 ** 18); // Adjust for decimal places

        return ethValue;
    }

}
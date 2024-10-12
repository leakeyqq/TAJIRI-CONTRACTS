// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./manageStock.sol";

contract MintStock is ManageStock {

    constructor(address initialOwner) ManageStock(initialOwner) {}

    event MintedStockForUser(address indexed recipient, address indexed stockContract, uint256 stockAmount);
    function mintNewStock(address stockContractAddress) public payable{

        StockInterface stockContract;
        uint256 ethSent = msg.value;

        // Ensure that ethSent is greater than zero
        require(ethSent > 0, "You must send ETH to mint stocks");


        uint256 amountOfStocksToMint = findEquivalentStockAmount(ethSent, stockContractAddress);
        uint256 amountOfStocksToMintInTokens = amountOfStocksToMint * 10**18;

        stockContract = StockInterface(stockContractAddress);
        stockContract.mint(msg.sender, amountOfStocksToMintInTokens);

        emit MintedStockForUser(msg.sender, stockContractAddress, amountOfStocksToMint);
    }

    function findEquivalentStockAmount(uint256 ethSent, address stockContractAddress) internal view returns (uint256){
        // Find the stock using the contractAddress
        uint stockIndex = findStockIndexByAddress(stockContractAddress);

        // Get the stock's price in ETH
        uint256 stockPrice = stocks[stockIndex].stockPriceEth;

        require(stockPrice > 0, "Stock price must be greater than zero");

        // Calculate the equivalent stock amount by dividing ETH sent by stock price
        uint256 equivalentStockAmount = ethSent / stockPrice;

        return equivalentStockAmount;
    }
}



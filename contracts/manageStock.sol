// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

interface StockInterface{
    function mint(address to, uint256 amount) external;
    function burnFrom(address name, uint256 value) external;
    function allowance(address owner, address spender) external  returns(uint256);
    function transferFrom(address from, address to, uint256 value) external returns(bool);
}

contract ManageStock is Ownable{

    constructor(address initialOwner)
        Ownable(initialOwner)
    {}

    struct Stock {
        string shortName;
        string longName;
        address contractAddress;
        uint256 stockPriceEth;
    }

    Stock[] public stocks;

    event AddedStock(string shortName, string longName, address indexed contractAddress, uint256 stockPriceEth);
    event RemovedStock(string shortName, string longName, address indexed contractAddress, uint256 stockPriceEth);
    event UpdatedStockPrice(address indexed contractAddress, uint256 oldPrice, uint256 newPrice);

    function addStock(string memory shortName, string memory longName, address contractAddress, uint256 stockPriceEth) onlyOwner public {
        Stock memory stock;
        stock.shortName = shortName;
        stock.longName = longName;
        stock.contractAddress = contractAddress;
        stock.stockPriceEth = stockPriceEth;

        stocks.push(stock);

        emit AddedStock(shortName, longName, contractAddress, stockPriceEth);

    }

    function removeStock(address contractAddress) onlyOwner public {
        uint stockIndex = findStockIndexByAddress(contractAddress);
        require(stockIndex < stocks.length, "Stock not found");

        Stock memory removedStock = stocks[stockIndex];

        // Replace the stock to be removed with the last stock in the array
        stocks[stockIndex] = stocks[stocks.length - 1];

        // Remove the last stock (duplicate) from the array
        stocks.pop();

        emit RemovedStock(removedStock.shortName, removedStock.longName, removedStock.contractAddress, removedStock.stockPriceEth);
    }

    function setStockPrice(address contractAddress, uint256 newPrice) public onlyOwner {
        uint length = stocks.length;

        for (uint i = 0; i < length; i++) {
            if (stocks[i].contractAddress == contractAddress) {
                uint256 oldPrice = stocks[i].stockPriceEth; // Save old price
                stocks[i].stockPriceEth = newPrice; // Update the price
                emit UpdatedStockPrice(contractAddress, oldPrice, newPrice); // Emit event
                return;
            }
        }

        revert("Stock with this contract address not found");
    }

    // Function to get all stocks
    function getAllStocks() public view returns (Stock[] memory) {
        return stocks;
    }


    function findStockIndexByAddress(address contractAddress) internal view returns (uint) {
        for (uint i = 0; i < stocks.length; i++) {
            if (stocks[i].contractAddress == contractAddress) {
                return i;
            }
        }
        revert("Stock not found");
    }

}
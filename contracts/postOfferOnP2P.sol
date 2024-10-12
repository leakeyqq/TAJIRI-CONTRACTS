// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./redeemStock.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PostOfferOnP2P is RedeemStock, ReentrancyGuard{

    using  Counters for Counters.Counter;
    Counters.Counter private _offerIDCounter; // Counter for unique offer IDs

    constructor(address initialOnwer) RedeemStock(initialOnwer) {}

    uint offerID = 0;

    struct BuyOffer {
        address stockContract;
        uint stockAmount;
        uint offerPriceEth;
        uint offerID;
        address createdByUser;
    }

    struct SellOffer {
        address stockContract;
        uint stockAmount;
        uint offerPriceEth;
        uint offerID;
        address createdByUser;
    }

    BuyOffer[] public buyOffers;
    SellOffer[] public  sellOffers;


    event BuyOfferPosted(address indexed stockContract, uint stockAmount, uint offerPriceEth, uint offerID);
    event SellOfferPosted(address indexed stockContract, uint stockAmount, uint offerPriceEth, uint offerID);

    event BuyOfferDeleted(address indexed stockContract, uint stockAmount, uint offerPriceEth, uint offerID);
    event SellOfferDeleted(address indexed stockContract, uint stockAmount, uint offerPriceEth, uint offerID);

    event PriceOfOfferChanged(uint256 offerID, uint oldPrice, uint newPrice);



    function createBuyOffer(address stockContractAddress, uint256 stockAmount, uint256 offerPriceEth) external payable nonReentrant returns (uint256){
        // Buyer should pay for the stocks they want to buy upfront 
        // The ETH will be locked in the escorow funtion until a trader takes the offer

        uint totalOfferPrice = (stockAmount * offerPriceEth) / (10**18);
        require (msg.value == totalOfferPrice, "You have to send exact ETH value for the stocks you want to buy!"); 

        // Increment the counter safely
        _offerIDCounter.increment();
        uint newOfferID = _offerIDCounter.current();

        BuyOffer memory buyOffer;
        buyOffer.stockContract = stockContractAddress;
        buyOffer.stockAmount = stockAmount;
        buyOffer.offerPriceEth = offerPriceEth;
        buyOffer.offerID = newOfferID;
        buyOffer.createdByUser = msg.sender;

        buyOffers.push(buyOffer);

        emit BuyOfferPosted(stockContractAddress, stockAmount, offerPriceEth, newOfferID);

        return newOfferID;
    }

    function createSellOffer(address stockContractAddress, uint256 stockAmount, uint256 offerPriceEth) external nonReentrant returns (uint256){
        // Buyer should pay for the stocks they want to buy upfront 
        // The ETH will be locked in the escorow funtion until a trader takes the offer

        StockInterface stockContract;
        stockContract = StockInterface(stockContractAddress);

        // Check if we have enough allowance
        uint256 allowance = stockContract.allowance(msg.sender, address(this));
        require(allowance >= stockAmount, "Insufficient token allowance");

        // Transfer the stock from user to contract
        stockContract.transferFrom(msg.sender, address(this), stockAmount); // Transfer the stocks from user to contract

        // Increment the counter safely
        _offerIDCounter.increment();
        uint newOfferID = _offerIDCounter.current();

        BuyOffer memory buyOffer;
        buyOffer.stockContract = stockContractAddress;
        buyOffer.stockAmount = stockAmount;
        buyOffer.offerPriceEth = offerPriceEth;
        buyOffer.offerID = newOfferID;
        buyOffer.createdByUser = msg.sender;

        buyOffers.push(buyOffer);

        emit BuyOfferPosted(stockContractAddress, stockAmount, offerPriceEth, newOfferID);

        return newOfferID;
    }

    function deleteBuyOffer(uint offerIDToDelete) external payable nonReentrant returns (bool){
        // Find the offer by its ID and check ownership
        for (uint i = 0; i < buyOffers.length; i++) {
            if (buyOffers[i].offerID == offerIDToDelete) {

                require(msg.sender == buyOffers[i].createdByUser, "You do not have permissions for this offer!");
                uint256 ethToRefund = (buyOffers[i].stockAmount * buyOffers[i].offerPriceEth) / (10**18);

                BuyOffer memory buyOfferToDelete = buyOffers[i];

                // Remove the offer by moving the last element into the current slot and popping the last element
                buyOffers[i] = buyOffers[buyOffers.length - 1];
                buyOffers.pop();

                // Check if the contract has enough ETH to refund the user
                require(address(this).balance >= ethToRefund, "Contract does not have enough ETH for the refund");

                // Refund the ETH to the user
                (bool success, ) = payable(msg.sender).call{value: ethToRefund}("");
                require(success, "Refund failed");

                emit BuyOfferDeleted(buyOfferToDelete.stockContract, buyOfferToDelete.stockAmount, buyOfferToDelete.offerPriceEth, buyOfferToDelete.offerID);
                return true;
            }
        }

        revert("Offer not found!");
    }

    function deleteSellOffer(uint offerIDToDelete) external nonReentrant returns (bool){
        // Find the offer by its ID and check ownership
        for (uint i = 0; i < sellOffers.length; i++) {
            if (sellOffers[i].offerID == offerIDToDelete) {

                require(msg.sender == sellOffers[i].createdByUser, "You do not have permissions for this offer!");
                uint256 stockAmountToRefund = sellOffers[i].stockAmount;


                StockInterface stockContract;
                stockContract = StockInterface(sellOffers[i].stockContract);
                stockContract.transferFrom(address(this), msg.sender, stockAmountToRefund);

                SellOffer memory sellOfferToDelete = sellOffers[i];

                // Remove the offer by moving the last element into the current slot and popping the last element
                sellOffers[i] = sellOffers[sellOffers.length - 1];
                sellOffers.pop();

                emit SellOfferDeleted(sellOfferToDelete.stockContract, sellOfferToDelete.stockAmount, sellOfferToDelete.offerPriceEth, sellOfferToDelete.offerID);
                return true;
            }
        }

        revert("Offer not found!");
    }

    function changePriceOfOffer(uint offerIDToUpdate, string memory offerType, uint newOfferPrice) external nonReentrant returns (bool){
        // offerType = [buyOffer/sellOffer}

        if(keccak256(abi.encodePacked(offerType)) == keccak256(abi.encodePacked("buyOffer"))){
            for(uint i = 0; i < buyOffers.length; i++){
                if(buyOffers[i].offerID == offerIDToUpdate){
                    uint256 oldOfferPrice = buyOffers[i].offerPriceEth;
                    buyOffers[i].offerPriceEth = newOfferPrice;
                    emit PriceOfOfferChanged(offerIDToUpdate, oldOfferPrice, newOfferPrice);
                    return true;
                }
            }
            revert("Buy offer not found!");

        }else if(keccak256(abi.encodePacked(offerType)) == keccak256(abi.encodePacked("sellOffer"))){

            for(uint i = 0; i < sellOffers.length; i++){
                if(sellOffers[i].offerID == offerIDToUpdate){
                    uint256 oldOfferPrice = sellOffers[i].offerPriceEth;
                    sellOffers[i].offerPriceEth = newOfferPrice;
                    emit PriceOfOfferChanged(offerIDToUpdate, oldOfferPrice, newOfferPrice);
                    return true;
                }
            }
            revert("Sell offer not found!");

        }else{
            revert("Invalid offer type!");
        }
    }

}
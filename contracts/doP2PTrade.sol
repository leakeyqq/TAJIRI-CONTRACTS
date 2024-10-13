// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./postOfferOnP2P.sol";

contract DoP2PTrade is PostOfferOnP2P{
    constructor(address initialOwner) PostOfferOnP2P(initialOwner) {}


    event BuyOfferExecuted(address indexed stockContract, uint stockAmount, uint offerPrice, uint offerID);
    event SellOfferExecuted(address indexed stockContract, uint stockAmount, uint offerPrice, uint offerID);

    function getAllBuyOffers() external view returns (BuyOffer[] memory) { 
        return buyOffers;
    }
    function getAllSellOffers() external view returns (SellOffer[] memory) {
        return sellOffers;
    }

    function sellToABuyer(uint buyerOfferID) external payable returns (bool){
        // Fetch offer
        for(uint i = 0; i < buyOffers.length; i++){
            if(buyOffers[i].offerID == buyerOfferID){

                // Fetch offer details
                BuyOffer memory buyOffer = buyOffers[i];


                StockInterface stockContract;
                stockContract = StockInterface(buyOffer.stockContract);



                // Transfer stocks from seller to buyer.
                // Transfer locked ETH from contract to the seller

                // Check if we have enough allowance to transfer stocks from the seller's wallet to contract
                uint256 allowance = stockContract.allowance(msg.sender, address(this));
                require(allowance >= buyOffer.stockAmount, "Insufficient token allowance");

                stockContract.transferFrom(msg.sender, address(this), buyOffer.stockAmount); // Transfer the stocks from user to contract
                stockContract.transfer(buyOffer.createdByUser, buyOffer.stockAmount);

                // Calculate ETH to send to seller
                uint ethSellerShallReceive = (buyOffer.stockAmount * buyOffer.offerPriceEth) / (10 ** 18);

                // Check if the contract has enough ETH to send to seller
                require(address(this).balance >= ethSellerShallReceive, "Contract does not have enough ETH to send to seller!");

                // Send ETH to the seller
                (bool success, ) = payable(msg.sender).call{value: ethSellerShallReceive}("");
                require(success, "Failed to send ETH to the seller!");

                // Delete the offer
                buyOffers[i] = buyOffers[buyOffers.length - 1];
                buyOffers.pop();

                emit BuyOfferExecuted(buyOffer.stockContract, buyOffer.stockAmount, buyOffer.offerPriceEth, buyerOfferID);

                return true;

            }

        }
        revert("The buy offer was not found!");
    }

    function buyFromAseller(uint sellerOfferID) external payable returns (bool) {
        // Fetch offer
        for(uint i = 0; i < sellOffers.length; i++){
            if(sellOffers[i].offerID == sellerOfferID){
                SellOffer memory sellOffer = sellOffers[i];

                // Check if buyer has sent enough ETH for the transaction
                uint ethBuyerShallPay = (sellOffer.stockAmount * sellOffer.offerPriceEth) / (10**18);

                require(msg.value == ethBuyerShallPay, "The ETH sent is not equal to what is required of you to send!");

                // Tranfer ETH to the seller
                (bool success, ) = payable(sellOffer.createdByUser).call{value: ethBuyerShallPay}("");
                require(success, "Failed to send ETH to the seller!");

                // Tranfer stocks to buyer
                StockInterface stockContract;
                stockContract = StockInterface(sellOffer.stockContract);
                
                stockContract.transfer(msg.sender, sellOffer.stockAmount);

                // Delete the offerID
                sellOffers[i] = sellOffers[sellOffers.length - 1];
                sellOffers.pop();

                emit SellOfferExecuted(sellOffer.stockContract, sellOffer.stockAmount, sellOffer.offerPriceEth, sellerOfferID); 
                return true;
                
            }
        }
        revert("Seller offer was not found!");

    }

}
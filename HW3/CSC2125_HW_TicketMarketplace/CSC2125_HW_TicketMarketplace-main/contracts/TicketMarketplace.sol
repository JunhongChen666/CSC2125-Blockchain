// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ITicketNFT} from "./interfaces/ITicketNFT.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TicketNFT} from "./TicketNFT.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol"; 
import {ITicketMarketplace} from "./interfaces/ITicketMarketplace.sol";
import "hardhat/console.sol";

contract TicketMarketplace is ITicketMarketplace {
    // your code goes here (you can do it!)
    struct Event {
        uint128 nextTicketToSell;
        uint128 maxTickets;
        uint256 pricePerTicket;
        uint256 pricePerTicketERC20;

    }


    mapping(uint128 => Event) public events;

    address public owner;
    address public ERC20Address;
    address public nftContract;

    uint128 public currentEventId;
    uint128 public seatId;

    ITicketNFT public ticketNFT;
    IERC20 public sampleCoin; 
    
    constructor(address _erc20Address) {
        ERC20Address = _erc20Address;
        currentEventId = 0;
        seatId = 0;
        owner = msg.sender;
        ticketNFT = new TicketNFT("");
        sampleCoin = IERC20(_erc20Address);
        nftContract = address(ticketNFT);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized access");
        _;
    }



    function createEvent(uint128 maxTickets, uint256 pricePerTicket, uint256 pricePerTicketERC20) external override onlyOwner {

        events[currentEventId] = Event(0, maxTickets,pricePerTicket,pricePerTicketERC20);

        // Triggering event
        emit EventCreated(currentEventId, maxTickets, pricePerTicket, pricePerTicketERC20);
        currentEventId++;
    }

    function setMaxTicketsForEvent(uint128 eventId, uint128 newMaxTickets) external override onlyOwner {

        require(newMaxTickets >= events[eventId].maxTickets, "The new number of max tickets is too small!");

        events[eventId].maxTickets = newMaxTickets;
        emit MaxTicketsUpdate(eventId, newMaxTickets);
    }

    function setPriceForTicketETH(uint128 eventId, uint256 price) external override onlyOwner {

        events[eventId].pricePerTicket = price;
        emit PriceUpdate(eventId, price, "ETH");
    }

    function setPriceForTicketERC20(uint128 eventId, uint256 price) external override onlyOwner {

        events[eventId].pricePerTicketERC20 = price;
        emit PriceUpdate(eventId, price, "ERC20");
    }

    function buyTickets(uint128 eventId, uint128 ticketCount) payable external override {
        uint256 totalPrice;
        unchecked {
            totalPrice = events[eventId].pricePerTicket * ticketCount;
        }
        require(totalPrice/ticketCount ==  events[eventId].pricePerTicket,"Overflow happened while calculating the total price of tickets. Try buying smaller number of tickets.");
        require(events[eventId].nextTicketToSell + ticketCount <= events[eventId].maxTickets, "We don't have that many tickets left to sell!");
        require(msg.value >= totalPrice, "Not enough funds supplied to buy the specified number of tickets.");

        for (uint128 i = 0; i < ticketCount; i++) {
            uint256 nftId = (uint256(eventId) << 128) + seatId;
            ticketNFT.mintFromMarketPlace(msg.sender, nftId);
            seatId++;
        }
        events[eventId].nextTicketToSell += ticketCount;

        emit TicketsBought(eventId, ticketCount, "ETH");
    }

    function buyTicketsERC20(uint128 eventId, uint128 ticketCount) external override {
        uint256 totalPrice;
        unchecked {
            totalPrice = events[eventId].pricePerTicketERC20 * ticketCount;
        }

        require(totalPrice/ticketCount ==  events[eventId].pricePerTicketERC20,"Overflow happened while calculating the total price of tickets. Try buying smaller number of tickets.");
        require(sampleCoin.balanceOf(msg.sender)>= totalPrice, "Should revert when not enough funds is on the account");
        require(events[eventId].nextTicketToSell + ticketCount <= events[eventId].maxTickets, "We don't have that many tickets left to sell!");

        sampleCoin.transferFrom(msg.sender, address(this), totalPrice);

        for (uint128 i = 0; i < ticketCount; i++) {
            uint256 nftId = (uint256(eventId) << 128) + seatId;
            ticketNFT.mintFromMarketPlace(msg.sender, nftId);
            seatId++;
        }

        events[eventId].nextTicketToSell += ticketCount;
        emit TicketsBought(eventId, ticketCount, "ERC20");
    }


    function setERC20Address(address newERC20Address) public override onlyOwner {
        ERC20Address = newERC20Address;
        emit ERC20AddressUpdate(newERC20Address);
    }

}
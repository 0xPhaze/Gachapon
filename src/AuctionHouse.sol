// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {console} from "../lib/forge-std/src/console.sol";

import {Ownable} from "./lib/Ownable.sol";
import {Gouda} from "./lib/Gouda.sol";

import {IERC721} from "../lib/openzeppelin-contracts/contracts/interfaces/IERC721.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";

error AuctionOngoing();
error AuctionInactive();

error InvalidTimestamp();
error BidTooLow();
error CannotWithdrawWinningBid();
error IncorrectWinner();

contract AuctionHouse is Ownable {
    event BurnForWhitelist(uint256 indexed id);

    struct Auction {
        uint40 start;
        uint40 end;
        uint160 currentBid; // way more than should be ever minted
        bool cancelled;
    }

    struct Prize {
        address nft;
        uint256 id;
    }

    uint256 public numAuctions;
    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => Prize) public prizes;

    mapping(uint256 => mapping(address => uint256)) public bids;

    // Gouda constant gouda = Gouda(0x3aD30C5E3496BE07968579169a96f00D56De4C1A);
    Gouda immutable gouda;

    constructor(Gouda gouda_) {
        gouda = gouda_;
    }

    /* ------------- External ------------- */

    function placeBid(uint256 auctionId, uint160 bid) external {
        Auction storage auction = auctions[auctionId];

        if (block.timestamp < auction.start || auction.end < block.timestamp) revert AuctionInactive();
        if (bid <= auction.currentBid) revert BidTooLow();

        uint256 callerBid = bids[auctionId][msg.sender];
        unchecked {
            // callerBid <= auction.currentBid < bid
            gouda.transferFrom(msg.sender, address(this), bid - callerBid);
        }

        bids[auctionId][msg.sender] = bid;
        auction.currentBid = bid;
    }

    function resolveBid(uint256 auctionId) external {
        Auction storage auction = auctions[auctionId];

        if (block.timestamp <= auction.end) revert AuctionOngoing();

        uint256 callerBid = bids[auctionId][msg.sender];
        delete bids[auctionId][msg.sender];

        if (auction.currentBid == callerBid) {
            Prize storage prize = prizes[auctionId];
            IERC721(prize.nft).transferFrom(address(this), msg.sender, prize.id);
        } else {
            gouda.transferFrom(address(this), msg.sender, callerBid);
        }
    }

    /* ------------- Owner ------------- */

    function createAuction(
        address toy,
        uint256 id,
        uint40 start,
        uint40 end
    ) external onlyOwner {
        uint256 auctionId;
        unchecked {
            auctionId = ++numAuctions;
        }
        Auction storage auction = auctions[auctionId];

        if (start > end) revert InvalidTimestamp();

        IERC721(toy).transferFrom(msg.sender, address(this), id);

        auction.start = start;
        auction.end = end;
    }

    function cancelAuction(uint256 auctionId) external onlyOwner {
        Auction storage auction = auctions[auctionId];
        auction.cancelled = true;

        Prize storage prize = prizes[auctionId];

        IERC721(prize.nft).transferFrom(address(this), msg.sender, prize.id);
    }
}

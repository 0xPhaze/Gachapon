// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {console} from "../lib/forge-std/src/console.sol";

import {Ownable} from "./lib/Ownable.sol";
import {Gouda} from "./lib/Gouda.sol";
import {IMadMouse} from "./lib/interfaces.sol";

import {IERC721} from "../lib/openzeppelin-contracts/contracts/interfaces/IERC721.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";

error AuctionOngoing();
error AuctionInactive();
error AuctionCancelled();

error ContractCallNotAllowed();

error InvalidTimestamp();
error BidTooLow();
error NoBidPlaced();
error CannotWithdrawWinningBid();
error IncorrectWinner();
error RequirementNotFulfilled();

error QualifierMaxEntrantsReached();
error QualifierInactive();
error QualifierSeedNotSet();
error QualifierNotEntered();
error QualifierAlreadyEntered();
error QualifierNotRequired();
error QualifierRevealInvalidTimeFrame();
error QualifierRandomSeedSet();

contract AuctionHouse is Ownable {
    event BidPlaced(uint256 indexed auctionId, address sender, uint256 price);

    struct Auction {
        uint16 qualifierNumEntrants;
        uint16 qualifierMaxEntrants;
        uint40 qualifierDuration;
        uint16 qualifierChance;
        uint16 qualifierRandomSeed;
        uint8 requirement;
        uint40 start;
        uint40 duration;
        uint40 currentBid; // in multiples of 1e18
        bool cancelled;
        address prizeNFT;
        uint40 prizeTokenId;
    }

    uint256 public numAuctions;
    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => mapping(address => uint256)) public bids;

    // Gouda constant gouda = Gouda(0x3aD30C5E3496BE07968579169a96f00D56De4C1A);
    // address constant genesis = Gouda(0x3ad30c5e2985e960e89f4a28efc91ba73e104b77);
    // address constant troupe = Gouda(0x74d9d90a7fc261fbe92ed47b606b6e0e00d75e70);

    Gouda immutable gouda;
    IMadMouse immutable genesis;
    IMadMouse immutable troupe;

    uint256 constant ONE_MONTH = 3600 * 24 * 7 * 4;
    uint256 constant AUCTION_EXTEND_DURATION = 5 * 60;

    constructor(
        Gouda gouda_,
        IMadMouse genesis_,
        IMadMouse troupe_
    ) {
        gouda = gouda_;
        genesis = genesis_;
        troupe = troupe_;
    }

    /* ------------- External ------------- */

    function placeBid(
        uint256 auctionId,
        uint40 bid,
        uint256 requirementData
    ) external noContract {
        Auction storage auction = auctions[auctionId];

        uint256 qualifierDuration = auction.qualifierDuration;

        if (bid <= auction.currentBid) revert BidTooLow();
        unchecked {
            uint256 start = uint256(auction.start) + auction.qualifierDuration;
            uint256 duration = auction.duration;

            if (duration < block.timestamp - start) revert AuctionInactive();

            uint256 end = start + duration;
            if (end - block.timestamp < AUCTION_EXTEND_DURATION) {
                auction.duration = uint40(duration + AUCTION_EXTEND_DURATION);
            }
        }

        if (auction.cancelled) revert AuctionCancelled();

        uint256 callerBid = bids[auctionId][msg.sender];

        // if callerBid is > qualifierDownpayment,
        // we don't have to re-evaluate qualifications,
        // since this check has already been performed
        if (callerBid <= 1) {
            uint256 requirement = auction.requirement;
            if (requirement != 0 && !fulfillsRequirement(msg.sender, requirement, requirementData))
                revert RequirementNotFulfilled();

            if (qualifierDuration != 0) {
                uint256 qualifierRandomSeed = auction.qualifierRandomSeed;
                if (qualifierRandomSeed == 0) revert QualifierSeedNotSet();
                if (callerBid == 0) revert QualifierNotEntered(); // non-zero for valid entry because of downpayment when entering qualifier
                uint256 roll = uint256(keccak256(abi.encodePacked(msg.sender, qualifierRandomSeed)));
                if (roll & 0xFFFF > auction.qualifierChance) revert QualifierNotEntered();
            }
        }

        unchecked {
            // type(uint40).max * 1e18 < 2^256: can't overflow
            // underflow assumption: callerBid <= auction.currentBid < bid
            gouda.transferFrom(msg.sender, address(this), (uint256(bid) - callerBid) * 1e18);
            emit BidPlaced(auctionId, msg.sender, uint256(bid) * 1e18);
        }

        bids[auctionId][msg.sender] = bid;
        auction.currentBid = bid;
    }

    function fulfillsRequirement(
        address user,
        uint256 requirement,
        uint256 data
    ) public returns (bool) {
        unchecked {
            if (requirement == 1 && genesis.numOwned(user) > 0) return true;
            if (requirement == 2 && troupe.numOwned(user) > 0) return true;
            if (
                requirement == 3 &&
                // specify data == 1 to direct that user is holding troupe and potentially save an sload;
                // or leave unspecified and worst-case check both
                ((data != 2 && troupe.numOwned(user) > 0) || (data != 1 && genesis.numOwned(user) > 0))
            ) return true;
            if (
                requirement == 4 &&
                (
                    data > 5000 // specify owner-held id: data > 5000 refers to genesis collection
                        ? genesis.getLevel(data - 5000) > 1 && genesis.ownerOf(data - 5000) == user
                        : troupe.getLevel(data) > 1 && troupe.ownerOf(data) == user
                )
            ) return true;
            if (
                requirement == 5 &&
                (
                    data > 5000
                        ? genesis.getLevel(data - 5000) > 2 && genesis.ownerOf(data - 5000) == user
                        : troupe.getLevel(data) > 2 && troupe.ownerOf(data) == user
                )
            ) return true;
            return false;
        }
    }

    function claimPrize(uint256 auctionId) external {
        resolveBid(auctionId);
    }

    function reclaimGouda(uint256 auctionId) external {
        resolveBid(auctionId);
    }

    function enterQualifier(uint256 auctionId, uint256 requirementData) external noContract {
        Auction storage auction = auctions[auctionId];
        if (++auction.qualifierNumEntrants > auction.qualifierMaxEntrants) revert QualifierMaxEntrantsReached();

        unchecked {
            if (auction.qualifierDuration < block.timestamp - auction.start) revert QualifierInactive();
        }

        uint256 requirement = auction.requirement;
        if (requirement != 0 && !fulfillsRequirement(msg.sender, requirement, requirementData))
            revert RequirementNotFulfilled();

        if (bids[auctionId][msg.sender] >= 1) revert QualifierAlreadyEntered();

        gouda.transferFrom(msg.sender, address(this), 1e18);
        bids[auctionId][msg.sender] = 1;
    }

    /* ------------- View ------------- */

    function qualifierChosen(uint256 auctionId, address user) external view returns (bool) {
        Auction storage auction = auctions[auctionId];

        if (auction.duration == 0) return false; // no qualifier required

        uint256 callerBid = bids[auctionId][user];
        if (callerBid == 0) return false; // downpayment signals successful qualifier entry

        uint256 qualifierRandomSeed = auction.qualifierRandomSeed;
        if (qualifierRandomSeed == 0) return false;

        uint256 roll = uint256(keccak256(abi.encodePacked(user, qualifierRandomSeed)));
        if (roll & 0xFFFF > auction.qualifierChance) return false;

        return true;
    }

    /* ------------- Private ------------- */

    function resolveBid(uint256 auctionId) private {
        Auction storage auction = auctions[auctionId];
        uint256 qualifierDuration = auction.qualifierDuration;
        uint256 end = auction.start + qualifierDuration + auction.duration;

        if (block.timestamp <= end && !auction.cancelled) revert AuctionOngoing();

        uint256 callerBid = bids[auctionId][msg.sender];
        delete bids[auctionId][msg.sender];

        if (callerBid == 0) revert NoBidPlaced();

        unchecked {
            if (auction.currentBid == callerBid) {
                IERC721(auction.prizeNFT).transferFrom(address(this), msg.sender, auction.prizeTokenId);
                gouda.burnFrom(address(this), callerBid * 1e18);
            } else {
                if (qualifierDuration != 0) callerBid -= 1; // keep the qualifier downpayment
                if (callerBid == 0) revert NoBidPlaced();
                gouda.transfer(msg.sender, callerBid * 1e18);
            }
        }
    }

    /* ------------- Owner ------------- */

    function createAuction(
        address nft,
        uint40 tokenId,
        uint16 qualifierMaxEntrants,
        uint40 qualifierDuration,
        uint16 qualifierChance,
        uint8 requirement,
        uint40 start,
        uint40 duration
    ) external onlyOwner {
        uint256 auctionId;
        unchecked {
            auctionId = ++numAuctions;
        }

        if (start < block.timestamp || duration > ONE_MONTH || qualifierDuration > ONE_MONTH) revert InvalidTimestamp();

        IERC721(nft).transferFrom(msg.sender, address(this), tokenId);

        Auction storage auction = auctions[auctionId];

        auction.qualifierMaxEntrants = qualifierMaxEntrants;
        auction.qualifierDuration = qualifierDuration;
        auction.qualifierChance = qualifierChance;

        auction.requirement = requirement;
        auction.start = start;
        auction.duration = duration;

        auction.prizeNFT = nft;
        auction.prizeTokenId = tokenId;
    }

    function cancelAuction(uint256 auctionId) external onlyOwner {
        Auction storage auction = auctions[auctionId];
        auction.cancelled = true;

        IERC721(auction.prizeNFT).transferFrom(address(this), msg.sender, auction.prizeTokenId);
    }

    function forcefulfillQualifier(uint256 auctionId) external onlyOwner {
        Auction storage auction = auctions[auctionId];

        uint256 qualifierDuration = auction.qualifierDuration;
        if (qualifierDuration == 0) revert QualifierNotRequired();

        uint256 start = auction.start;

        if (start < block.timestamp) revert QualifierRevealInvalidTimeFrame();
        if (auction.qualifierRandomSeed != 0) revert QualifierRandomSeedSet();

        // extend period by lost time waiting for reveal
        auction.qualifierDuration = uint40(block.timestamp - start + qualifierDuration);

        // FIX
        auction.qualifierRandomSeed = uint16(uint256(keccak256(abi.encode(block.timestamp))));
    }

    /* ------------- Modifier ------------- */

    modifier noContract() {
        if (msg.sender != tx.origin) revert ContractCallNotAllowed();
        _;
    }
}

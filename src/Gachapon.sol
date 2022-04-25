// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {Strings} from "../lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import {IERC721} from "../lib/openzeppelin-contracts/contracts/interfaces/IERC721.sol";

// import {VRFSubscriptionManagerMainnet as VRFSubscriptionManager} from "./lib/VRFSubscriptionManager.sol";
import {VRFSubscriptionManagerMock as VRFSubscriptionManager} from "./lib/VRFSubscriptionManager.sol";

import {IGouda, IMadMouse} from "./lib/interfaces.sol";
import {Ownable} from "./lib/Ownable.sol";
import {Choice} from "./lib/Choice.sol";
import {Gouda} from "./lib/Gouda.sol";

import {Tickets} from "./Tickets.sol";

import {console} from "../lib/forge-std/src/console.sol";

error RaffleNotActive();
error RaffleOngoing();
error RaffleRandomSeedSet();
error RaffleAlreadyCancelled();
error TicketsMaxSupplyReached();

error RaffleUnrevealed();
error PrizeAlreadyClaimed();

error BetterLuckNextTime();
error MachineBeDoinWork();
error NeedsMoarTickets();
error TicketsImplementationUnset();
error InvalidTimestamps();
error InvalidTicketPrice();
error RequirementNotFulfilled();

contract Gachapon is Ownable, VRFSubscriptionManager {
    using Strings for uint256;

    event Kachingg();
    event Grapple();
    event BZZzzt();

    struct Raffle {
        uint40 start;
        uint40 end;
        uint40 ticketSupply;
        uint40 maxTicketSupply;
        uint40 ticketPrice; // in multiples of 1e18
        uint8 requirement;
        uint16 refundRate;
        bool cancelled;
        address tickets;
        uint40 randomSeed;
        address prizeNFT;
        uint256[] prizeTokenIds;
        // can split off numPrizes
    }

    string ticketURI = "ipfs://QmSwrzsySKnkQmRQoZYmZ2XuJx3NMn2awdHwf1fezAJbq3/silver-ticket.json";
    string losingTicketURI = "ipfs://QmSwrzsySKnkQmRQoZYmZ2XuJx3NMn2awdHwf1fezAJbq3/red-ticket.json";
    string winningTicketURI = "ipfs://QmSwrzsySKnkQmRQoZYmZ2XuJx3NMn2awdHwf1fezAJbq3/gold-ticket.json";

    address ticketsImplementation;

    uint256 public numRaffles;
    mapping(uint256 => Raffle) private raffles;
    mapping(address => uint256) public ticketsToRaffleId;
    mapping(uint256 => uint256) requestIdToLot;

    mapping(uint256 => mapping(uint256 => bool)) public claimedPrize;

    uint256 constant ONE_MONTH = 3600 * 24 * 28;

    // Gouda constant gouda = Gouda(0x3aD30C5E3496BE07968579169a96f00D56De4C1A);
    // address constant genesis = Gouda(0x3ad30c5e2985e960e89f4a28efc91ba73e104b77);
    // address constant troupe = Gouda(0x74d9d90a7fc261fbe92ed47b606b6e0e00d75e70);

    Gouda immutable gouda;
    IMadMouse immutable genesis;
    IMadMouse immutable troupe;

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

    function buyTicket(uint256 raffleId, uint256 requirementData) external {
        Raffle storage raffle = raffles[raffleId];
        uint256 ticketSupply = raffle.ticketSupply;

        if (raffle.cancelled || raffle.end < block.timestamp || block.timestamp < raffle.start)
            revert RaffleNotActive();
        if (ticketSupply == raffle.maxTicketSupply) revert TicketsMaxSupplyReached();

        uint256 requirement = raffle.requirement;
        if (requirement != 0 && !fulfillsRequirement(msg.sender, requirement, requirementData))
            revert RequirementNotFulfilled();

        unchecked {
            gouda.transferFrom(msg.sender, address(this), raffle.ticketPrice * 1e18);
        }

        uint256 ticketId = ++ticketSupply;
        raffle.ticketSupply = uint40(ticketSupply);

        Tickets(raffle.tickets).mint(msg.sender, ticketId);
    }

    function claimPrize(uint256 raffleId, uint256 ticketId) external {
        Raffle storage raffle = raffles[raffleId];
        Tickets tickets = Tickets(raffle.tickets);

        uint256 randomSeed = raffle.randomSeed;

        if (raffle.cancelled) revert RaffleNotActive();
        if (randomSeed == 0) revert RaffleUnrevealed();

        uint256 numPrizes = raffle.prizeTokenIds.length;
        uint256 numEntrants = raffle.ticketSupply;

        (bool win, uint256 prizeId) = Choice.indexOfSelectNOfM(ticketId - 1, numPrizes, numEntrants, randomSeed);

        // don't burn, keep as a souvenir
        // tickets.burnFrom(msg.sender, ticketId);
        if (tickets.ownerOf(ticketId) != msg.sender || !win) revert BetterLuckNextTime();
        if (claimedPrize[raffleId][ticketId]) revert PrizeAlreadyClaimed();

        claimedPrize[raffleId][ticketId] = true;

        IERC721 prizeNFT = IERC721(raffle.prizeNFT);
        prizeNFT.transferFrom(address(this), msg.sender, raffle.prizeTokenIds[prizeId]);
    }

    function burnTickets(uint256[] calldata burnRaffleIds, uint256[] calldata burnTicketIds) external {
        Raffle storage raffle;

        uint256 refund;

        uint256 numBurnTickets = burnTicketIds.length;
        if (numBurnTickets == 0) revert NeedsMoarTickets();

        unchecked {
            for (uint256 i; i < numBurnTickets; ++i) {
                raffle = raffles[burnRaffleIds[i]];
                Tickets tickets = Tickets(raffle.tickets);

                tickets.burnFrom(msg.sender, burnTicketIds[i]);
                refund += (raffle.ticketPrice * 1e18 * raffle.refundRate) >> 16;
            }
        }

        gouda.transfer(msg.sender, refund);
    }

    /* ------------- View ------------- */

    function isWinningTicket(uint256 raffleId, uint256 ticketId) public view returns (bool) {
        Raffle storage raffle = raffles[raffleId];
        uint256 randomSeed = raffle.randomSeed;

        if (raffle.cancelled || randomSeed == 0) return false;

        uint256 numPrizes = raffle.prizeTokenIds.length;
        uint256 numEntrants = raffle.ticketSupply;

        (bool win, ) = Choice.indexOfSelectNOfM(ticketId - 1, numPrizes, numEntrants, randomSeed);
        return win;
    }

    function getWinningTickets(uint256 raffleId) public view returns (uint256[] memory ticketIds) {
        Raffle storage raffle = raffles[raffleId];

        uint256 randomSeed = raffle.randomSeed;

        if (raffle.cancelled || randomSeed == 0) return ticketIds;

        uint256 numPrizes = raffle.prizeTokenIds.length;
        uint256 numEntrants = raffle.ticketSupply;

        return Choice.selectNOfM(numPrizes, numEntrants, randomSeed, 1);
    }

    function getWinners(uint256 raffleId) public view returns (address[] memory winners) {
        Raffle storage raffle = raffles[raffleId];

        uint256 randomSeed = raffle.randomSeed;

        if (raffle.cancelled || randomSeed == 0) return winners;

        uint256 numPrizes = raffle.prizeTokenIds.length;
        uint256 numEntrants = raffle.ticketSupply;
        Tickets tickets = Tickets(raffle.tickets);

        uint256[] memory prizeTokenIds = Choice.selectNOfM(numPrizes, numEntrants, randomSeed, 1);
        uint256 numIds = prizeTokenIds.length;

        winners = new address[](numIds);
        for (uint256 i; i < numIds; ++i) winners[i] = tickets.ownerOf(prizeTokenIds[i]);
    }

    function getRaffle(uint256 raffleId) external view returns (Raffle memory) {
        return raffles[raffleId];
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

    /* ------------- Tickets Callbacks ------------- */

    function ticketsSupply() external view returns (uint256) {
        uint256 raffleId = ticketsToRaffleId[msg.sender];
        return raffles[raffleId].ticketSupply;
    }

    function ticketsName() external view returns (string memory) {
        uint256 raffleId = ticketsToRaffleId[msg.sender];
        return string.concat("Raffle Tickets #", raffleId.toString());
    }

    function ticketsSymbol() external view returns (string memory) {
        uint256 raffleId = ticketsToRaffleId[msg.sender];
        return string.concat("GRAFF", raffleId.toString());
    }

    function ticketsTokenURI(uint256 id) external view returns (string memory) {
        uint256 raffleId = ticketsToRaffleId[msg.sender];
        return
            raffles[raffleId].randomSeed != 0
                ? isWinningTicket(raffleId, id) ? winningTicketURI : losingTicketURI
                : ticketURI;
    }

    /* ------------- Owner ------------- */

    function feedToys(
        address prizeNFT,
        uint256[] calldata prizeTokenIds,
        uint40 start,
        uint40 end,
        uint40 ticketPrice,
        uint16 refundRate,
        uint40 maxTicketSupply,
        uint8 requirement
    ) external onlyOwner {
        for (uint256 i; i < prizeTokenIds.length; ++i)
            IERC721(prizeNFT).transferFrom(msg.sender, address(this), prizeTokenIds[i]);

        uint256 raffleId = ++numRaffles;
        Raffle storage raffle = raffles[raffleId];

        if (ticketsImplementation == address(0)) revert TicketsImplementationUnset();
        if (start < block.timestamp || end <= start || end - start > ONE_MONTH) revert InvalidTimestamps();
        if (ticketPrice >= 1e18) revert InvalidTicketPrice();

        address tickets = createClone(ticketsImplementation);
        ticketsToRaffleId[tickets] = raffleId;

        raffle.tickets = tickets;
        raffle.prizeNFT = prizeNFT;
        raffle.prizeTokenIds = prizeTokenIds;
        raffle.start = start;
        raffle.end = end;
        raffle.ticketPrice = ticketPrice;
        raffle.refundRate = refundRate;
        raffle.maxTicketSupply = maxTicketSupply;
        raffle.requirement = requirement;

        emit Kachingg();
    }

    function rescueToys(address prizeNFT, uint256[] calldata prizeTokenIds) external onlyOwner {
        for (uint256 i; i < prizeTokenIds.length; ++i)
            IERC721(prizeNFT).transferFrom(address(this), msg.sender, prizeTokenIds[i]);
    }

    function cancelRaffle(uint256 raffleId) external onlyOwner {
        Raffle storage raffle = raffles[raffleId];

        uint256 numToys = raffle.prizeTokenIds.length;

        if (raffle.cancelled) revert RaffleAlreadyCancelled();

        IERC721 prizeNFT = IERC721(raffle.prizeNFT);
        for (uint256 i; i < numToys; ++i)
            prizeNFT.transferFrom(address(this), msg.sender, raffles[raffleId].prizeTokenIds[i]);

        raffle.cancelled = true;
    }

    function initiateGrappler(uint256 raffleId) external onlyOwner {
        Raffle storage raffle = raffles[raffleId];

        if (raffle.cancelled) revert RaffleNotActive();
        if (block.timestamp <= raffle.end) revert RaffleOngoing();
        if (raffle.randomSeed != 0) revert RaffleRandomSeedSet();

        uint256 requestId = requestRandomWords();
        requestIdToLot[requestId] = raffleId;

        emit Grapple();
        emit Grapple();
    }

    function setTicketsImplementation(address ticketsImplementation_) external onlyOwner {
        ticketsImplementation = ticketsImplementation_;
    }

    function setWinningTicketURI(string calldata uri) external onlyOwner {
        winningTicketURI = uri;
    }

    function setLosingTicketURI(string calldata uri) external onlyOwner {
        losingTicketURI = uri;
    }

    function setTicketURI(string calldata uri) external onlyOwner {
        ticketURI = uri;
    }

    function kickStuckMachine(uint256 raffleId) external onlyOwner {
        Raffle storage raffle = raffles[raffleId];

        if (raffle.cancelled) revert RaffleNotActive();
        if (block.timestamp < raffle.end) revert RaffleOngoing();
        if (raffle.randomSeed != 0) revert MachineBeDoinWork();

        emit BZZzzt();
        // on-chain requires block.number - 1, forge block number starts at 0 and errs...
        // raffle.randomSeed = uint256(blockhash(block.number - 1));
        // @note FIX
        raffle.randomSeed = uint40(uint256(keccak256(abi.encode(block.timestamp))));
    }

    /* ------------- Internal ------------- */

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 raffleId = requestIdToLot[requestId];
        delete requestIdToLot[requestId];

        Raffle storage raffle = raffles[raffleId];
        if (!raffle.cancelled && raffle.randomSeed == 0) {
            emit BZZzzt();
            raffle.randomSeed = uint40(randomWords[0]);
        }
    }

    // https://github.com/optionality/clone-factory/blob/master/contracts/CloneFactory.sol
    function createClone(address target) private returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }
}

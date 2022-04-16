// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {Strings} from "../lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import {IERC721} from "../lib/openzeppelin-contracts/contracts/interfaces/IERC721.sol";

// import {VRFSubscriptionManagerMainnet as VRFSubscriptionManager} from "./lib/VRFSubscriptionManager.sol";
import {VRFSubscriptionManagerMock as VRFSubscriptionManager} from "./lib/VRFSubscriptionManager.sol";

import {IGouda} from "./lib/interfaces.sol";
import {Ownable} from "./lib/Ownable.sol";
import {Choice} from "./lib/Choice.sol";

import {Tickets} from "./Tickets.sol";

import {console} from "../lib/forge-std/src/console.sol";

error RaffleNotActive();
error RaffleOngoing();
error RaffleRandomSeedSet();
error TicketsMaxSupplyReached();

error RaffleUnrevealed();

error BetterLuckNextTime();
error MachineBeDoinWork();
error NeedsMoarTickets();
error TicketsImplementationUnset();
error InvalidTimestamps();

contract Gachapon is Ownable, VRFSubscriptionManager {
    using Strings for uint256;

    event Kachingg();
    event Grapple();
    event BZZzzt();

    struct Raffle {
        uint256 start;
        uint256 end;
        uint256 price;
        address tickets;
        uint256 ticketSupply;
        uint256 maxSupply;
        uint256 requirement;
        address[] toys;
        uint256[] ids;
        uint256 randomSeed;
        bool cancelled;
    }

    string ticketURI;
    string losingTicketURI;
    string winningTicketURI;

    IGouda public gouda;
    address ticketsImplementation;

    uint256 public numRaffles;
    mapping(uint256 => Raffle) raffles;
    mapping(address => uint256) ticketsToRaffleId;
    mapping(uint256 => uint256) requestIdToLot;
    mapping(uint256 => string) raffleNames;

    uint256 raffleRefund = 80;

    /* ------------- External ------------- */

    function buyTicket(uint256 raffleId) external {
        Raffle storage raffle = raffles[raffleId];
        uint256 ticketSupply = raffle.ticketSupply;

        // console.log("ticketsupply", ticketSupply);
        // console.log("maxsupply", raffle.maxSupply);

        if (raffle.cancelled || raffle.end < block.timestamp || block.timestamp < raffle.start)
            revert RaffleNotActive();
        if (ticketSupply == raffle.maxSupply) revert TicketsMaxSupplyReached();

        gouda.transferFrom(msg.sender, address(this), raffle.price);

        uint256 ticketId = ++raffle.ticketSupply;
        Tickets(raffle.tickets).mint(msg.sender, ticketId);
    }

    function claimPrize(uint256 raffleId, uint256 ticketId) external {
        Raffle storage raffle = raffles[raffleId];
        Tickets tickets = Tickets(raffle.tickets);

        uint256 randomSeed = raffle.randomSeed;

        if (raffle.cancelled) revert RaffleNotActive();
        if (randomSeed == 0) revert RaffleUnrevealed();

        uint256 numPrizes = raffle.ids.length;
        uint256 numEntrants = raffle.ticketSupply;

        (bool win, uint256 prizeId) = Choice.indexOfSelectNOfM(ticketId - 1, numPrizes, numEntrants, randomSeed);

        if (!win) revert BetterLuckNextTime();

        tickets.burnFrom(msg.sender, ticketId);
        IERC721(raffle.toys[prizeId]).transferFrom(address(this), msg.sender, raffle.ids[prizeId]);
    }

    function burnTickets(uint256[] calldata burnRaffleIds, uint256[] calldata burnTicketIds) external {
        Raffle storage raffle;

        uint256 refund;
        uint256 raffleRefundRate = raffleRefund;

        uint256 numBurnTickets = burnTicketIds.length;
        if (numBurnTickets == 0) revert NeedsMoarTickets();

        unchecked {
            for (uint256 i; i < numBurnTickets; ++i) {
                raffle = raffles[burnRaffleIds[i]];
                Tickets tickets = Tickets(raffle.tickets);

                tickets.burnFrom(msg.sender, burnTicketIds[i]);
                refund += (raffle.price * raffleRefundRate) / 100;
            }
        }

        gouda.transferFrom(address(this), msg.sender, refund);
    }

    /* ------------- View ------------- */

    function isWinningTicket(uint256 raffleId, uint256 ticketId) public view returns (bool) {
        Raffle storage raffle = raffles[raffleId];
        uint256 randomSeed = raffle.randomSeed;

        if (raffle.cancelled || randomSeed == 0) return false;

        uint256 numPrizes = raffle.ids.length;
        uint256 numEntrants = raffle.ticketSupply;

        (bool win, ) = Choice.indexOfSelectNOfM(ticketId - 1, numPrizes, numEntrants, randomSeed);
        return win;
    }

    function getWinningTickets(uint256 raffleId) public view returns (uint256[] memory ids) {
        Raffle storage raffle = raffles[raffleId];

        uint256 randomSeed = raffle.randomSeed;

        if (raffle.cancelled || randomSeed == 0) return ids;

        uint256 numPrizes = raffle.ids.length;
        uint256 numEntrants = raffle.ticketSupply;

        return Choice.selectNOfM(numPrizes, numEntrants, randomSeed, 1);
    }

    function getWinners(uint256 raffleId) public view returns (address[] memory winners) {
        Raffle storage raffle = raffles[raffleId];

        uint256 randomSeed = raffle.randomSeed;

        if (raffle.cancelled || randomSeed == 0) return winners;

        uint256 numPrizes = raffle.ids.length;
        uint256 numEntrants = raffle.ticketSupply;
        Tickets tickets = Tickets(raffle.tickets);

        uint256[] memory ids = Choice.selectNOfM(numPrizes, numEntrants, randomSeed, 1);
        uint256 numIds = ids.length;

        winners = new address[](numIds);
        for (uint256 i; i < numIds; ++i) winners[i] = tickets.ownerOf(ids[i]);
    }

    function getRaffleTickets(uint256 raffleId) external view returns (address) {
        return raffles[raffleId].tickets;
    }

    function queryRaffles(uint256 from, uint256 to)
        external
        view
        returns (
            address[] memory tickets,
            uint256[] memory start,
            uint256[] memory end,
            uint256[] memory price,
            uint256[] memory requirement,
            uint256[] memory ticketSupply,
            uint256[] memory maxSupply,
            // uint256[] memory ticketBalance,
            address[][] memory toys,
            uint256[][] memory ids
        )
    {
        tickets = new address[](to - from);
        start = new uint256[](to - from);
        end = new uint256[](to - from);
        price = new uint256[](to - from);

        toys = new address[][](to - from);
        ids = new uint256[][](to - from);

        ticketSupply = new uint256[](to - from);
        maxSupply = new uint256[](to - from);
        // ticketBalance = new uint256[](to - from);

        requirement = new uint256[](to - from);

        for (uint256 i; i < to - from; ++i) {
            tickets[i] = raffles[from + i].tickets;
            start[i] = raffles[from + i].start;
            end[i] = raffles[from + i].end;
            price[i] = raffles[from + i].price;
            requirement[i] = raffles[from + i].requirement;
            toys[i] = raffles[from + i].toys;
            ids[i] = raffles[from + i].ids;

            // ticketBalance[i] = Tickets(raffles[from + i].tickets).balanceOf(msg.sender);
            ticketSupply[i] = raffles[from + i].ticketSupply;
            maxSupply[i] = raffles[from + i].maxSupply;
        }
    }

    /* ------------- Tickets Callbacks ------------- */

    function ticketsSupply() external view returns (uint256) {
        uint256 raffleId = ticketsToRaffleId[msg.sender];
        return raffles[raffleId].ticketSupply;
    }

    function ticketsName() external view returns (string memory) {
        uint256 raffleId = ticketsToRaffleId[msg.sender];
        string memory name = raffleNames[raffleId];
        if (bytes(name).length == 0) return string.concat("Gouda Raffle #", raffleId.toString());
        return name;
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
        address[] calldata toys,
        uint256[] calldata ids,
        uint256 start,
        uint256 end,
        uint256 requirement,
        uint256 price,
        uint256 maxSupply
    ) external onlyOwner {
        for (uint256 i; i < toys.length; ++i) IERC721(toys[i]).transferFrom(msg.sender, address(this), ids[i]);

        uint256 raffleId = ++numRaffles;
        Raffle storage raffle = raffles[raffleId];

        if (ticketsImplementation == address(0)) revert TicketsImplementationUnset();
        if (end < start) revert InvalidTimestamps();
        // if (end < start || start < block.timestamp) revert InvalidTimestamps();

        address tickets = createClone(ticketsImplementation);
        ticketsToRaffleId[tickets] = raffleId;

        raffle.tickets = tickets;
        raffle.toys = toys;
        raffle.ids = ids;
        raffle.start = start;
        raffle.end = end;
        raffle.price = price;
        raffle.maxSupply = maxSupply;
        raffle.requirement = requirement;

        emit Kachingg();
    }

    function rescueToys(address[] calldata toys, uint256[] calldata ids) external onlyOwner {
        for (uint256 i; i < toys.length; ++i) IERC721(toys[i]).transferFrom(address(this), msg.sender, ids[i]);
    }

    function cancelRaffle(uint256 raffleId) external onlyOwner {
        Raffle storage raffle = raffles[raffleId];

        uint256 numToys = raffle.toys.length;

        // @note check cancelled
        // raffle.cancelled = true;

        for (uint256 i; i < numToys; ++i)
            IERC721(raffle.toys[i]).transferFrom(address(this), msg.sender, raffles[raffleId].ids[i]);

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

    function setRaffleRefund(uint256 percentage) external onlyOwner {
        raffleRefund = percentage;
    }

    function setGouda(IGouda gouda_) external onlyOwner {
        gouda = gouda_;
    }

    function setRaffleName(uint256 raffleId, string calldata name) external onlyOwner {
        raffleNames[raffleId] = name;
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
        // on-chain requires block.number - 1, forge block number starts at 0...
        // raffle.randomSeed = uint256(blockhash(block.number - 1));
        // @note FIX
        raffle.randomSeed = uint256(keccak256(abi.encode(raffleId)));
    }

    /* ------------- Internal ------------- */

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 raffleId = requestIdToLot[requestId];
        delete requestIdToLot[requestId];

        Raffle storage raffle = raffles[raffleId];
        if (!raffle.cancelled && raffle.randomSeed == 0) {
            emit BZZzzt();
            raffle.randomSeed = randomWords[0];
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

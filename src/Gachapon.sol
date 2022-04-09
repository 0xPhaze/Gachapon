// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";

import {Ownable} from "./lib/Ownable.sol";
import {Choice} from "./lib/Choice.sol";
// import {VRFSubscriptionManagerMainnet as VRFSubscriptionManager} from "./lib/VRFSubscriptionManager.sol";
import {VRFSubscriptionManagerMock as VRFSubscriptionManager} from "./lib/VRFSubscriptionManager.sol";
import {Tickets} from "./Tickets.sol";
import {IGouda} from "./lib/interfaces.sol";

// import {console} from "../node_modules/forge-std/src/console.sol";

error RaffleNotActive();
error RaffleOngoing();
error RaffleRandomSeedSet();
error TicketsMaxSupplyReached();

error CallerNotOwner();
error RaffleUnrevealed();

error BetterLuckNextTime();
error MachineBeDoinWork();
error NeedsMoarTickets();
error TicketsImplementationUnset();

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
        address[] toys;
        uint256[] ids;
        uint256 randomSeed;
        bool active;
    }

    IGouda public gouda;
    address ticketsImplementation;

    uint256 public numRaffles;
    mapping(uint256 => Raffle) raffles;
    mapping(address => uint256) ticketsToRaffleId;
    mapping(uint256 => uint256) requestIdToLot;
    mapping(uint256 => string) raffleNames;

    uint256 raffleRefund = 80;

    /* ------------- External ------------- */

    function feedGouda(uint256 raffleId) external {
        Raffle storage raffle = raffles[raffleId];
        uint256 ticketSupply = raffle.ticketSupply;

        if (!raffle.active || raffle.end < block.timestamp || block.timestamp < raffle.start) revert RaffleNotActive();
        if (ticketSupply + 1 > raffle.maxSupply) revert TicketsMaxSupplyReached();

        gouda.transferFrom(msg.sender, address(this), raffle.price);

        uint256 ticketId = raffle.ticketSupply++;
        Tickets(raffle.tickets).mint(msg.sender, ticketId);
    }

    function claimPrize(uint256 raffleId, uint256 ticketId) external {
        Raffle storage raffle = raffles[raffleId];
        Tickets tickets = Tickets(raffle.tickets);

        uint256 randomSeed = raffle.randomSeed;

        if (randomSeed == 0) revert RaffleUnrevealed();
        if (!raffle.active) revert RaffleNotActive();

        uint256 numPrizes = raffle.ids.length;
        uint256 numEntrants = raffle.ticketSupply;

        (bool win, uint256 prizeId) = Choice.indexOfSelectNOfM(ticketId, numPrizes, numEntrants, randomSeed);

        if (!win) revert BetterLuckNextTime();

        tickets.burnFrom(msg.sender, ticketId);
        IERC721(raffle.toys[prizeId]).transferFrom(address(this), msg.sender, prizeId);
    }

    function burnTickets(
        uint256 raffleId,
        uint256[] calldata scrapRaffleIds,
        uint256[] calldata scrapTicketIds
    ) external {
        if (scrapTicketIds.length != 3) revert NeedsMoarTickets();

        Raffle storage raffle;
        uint256 refund;

        unchecked {
            for (uint256 i; i < scrapRaffleIds.length; ++i) {
                raffle = raffles[scrapRaffleIds[i]];
                Tickets tickets = Tickets(raffle.tickets);

                tickets.burnFrom(msg.sender, scrapTicketIds[i]);
                refund += (raffle.price * raffleRefund) / 100;
            }
        }

        gouda.transferFrom(address(this), msg.sender, refund);

        raffle = raffles[raffleId];
        if (!raffle.active || raffle.end < block.timestamp || block.timestamp < raffle.start) revert RaffleNotActive();

        if (raffle.price > refund) gouda.transferFrom(msg.sender, address(this), raffle.price - refund);
        else gouda.transferFrom(address(this), msg.sender, refund - raffle.price);

        uint256 ticketId = raffle.ticketSupply++;
        Tickets(raffle.tickets).mint(msg.sender, ticketId);
    }

    function redeemGouda(uint256 raffleId, uint256 ticketId) external {
        Raffle storage raffle = raffles[raffleId];

        if (!raffle.active) revert RaffleNotActive();
        if (raffle.end < block.timestamp || block.timestamp < raffle.start) revert RaffleNotActive();

        Tickets tickets = Tickets(raffle.tickets);
        tickets.burnFrom(msg.sender, ticketId);

        uint256 refund;
        unchecked {
            refund = (raffle.price * raffleRefund) / 100;
        }

        gouda.transferFrom(address(this), msg.sender, refund);
    }

    /* ------------- View ------------- */

    function isGoldenTicket(uint256 raffleId, uint256 ticketId) public view returns (bool) {
        Raffle storage raffle = raffles[raffleId];
        uint256 randomSeed = raffle.randomSeed;

        if (!raffle.active || randomSeed == 0) return false;

        uint256 numPrizes = raffle.ids.length;
        uint256 numEntrants = raffle.ticketSupply;

        (bool win, ) = Choice.indexOfSelectNOfM(ticketId, numPrizes, numEntrants, randomSeed);
        return win;
    }

    function getRaffleWinners(uint256 raffleId) public view returns (address[] memory winners) {
        Raffle storage raffle = raffles[raffleId];
        Tickets tickets = Tickets(raffle.tickets);
        uint256 randomSeed = raffle.randomSeed;

        if (!raffle.active || randomSeed == 0) return winners;

        uint256 numPrizes = raffle.ids.length;
        uint256 numEntrants = raffle.ticketSupply;

        uint256[] memory winnerIds = Choice.selectNOfM(numPrizes, numEntrants, randomSeed);

        winners = new address[](numPrizes);
        unchecked {
            for (uint256 i; i < numPrizes; ++i) winners[i] = tickets.ownerOf(winnerIds[i]);
        }

        return winners;
    }

    function getRaffleTickets(uint256 raffleId) external view returns (address) {
        return raffles[raffleId].tickets;
    }

    function getRaffleName(uint256 raffleId) external view returns (string memory) {
        string memory name = raffleNames[raffleId];
        if (bytes(name).length == 0) return string.concat("Gouda Raffle #", raffleId.toString());
        return name;
    }

    function queryRaffles(uint256 from, uint256 to)
        external
        view
        returns (
            address[] memory tickets,
            uint256[] memory start,
            uint256[] memory end,
            uint256[] memory price,
            bool[] memory active,
            uint256[] memory ticketSupply,
            uint256[] memory maxSupply,
            address[][] memory toys,
            uint256[][] memory ids,
            address[][] memory winners
        )
    {
        uint256 numTotal = to - from;
        Raffle storage raffle;

        tickets = new address[](numTotal);
        start = new uint256[](numTotal);
        end = new uint256[](numTotal);
        price = new uint256[](numTotal);
        active = new bool[](numTotal);

        toys = new address[][](numTotal);
        ids = new uint256[][](numTotal);

        ticketSupply = new uint256[](numTotal);
        maxSupply = new uint256[](numTotal);

        winners = new address[][](numTotal);

        for (uint256 i = from; i < to; ++i) {
            raffle = raffles[i];

            tickets[i] = raffle.tickets;
            start[i] = raffle.start;
            end[i] = raffle.end;
            price[i] = raffle.price;
            active[i] = raffle.active;
            toys[i] = raffle.toys;
            ids[i] = raffle.ids;

            ticketSupply[i] = raffle.ticketSupply;
            maxSupply[i] = raffle.maxSupply;

            winners[i] = getRaffleWinners(i);
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
            isGoldenTicket(raffleId, id)
                ? "ipfs://QmcU3dhpgV9uWwgWQ7aPCsyZSYZDZMCKj1FrDJCEQAceoP/winning-ticket.json"
                : "ipfs://QmcU3dhpgV9uWwgWQ7aPCsyZSYZDZMCKj1FrDJCEQAceoP/raffle-ticket.json";
    }

    /* ------------- Owner ------------- */

    function feedToys(
        address[] calldata toys,
        uint256[] calldata ids,
        uint256 start,
        uint256 end,
        uint256 price,
        uint256 maxSupply
    ) external onlyOwner {
        for (uint256 i; i < toys.length; ++i) IERC721(toys[i]).transferFrom(msg.sender, address(this), ids[i]);

        uint256 raffleId = numRaffles++;
        Raffle storage raffle = raffles[raffleId];

        if (ticketsImplementation == address(0)) revert TicketsImplementationUnset();

        address tickets = createClone(ticketsImplementation);
        ticketsToRaffleId[tickets] = raffleId;

        raffle.tickets = tickets;
        raffle.toys = toys;
        raffle.ids = ids;
        raffle.start = start;
        raffle.end = end;
        raffle.price = price;
        raffle.maxSupply = maxSupply;
        raffle.active = true;

        emit Kachingg();
    }

    function rescueToys(uint256 raffleId) external onlyOwner {
        Raffle storage raffle = raffles[raffleId];

        uint256 numToys = raffle.toys.length;

        for (uint256 i; i < numToys; ++i) {
            IERC721(raffle.toys[i]).transferFrom(address(this), msg.sender, raffles[raffleId].ids[i]);
            delete raffle.toys;
            delete raffle.ids;
        }

        raffle.active = false;
    }

    function initiateGrappler(uint256 raffleId) external onlyOwner {
        Raffle storage raffle = raffles[raffleId];

        if (!raffle.active) revert RaffleNotActive();
        if (block.timestamp < raffle.end) revert RaffleOngoing();
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

    function kickStuckMachine(uint256 raffleId) external onlyOwner {
        Raffle storage raffle = raffles[raffleId];

        if (!raffle.active) revert RaffleNotActive();
        if (block.timestamp < raffle.end) revert RaffleOngoing();
        if (raffle.randomSeed != 0) revert MachineBeDoinWork();

        emit BZZzzt();
        // @note check if this has to be -1
        // raffle.randomSeed = uint256(blockhash(block.number - 1));
        raffle.randomSeed = uint256(blockhash(block.number));
    }

    /* ------------- Internal ------------- */

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 raffleId = requestIdToLot[requestId];
        delete requestIdToLot[requestId];

        Raffle storage raffle = raffles[raffleId];
        if (raffle.active && raffle.randomSeed == 0) {
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

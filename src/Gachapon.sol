// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";

import {Ownable} from "./lib/Ownable.sol";
import {Choice} from "./lib/Choice.sol";
// import {VRFSubscriptionManagerMainnet as VRFSubscriptionManager} from "./lib/VRFSubscriptionManager.sol";
import {VRFSubscriptionManagerMock as VRFSubscriptionManager} from "./lib/VRFSubscriptionManager.sol";
import {Tickets} from "./Ticket.sol";
import {IGouda} from "./lib/interfaces.sol";

// import {console} from "../node_modules/forge-std/src/console.sol";

error RaffleNotActive();
error RaffleOngoing();
error RaffleRandomSeedSet();
error CallerNotOwner();
error RaffleUnrevealed();

error BetterLuckNextTime();
error MachineBeDoinWork();
error NeedsMoarTickets();

contract Gachapon is Ownable, VRFSubscriptionManager {
    using Strings for uint256;

    event Kachingg();
    event Grapple();
    event BZZzzt();

    struct Raffle {
        address[] toys;
        uint256[] ids;
        address tickets;
        uint256 start;
        uint256 end;
        uint256 price;
        uint256 randomSeed;
        bool active;
    }

    IGouda gouda;
    uint256 public numRaffles;
    mapping(uint256 => Raffle) public raffles;
    mapping(uint256 => uint256) requestIdToLot;

    uint256 raffleRefund = 80;

    /* ------------- External ------------- */

    function feedGouda(uint256 raffleId) external {
        Raffle storage raffle = raffles[raffleId];
        if (
            !raffle.active ||
            raffle.end < block.timestamp ||
            block.timestamp < raffle.start
        ) revert RaffleNotActive();

        gouda.transferFrom(msg.sender, address(this), raffle.price);
        Tickets(raffle.tickets).mint(msg.sender);
    }

    function claimPrize(uint256 raffleId, uint256 ticketId) external {
        Raffle storage raffle = raffles[raffleId];
        Tickets tickets = Tickets(raffle.tickets);

        uint256 randomSeed = raffle.randomSeed;

        if (randomSeed == 0) revert RaffleUnrevealed();
        if (!raffle.active) revert RaffleNotActive();

        uint256 numPrizes = raffle.ids.length;
        uint256 numEntrants = tickets.totalSupply();

        (bool win, uint256 prizeId) = Choice.indexOfSelectNOfM(
            ticketId,
            numPrizes,
            numEntrants,
            randomSeed
        );

        if (!win) revert BetterLuckNextTime();

        tickets.burnFrom(msg.sender, ticketId);
        IERC721(raffle.toys[prizeId]).transferFrom(
            address(this),
            msg.sender,
            prizeId
        );
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
        if (
            !raffle.active ||
            raffle.end < block.timestamp ||
            block.timestamp < raffle.start
        ) revert RaffleNotActive();
        if (raffle.price > refund) {
            gouda.transferFrom(
                msg.sender,
                address(this),
                raffle.price - refund
            );
        } else {
            gouda.transferFrom(
                address(this),
                msg.sender,
                refund - raffle.price
            );
        }

        Tickets(raffle.tickets).mint(msg.sender);
    }

    function redeemGouda(uint256 raffleId, uint256 ticketId) external {
        Raffle storage raffle = raffles[raffleId];
        if (!raffle.active) revert RaffleNotActive();
        if (raffle.end < block.timestamp || block.timestamp < raffle.start)
            revert RaffleNotActive();

        Tickets tickets = Tickets(raffle.tickets);
        tickets.burnFrom(msg.sender, ticketId);

        uint256 refund;
        unchecked {
            refund = (raffle.price * raffleRefund) / 100;
        }

        gouda.transferFrom(address(this), msg.sender, refund);
    }

    /* ------------- View ------------- */

    function isGoldenTicket(uint256 raffleId, uint256 ticketId)
        external
        view
        returns (bool)
    {
        Raffle storage raffle = raffles[raffleId];
        Tickets tickets = Tickets(raffle.tickets);
        uint256 randomSeed = raffle.randomSeed;

        if (!raffle.active) revert RaffleNotActive();
        if (randomSeed == 0) return false;

        uint256 numPrizes = raffle.ids.length;
        uint256 numEntrants = tickets.totalSupply();

        (bool win, ) = Choice.indexOfSelectNOfM(
            ticketId,
            numPrizes,
            numEntrants,
            randomSeed
        );
        return win;
    }

    function getRaffleWinners(uint256 raffleId)
        public
        view
        returns (address[] memory winners)
    {
        Raffle storage raffle = raffles[raffleId];
        Tickets tickets = Tickets(raffle.tickets);
        uint256 randomSeed = raffle.randomSeed;

        if (randomSeed == 0 || !raffle.active) return winners;

        uint256 numPrizes = raffle.ids.length;
        uint256 numEntrants = tickets.totalSupply();

        uint256[] memory winnerIds = Choice.selectNOfM(
            numPrizes,
            numEntrants,
            randomSeed
        );

        winners = new address[](numPrizes);
        unchecked {
            for (uint256 i; i < numPrizes; ++i)
                winners[i] = tickets.ownerOf(winnerIds[i]);
        }

        return winners;
    }

    function getAllRaffles()
        external
        view
        returns (
            address[][] memory toys,
            uint256[][] memory ids,
            address[] memory tickets,
            uint256[] memory start,
            uint256[] memory end,
            uint256[] memory price,
            bool[] memory active,
            address[][] memory winners
        )
    {
        Raffle storage raffle;

        toys = new address[][](numRaffles);
        ids = new uint256[][](numRaffles);
        tickets = new address[](numRaffles);
        start = new uint256[](numRaffles);
        end = new uint256[](numRaffles);
        price = new uint256[](numRaffles);
        active = new bool[](numRaffles);
        winners = new address[][](numRaffles);

        for (uint256 i; i < numRaffles; ++i) {
            raffle = raffles[i];

            toys[i] = raffle.toys;
            ids[i] = raffle.ids;
            tickets[i] = raffle.tickets;
            start[i] = raffle.start;
            end[i] = raffle.end;
            price[i] = raffle.price;
            active[i] = raffle.active;

            winners[i] = getRaffleWinners(i);
        }
    }

    /* ------------- Owner ------------- */

    function feedToys(
        address[] calldata toys,
        uint256[] calldata ids,
        uint256 start,
        uint256 end,
        uint256 price
    ) external onlyOwner {
        for (uint256 i; i < toys.length; ++i)
            IERC721(toys[i]).transferFrom(msg.sender, address(this), ids[i]);

        uint256 raffleId = numRaffles++;
        Raffle storage raffle = raffles[raffleId];

        string memory name = string.concat(
            "Gouda Raffle #",
            raffleId.toString()
        );
        string memory symbol = string.concat("GRAFF", raffleId.toString());

        raffle.tickets = address(new Tickets(raffleId, name, symbol));
        raffle.toys = toys;
        raffle.ids = ids;
        raffle.start = start;
        raffle.end = end;
        raffle.price = price;
        raffle.active = true;

        // console.logBytes(abi.encode(raffle.toys));

        emit Kachingg();
    }

    function rescueToys(uint256 raffleId) external onlyOwner {
        Raffle storage raffle = raffles[raffleId];

        for (uint256 i; i < raffles[raffleId].toys.length; ++i)
            IERC721(raffle.toys[i]).transferFrom(
                address(this),
                msg.sender,
                raffles[raffleId].ids[i]
            );

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

    function setGouda(IGouda gouda_) external onlyOwner {
        gouda = gouda_;
    }

    function kickStuckMachine(uint256 raffleId) external onlyOwner {
        Raffle storage raffle = raffles[raffleId];

        if (raffle.randomSeed != 0) revert MachineBeDoinWork();

        emit BZZzzt();
        raffle.randomSeed = uint256(blockhash(block.number - 1));
    }

    /* ------------- Internal ------------- */

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        uint256 raffleId = requestIdToLot[requestId];
        delete requestIdToLot[requestId];

        Raffle storage raffle = raffles[raffleId];
        if (raffle.active && raffle.randomSeed == 0) {
            emit BZZzzt();
            raffle.randomSeed = randomWords[0];
        }
    }
}

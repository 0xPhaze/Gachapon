// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {DSTestPlus} from "../../lib/solmate/src/test/utils/DSTestPlus.sol";
import {Vm} from "../../lib/forge-std/src/Vm.sol";
import {stdCheats} from "../../lib/forge-std/src/stdlib.sol";
import {console} from "../../lib/forge-std/src/console.sol";

import {MockERC721} from "../../lib/solmate/src/test/utils/mocks/MockERC721.sol";
import {MockERC20} from "../../lib/solmate/src/test/utils/mocks/MockERC20.sol";

import {IGouda} from "../lib/interfaces.sol";
import {MockMadMouse} from "./mocks/MockMadMouse.sol";
import {MockGouda} from "./mocks/MockGouda.sol";

import {ArrayUtils} from "./ArrayUtils.sol";

import "../Gachapon.sol";

contract TestGachapon is DSTestPlus, stdCheats {
    using ArrayUtils for *;

    Vm vm = Vm(HEVM_ADDRESS);

    MockGouda gouda;
    MockMadMouse troupe;
    MockMadMouse genesis;

    Gachapon gachapon;
    Tickets ticketsImpl;

    address bob = address(0xb0b);
    address alice = address(0xbabe);
    address tester = address(this);

    event log_array(uint256[] arr);
    event log_arrayAddress(address[] arr);

    function setUp() public {
        gouda = new MockGouda();
        troupe = new MockMadMouse();
        genesis = new MockMadMouse();

        gachapon = new Gachapon(IGouda(address(gouda)), IMadMouse(address(genesis)), IMadMouse(address(troupe)));
        ticketsImpl = new Tickets(gachapon);

        gachapon.setTicketsImplementation(address(ticketsImpl));

        vm.label(bob, "bob");
        vm.label(alice, "alice");
        vm.label(tester, "tester");

        vm.label(address(gachapon), "gachapon");
    }

    /* ------------- Helpers ------------- */

    // function initializeMockRaffle() public {
    //     ids = [3877, 5592, 8877, 9048, 9911].toMemory32();
    //     for (uint256 i; i < ids.length; ++i) mock.mint(deployer, ids[i]);
    //     gachapon.feedToys(
    //         address(mock),
    //         ids,
    //         uint40(block.timestamp),
    //         uint40(block.timestamp + 10),
    //         7,
    //         uint16((uint256(type(uint16).max) * 66) / 100),
    //         30,
    //         0
    //     );

    //     (address[] memory toys, uint256[] memory ids) = generateMockToys(tester, 8, 21);

    //     for (uint256 i; i < 8; i++) IERC721(toys[i]).setApprovalForAll(address(gachapon), true);

    //     gachapon.feedToys(toys, ids, block.timestamp + 100, block.timestamp + 300, 0, 600, 30);
    // }

    function assertEqArray(uint256[] memory a, uint256[] memory b) internal {
        assertEq(a.length, b.length);
        for (uint256 i; i < a.length; i++) assertEq(a[i], b[i]);
    }

    function assertEqArray(address[] memory a, address[] memory b) internal {
        assertEq(a.length, b.length);
        for (uint256 i; i < a.length; i++) assertEq(a[i], b[i]);
    }

    /* ------------- feedToys() ------------- */

    function test_feedToys() public {
        MockERC721 prizeNFT = new MockERC721("MockERC721", "MERC721");
        prizeNFT.setApprovalForAll(address(gachapon), true);

        uint32[] memory prizeTokenIds = [3877, 5592, 8877, 9048, 9911].toMemory32();

        uint40 start = uint40(block.timestamp);
        uint40 end = uint40(block.timestamp + 100);
        uint40 ticketPrice = 88;
        uint16 refundRate = uint16((uint256(type(uint16).max) * 66) / 100);
        uint40 maxTicketSupply = uint40(10);
        uint8 requirement = uint8(0);

        gachapon.feedToys(
            address(prizeNFT), // address prizeNFT,
            prizeTokenIds, // uint32[] calldata prizeTokenIds,
            start, // uint40 start,
            end, // uint40 end,
            ticketPrice, // uint40 ticketPrice,
            refundRate, // uint16 refundRate,
            maxTicketSupply, // uint40 maxTicketSupply,
            requirement // uint8 requirement
        );

        Gachapon.Raffle memory raffle = gachapon.getRaffle(1);

        assertEq(raffle.start, start);
        assertEq(raffle.end, end);
        assertEq(raffle.ticketSupply, 0);
        assertEq(raffle.maxTicketSupply, maxTicketSupply);
        assertEq(raffle.ticketPrice, ticketPrice);
        assertEq(raffle.requirement, requirement);
        assertEq(raffle.refundRate, refundRate);
        assertFalse(raffle.cancelled);
        assertEq(raffle.randomSeed, 0);
        // assertEq(raffle.prizeNFT, prizeNFT);
        // assertEq(raffle.prizeTokenIds, prizeTokenIds);

        // assertEqArray(raffle.prizeNFT, prizeNFT);
        // assertEqArray(raffle.prizeTokenIds, prizeTokenIds);

        // gachapon.feedToys(
        //         address(prizeNFT), // address prizeNFT,
        //         prizeTokenIds, // uint32[] calldata prizeTokenIds,
        //         uint40(block.timestamp), // uint40 start,
        //         uint40(block.timestamp + 10), // uint40 end,
        //     88, // uint40 ticketPrice,
        //     refundRate, // uint16 refundRate,
        //     maxTicketSupply, // uint40 maxTicketSupply,
        //     requirement, // uint8 requirement
        // );
    }

    /* ------------- buyTicket() ------------- */

    // function test_buyTicket() public {
    //     initializeMockRaffle();
    //     skip(200);

    //     gouda.mint(tester, 1000);
    //     gouda.approve(address(gachapon), type(uint256).max);
    //     gachapon.buyTicket(1);

    //     assertEq(gouda.balanceOf(tester), 400);
    //     assertEq(gouda.balanceOf(address(gachapon)), 600);

    //     Tickets tickets = Tickets(gachapon.getRaffleTickets(1));
    //     assertEq(tickets.ownerOf(1), tester);
    // }

    // function test_buyTickets() public {
    //     initializeMockRaffle();
    //     initializeMockRaffle();
    //     skip(200);

    //     gouda.mint(tester, 100000000);
    //     gouda.approve(address(gachapon), type(uint256).max);

    //     for (uint256 i; i < 30; i++) gachapon.buyTicket(2);

    //     Tickets tickets = Tickets(gachapon.getRaffleTickets(2));

    //     for (uint256 i; i < 30; i++) assertEq(tickets.ownerOf(i + 1), tester);
    // }

    // function test_buyTicket_fail_RaffleNotActive() public {
    //     initializeMockRaffle();

    //     // too early
    //     vm.expectRevert(RaffleNotActive.selector);
    //     gachapon.buyTicket(1);

    //     // too late
    //     skip(1000000);
    //     vm.expectRevert(RaffleNotActive.selector);
    //     gachapon.buyTicket(1);
    // }

    // function test_buyTicket_fail_MintExceedsLimit() public {
    //     initializeMockRaffle();
    //     skip(200);

    //     gouda.mint(tester, 100000000);
    //     gouda.approve(address(gachapon), type(uint256).max);

    //     gachapon.buyTicket(1);

    //     vm.expectRevert(MintExceedsLimit.selector);
    //     gachapon.buyTicket(1);
    // }

    // /* ------------- initiateGrappler() ------------- */

    // function test_initiateGrappler_fail_RaffleOngoing() public {
    //     initializeMockRaffle();
    //     skip(200);

    //     vm.expectRevert(RaffleOngoing.selector);
    //     gachapon.initiateGrappler(1);
    // }

    // function test_initiateGrappler_fail_RaffleRandomSeedSet() public {
    //     initializeMockRaffle();
    //     skip(500);

    //     gachapon.kickStuckMachine(1);

    //     vm.expectRevert(RaffleRandomSeedSet.selector);
    //     gachapon.initiateGrappler(1);
    // }

    // function test_initiateGrappler() public {
    //     initializeMockRaffle();
    //     skip(200);

    //     gouda.mint(alice, 1000000000000000000);
    //     gouda.mint(bob, 1000000000000000000);
    //     gouda.mint(chris, 1000000000000000000);

    //     vm.prank(alice);
    //     gouda.approve(address(gachapon), type(uint256).max);
    //     vm.prank(bob);
    //     gouda.approve(address(gachapon), type(uint256).max);
    //     vm.prank(chris);
    //     gouda.approve(address(gachapon), type(uint256).max);

    //     vm.prank(alice);
    //     gachapon.buyTicket(1);
    //     vm.prank(bob);
    //     gachapon.buyTicket(1);
    //     vm.prank(chris);
    //     gachapon.buyTicket(1);

    //     skip(300);

    //     gachapon.kickStuckMachine(1);

    //     uint256[] memory winningIds = gachapon.getWinningTickets(1);
    //     address[] memory winners = gachapon.getWinners(1);

    //     assertEq(winningIds.length, 3);
    //     assertEq(winners.length, 3);
    // }
}

// function generateMockToys(
//     address to,
//     uint256 num,
//     uint256 rs
// ) returns (address[] memory, uint256[] memory) {
//     address[] memory toys = new address[](num);
//     uint256[] memory ids = new uint256[](num);
//     string[] memory names = ["Kaijus", "Godjiars", "Cool Otters", "Anonymice", "Red Padirs"];

//     MockERC721 mock;
//     uint256 id;
//     for (uint256 i; i < num; i++) {
//         if (i % 3 == 0) mock = new MockERC721(names[((rs * i) % names.length)], "");

//         id = rs + i * 13;
//         mock.mint(to, id);
//         toys[i] = address(mock);
//         ids[i] = id;
//     }

//     return (toys, ids);
// }

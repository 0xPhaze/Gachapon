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
import "../SoulboundTickets.sol";

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

    MockERC721 mockNFT;

    function setUp() public {
        gouda = new MockGouda();
        troupe = new MockMadMouse();
        genesis = new MockMadMouse();

        gachapon = new Gachapon(IGouda(address(gouda)), IMadMouse(address(genesis)), IMadMouse(address(troupe)));
        ticketsImpl = new Tickets(gachapon);

        gachapon.setTicketsImplementation(address(ticketsImpl));

        mockNFT = new MockERC721("MockERC721", "MERC721");

        vm.label(bob, "bob");
        vm.label(alice, "alice");
        vm.label(tester, "tester");

        vm.label(address(gachapon), "gachapon");
        vm.label(address(mockNFT), "mockNFT");

        vm.roll(block.number + 10);
    }

    /* ------------- Helpers ------------- */

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
        uint16 ticketPrice = 188;
        uint8 refundRate = uint8((uint256(type(uint8).max) * 66) / 100);
        uint8 maxTicketSupply = 10;
        uint8 requirement = 0;

        gachapon.feedToys(
            address(prizeNFT), // address prizeNFT
            prizeTokenIds, // uint32[] calldata prizeTokenIds
            start, // uint40 start
            end, // uint40 end
            ticketPrice, // uint16 ticketPrice
            refundRate, // uint8 refundRate
            maxTicketSupply, // uint8 maxTicketSupply
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
    }

    /* ------------- buyTicket() ------------- */

    function test_buyTicket() public {
        gachapon.feedToys(
            address(0x123), // address prizeNFT
            [32, 40, 25].toMemory32(), // uint32[] calldata prizeTokenIds
            uint40(block.timestamp), // uint40 start
            uint40(block.timestamp + 100), // uint40 end
            1600, // uint16 ticketPrice
            (255 * 80) / 100, // uint8 refundRate
            20, // uint8 maxTicketSupply
            0 // uint8 requirement
        );

        gouda.mint(alice, 2000 ether);

        vm.prank(alice, alice);
        gachapon.buyTicket(1, 0);

        assertEq(gouda.balanceOf(alice), 400 ether);

        Tickets tickets = Tickets(gachapon.getRaffle(1).tickets);
        assertEq(tickets.ownerOf(1), alice);
    }

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

    /* ------------- claimPrize() ------------- */

    function test_triggerClaw() public {
        mockNFT.mint(tester, 46);
        mockNFT.mint(tester, 67);
        mockNFT.mint(tester, 82);
        mockNFT.setApprovalForAll(address(gachapon), true);

        gachapon.feedToys(
            address(mockNFT), // address prizeNFT
            [46, 67, 82].toMemory32(), // uint32[] calldata prizeTokenIds
            uint40(block.timestamp), // uint40 start
            uint40(block.timestamp + 100), // uint40 end
            500, // uint16 ticketPrice
            (255 * 80) / 100, // uint8 refundRate
            20, // uint8 maxTicketSupply
            0 // uint8 requirement
        );

        gouda.mint(tester, 2000 ether);
        gouda.mint(alice, 2000 ether);
        gouda.mint(bob, 2000 ether);

        vm.prank(tester, tester);
        gachapon.buyTicket(1, 0);

        vm.prank(alice, alice);
        gachapon.buyTicket(1, 0);

        vm.prank(bob, bob);
        gachapon.buyTicket(1, 0);

        vm.warp(500);
        gachapon.triggerClaw(1);

        address[] memory winners = gachapon.getWinners(1);
        assertTrue(winners.includes(tester));
        assertTrue(winners.includes(alice));
        assertTrue(winners.includes(bob));

        assertTrue(gachapon.isWinningTicket(1, 1));
        assertTrue(gachapon.isWinningTicket(1, 2));
        assertTrue(gachapon.isWinningTicket(1, 3));
    }

    function test_claimPrize() public {
        mockNFT.mint(tester, 46);
        mockNFT.setApprovalForAll(address(gachapon), true);

        gachapon.feedToys(
            address(mockNFT), // address prizeNFT
            [46].toMemory32(), // uint32[] calldata prizeTokenIds
            uint40(block.timestamp), // uint40 start
            uint40(block.timestamp + 100), // uint40 end
            500, // uint16 ticketPrice
            (255 * 80) / 100, // uint8 refundRate
            20, // uint8 maxTicketSupply
            0 // uint8 requirement
        );

        gouda.mint(alice, 2000 ether);

        vm.prank(alice, alice);
        gachapon.buyTicket(1, 0);

        vm.warp(500);
        gachapon.triggerClaw(1);

        vm.prank(alice, alice);
        gachapon.claimPrize(1, 1);

        assertEq(mockNFT.ownerOf(46), alice);

        assertTrue(gachapon.getRaffle(1).prizeTokenIds[0] > 0x7fffffff);
        assertEq(gachapon.getRaffle(1).prizeTokenIds[0] & 0x0fffffff, 46);
    }

    function test_claimPrize_fail_PrizeAlreadyClaimed() public {
        mockNFT.mint(tester, 46);
        mockNFT.setApprovalForAll(address(gachapon), true);

        gachapon.feedToys(
            address(mockNFT), // address prizeNFT
            [46].toMemory32(), // uint32[] calldata prizeTokenIds
            uint40(block.timestamp), // uint40 start
            uint40(block.timestamp + 100), // uint40 end
            500, // uint16 ticketPrice
            (255 * 80) / 100, // uint8 refundRate
            20, // uint8 maxTicketSupply
            0 // uint8 requirement
        );

        gouda.mint(alice, 2000 ether);

        vm.prank(alice, alice);
        gachapon.buyTicket(1, 0);

        vm.warp(500);
        gachapon.triggerClaw(1);

        vm.prank(alice, alice);
        gachapon.claimPrize(1, 1);

        vm.expectRevert(PrizeAlreadyClaimed.selector);

        vm.prank(alice, alice);
        gachapon.claimPrize(1, 1);
    }

    /* ------------- burnTickets() ------------- */

    function test_burnTickets() public {
        mockNFT.mint(tester, 67);
        mockNFT.setApprovalForAll(address(gachapon), true);

        uint8 refundRate = (255 * 80) / 100;
        uint16 ticketPrice = 500;

        gachapon.feedToys(
            address(mockNFT), // address prizeNFT
            [67].toMemory32(), // uint32[] calldata prizeTokenIds
            uint40(block.timestamp), // uint40 start
            uint40(block.timestamp + 100), // uint40 end
            ticketPrice, // uint16 ticketPrice
            refundRate, // uint8 refundRate
            20, // uint8 maxTicketSupply
            0 // uint8 requirement
        );

        gouda.mint(bob, 2000 ether);
        gouda.mint(alice, 2000 ether);

        vm.prank(bob, bob);
        gachapon.buyTicket(1, 0);

        vm.prank(alice, alice);
        gachapon.buyTicket(1, 0);

        vm.warp(500);
        gachapon.triggerClaw(1);

        address loser = gachapon.isWinningTicket(1, 1) ? alice : bob;
        uint256 losingId = gachapon.isWinningTicket(1, 1) ? 2 : 1;

        assertEq(gouda.balanceOf(loser), 1500 ether);

        vm.prank(loser, loser);
        gachapon.burnTickets([1].toMemory256(), [losingId].toMemory256());

        assertEq(gouda.balanceOf(loser), 1500 ether + ((uint256(ticketPrice) * (refundRate + 1) * 1e18) >> 8));
    }

    function test_burnTickets_fail_BurnFromIncorrectOwner() public {
        mockNFT.mint(tester, 67);
        mockNFT.setApprovalForAll(address(gachapon), true);

        gachapon.feedToys(
            address(mockNFT), // address prizeNFT
            [67].toMemory32(), // uint32[] calldata prizeTokenIds
            uint40(block.timestamp), // uint40 start
            uint40(block.timestamp + 100), // uint40 end
            500, // uint16 ticketPrice
            (255 * 80) / 100, // uint8 refundRate
            20, // uint8 maxTicketSupply
            0 // uint8 requirement
        );

        gouda.mint(alice, 2000 ether);

        vm.prank(alice, alice);
        gachapon.buyTicket(1, 0);

        vm.warp(500);
        gachapon.triggerClaw(1);

        vm.expectRevert(BurnFromIncorrectOwner.selector);
        vm.prank(bob, bob);
        gachapon.burnTickets([1].toMemory256(), [1].toMemory256());

        vm.prank(alice, alice);
        gachapon.burnTickets([1].toMemory256(), [1].toMemory256());

        vm.expectRevert(BurnFromIncorrectOwner.selector);
        vm.prank(alice, alice);
        gachapon.burnTickets([1].toMemory256(), [1].toMemory256());
    }

    // /* ------------- triggerClaw() ------------- */

    // function test_triggerClaw_fail_RaffleOngoing() public {
    //     initializeMockRaffle();
    //     skip(200);

    //     vm.expectRevert(RaffleOngoing.selector);
    //     gachapon.triggerClaw(1);
    // }

    // function test_triggerClaw_fail_RaffleRandomSeedSet() public {
    //     initializeMockRaffle();
    //     skip(500);

    //     gachapon.kickStuckMachine(1);

    //     vm.expectRevert(RaffleRandomSeedSet.selector);
    //     gachapon.triggerClaw(1);
    // }

    // function test_triggerClaw() public {
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

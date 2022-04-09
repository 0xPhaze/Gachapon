// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {DSTest} from "../../lib/ds-test/src/test.sol";
import {Vm} from "../../lib/forge-std/src/Vm.sol";
import {stdCheats} from "../../lib/forge-std/src/stdlib.sol";
// import {console} from "../../lib/forge-std/src/console.sol";

import {MockERC721} from "@rari-capital/solmate/src/test/utils/mocks/MockERC721.sol";
import {MockERC20} from "@rari-capital/solmate/src/test/utils/mocks/MockERC20.sol";

import {IGouda} from "../lib/interfaces.sol";
import "../Gachapon.sol";

import {Tickets, CallerNotApproved, MaxSupplyReached} from "../Tickets.sol";

contract TestGachapon is DSTest, stdCheats {
    Vm vm = Vm(HEVM_ADDRESS);

    Gachapon gachapon;
    MockERC20 gouda;
    Tickets ticketsImpl;

    address alice = address(0x1337);
    address bob = address(0x1338);
    address chris = address(0x1339);
    address tester = address(this);

    event log_array(uint256[] arr);
    event log_arrayAddress(address[] arr);

    function setUp() public {
        gachapon = new Gachapon();
        gouda = new MockERC20("", "", 18);
        ticketsImpl = new Tickets(gachapon);

        gachapon.setGouda(IGouda(address(gouda)));
        gachapon.setTicketsImplementation(address(ticketsImpl));

        vm.label(alice, "alice");
        vm.label(bob, "bob");
        vm.label(chris, "chris");
        vm.label(tester, "tester");

        vm.label(address(gachapon), "gachapon");
    }

    /* ------------- Helpers ------------- */

    function initiateMockRaffle() public {
        (address[] memory toys, uint256[] memory ids) = generateMockToys(tester, 8, 21);

        for (uint256 i; i < 8; i++) IERC721(toys[i]).setApprovalForAll(address(gachapon), true);

        gachapon.feedToys(toys, ids, block.timestamp + 100, block.timestamp + 300, 600, 30);
    }

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
        (address[] memory toys, uint256[] memory ids) = generateMockToys(tester, 8, 13);

        for (uint256 i; i < 8; i++) IERC721(toys[i]).setApprovalForAll(address(gachapon), true);

        uint256 start = block.timestamp;
        uint256 end = block.timestamp + 8888;
        uint256 price = 6666;
        uint256 maxSupply = 100;

        gachapon.feedToys(toys, ids, start, end, price, maxSupply);

        for (uint256 i; i < ids.length; i++) assertEq(IERC721(toys[i]).ownerOf(ids[i]), address(gachapon));

        /* Test Query */
        {
            (
                address[] memory allTickets,
                uint256[] memory allStart,
                uint256[] memory allEnd,
                uint256[] memory allPrice,
                bool[] memory allActive,
                uint256[] memory allTotalSupply,
                uint256[] memory allMaxSupply,
                ,
                ,

            ) = gachapon.queryRaffles(0, 1);

            assertEq(allTickets.length, 1);
            assertEq(allStart.length, 1);
            assertEq(allEnd.length, 1);
            assertEq(allPrice.length, 1);
            assertEq(allActive.length, 1);
            assertEq(allTotalSupply.length, 1);
            assertEq(allMaxSupply.length, 1);

            assertEq(allStart[0], start);
            assertEq(allEnd[0], end);
            assertEq(allPrice[0], price);
            assertTrue(allActive[0]);
        }
        {
            (
                ,
                ,
                ,
                ,
                ,
                ,
                ,
                address[][] memory allToys,
                uint256[][] memory allIds,
                address[][] memory allWinners
            ) = gachapon.queryRaffles(0, 1);

            assertEqArray(allToys[0], toys);
            assertEqArray(allIds[0], ids);
            assertEqArray(allWinners[0], new address[](0));
        }
    }

    // function test_feedToysQueryLimit() public {
    //     for (uint256 i; i < 1000; i++) {
    //         (address[] memory toys, uint256[] memory ids) = generateMockToys(tester, 8, i);
    //         for (uint256 j; j < 8; j++) IERC721(toys[j]).setApprovalForAll(address(gachapon), true);
    //         gachapon.feedToys(toys, ids, block.timestamp, block.timestamp + 100, 600, 100);
    //     }

    //     /* Test Query */
    //     (
    //         address[] memory allTickets,
    //         uint256[] memory allStart,
    //         uint256[] memory allEnd,
    //         uint256[] memory allPrice,
    //         bool[] memory allActive,
    //         uint256[] memory allTotalSupply,
    //         uint256[] memory allMaxSupply,
    //         address[][] memory allToys,
    //         uint256[][] memory allIds,
    //         address[][] memory allWinners
    //     ) = gachapon.queryRaffles(0, 1000);
    //     assertEq(allToys.length, 1000);
    // }

    /* ------------- feedGouda() ------------- */

    function test_feedGouda_fail_RaffleNotActive() public {
        initiateMockRaffle();

        // too early
        vm.expectRevert(RaffleNotActive.selector);
        gachapon.feedGouda(0);

        // too late
        skip(1000000);
        vm.expectRevert(RaffleNotActive.selector);
        gachapon.feedGouda(0);
    }

    function test_feedGouda() public {
        initiateMockRaffle();
        skip(200);

        gouda.mint(tester, 1000);
        gouda.approve(address(gachapon), type(uint256).max);
        gachapon.feedGouda(0);

        assertEq(gouda.balanceOf(tester), 400);
        assertEq(gouda.balanceOf(tester), 400);
    }

    function test_feedGouda_fail_MaxSupplyReached() public {
        initiateMockRaffle();
        skip(200);

        gouda.mint(tester, 100000000);
        gouda.approve(address(gachapon), type(uint256).max);

        for (uint256 i; i < 30; i++) gachapon.feedGouda(0);

        Tickets tickets = Tickets(gachapon.getRaffleTickets(0));
        assertEq(tickets.balanceOf(tester), 30);

        vm.expectRevert(TicketsMaxSupplyReached.selector);
        gachapon.feedGouda(0);
    }

    /* ------------- initiateGrappler() ------------- */

    function test_initiateGrappler_fail_RaffleOngoing() public {
        initiateMockRaffle();
        skip(200);

        vm.expectRevert(RaffleOngoing.selector);
        gachapon.initiateGrappler(0);
    }

    function test_initiateGrappler_fail_RaffleRandomSeedSet() public {
        initiateMockRaffle();
        skip(500);

        gachapon.kickStuckMachine(0);

        vm.expectRevert(RaffleRandomSeedSet.selector);
        gachapon.initiateGrappler(0);
    }

    function test_initiateGrappler() public {
        initiateMockRaffle();
        skip(200);

        gouda.mint(alice, 1000000000000000000);
        gouda.mint(bob, 1000000000000000000);
        gouda.mint(chris, 1000000000000000000);

        vm.prank(alice);
        gouda.approve(address(gachapon), type(uint256).max);
        vm.prank(bob);
        gouda.approve(address(gachapon), type(uint256).max);
        vm.prank(chris);
        gouda.approve(address(gachapon), type(uint256).max);

        for (uint256 i; i < 5; i++) {
            vm.prank(alice);
            gachapon.feedGouda(0);
            vm.prank(bob);
            gachapon.feedGouda(0);
            vm.prank(chris);
            gachapon.feedGouda(0);
        }

        skip(300);

        gachapon.kickStuckMachine(0);
        address[] memory winners = gachapon.getRaffleWinners(0);
        uint256 numWinners = winners.length;
        (, , , , , , , , uint256[][] memory ids, ) = gachapon.queryRaffles(0, 1);
        assertEq(numWinners, ids[0].length);
        // for (uint256 i; i < winners.length; i++) console.log(winners[i]);
    }
}

function generateMockToys(
    address to,
    uint256 num,
    uint256 rs
) returns (address[] memory, uint256[] memory) {
    address[] memory toys = new address[](num);
    uint256[] memory ids = new uint256[](num);

    MockERC721 mock;
    uint256 id;
    for (uint256 i; i < num; i++) {
        if (i % 3 == 0) mock = new MockERC721("", "");

        id = rs + i * 13;
        mock.mint(to, id);
        toys[i] = address(mock);
        ids[i] = id;
    }

    return (toys, ids);
}

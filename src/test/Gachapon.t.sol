// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {DSTestPlus} from "../../lib/solmate/src/test/utils/DSTestPlus.sol";
import {Vm} from "../../lib/forge-std/src/Vm.sol";
import {stdCheats} from "../../lib/forge-std/src/stdlib.sol";
import {console} from "../../lib/forge-std/src/console.sol";

import {MockERC721} from "../../lib/solmate/src/test/utils/mocks/MockERC721.sol";
import {MockERC20} from "../../lib/solmate/src/test/utils/mocks/MockERC20.sol";

import {IGouda} from "../lib/interfaces.sol";
import "../Gachapon.sol";

import "../Tickets.sol";

contract TestGachapon is DSTestPlus, stdCheats {
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

    function initializeMockRaffle() public {
        (address[] memory toys, uint256[] memory ids) = generateMockToys(tester, 8, 21);

        for (uint256 i; i < 8; i++) IERC721(toys[i]).setApprovalForAll(address(gachapon), true);

        gachapon.feedToys(toys, ids, block.timestamp + 100, block.timestamp + 300, 0, 600, 30);
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
        uint256 requirements = 4;

        gachapon.feedToys(toys, ids, start, end, requirements, price, maxSupply);

        for (uint256 i; i < ids.length; i++) assertEq(IERC721(toys[i]).ownerOf(ids[i]), address(gachapon));

        {
            (
                address[] memory allTickets,
                uint256[] memory allStart,
                uint256[] memory allEnd,
                uint256[] memory allPrice,
                uint256[] memory allRequirements,
                uint256[] memory allTotalSupply,
                uint256[] memory allMaxSupply,
                ,

            ) = gachapon.queryRaffles(1, 2);

            assertEq(allTickets.length, 1);
            assertEq(allStart.length, 1);
            assertEq(allEnd.length, 1);
            assertEq(allPrice.length, 1);
            assertEq(allTotalSupply.length, 1);
            assertEq(allMaxSupply.length, 1);

            assertEq(allStart[0], start);
            assertEq(allEnd[0], end);
            assertEq(allPrice[0], price);
            assertEq(allRequirements[0], requirements);
            assertEq(allTotalSupply[0], 0);
            assertEq(allMaxSupply[0], maxSupply);
            // console.log(allMaxSupply[0]);

            // @note check requirements
        }
        {
            (, , , , , , , address[][] memory allToys, uint256[][] memory allIds) = gachapon.queryRaffles(1, 2);

            assertEqArray(allToys[0], toys);
            assertEqArray(allIds[0], ids);
            // assertEqArray(allWinners[0], new address[](0));
        }
    }

    /* ------------- buyTicket() ------------- */

    function test_buyTicket() public {
        initializeMockRaffle();
        skip(200);

        gouda.mint(tester, 1000);
        gouda.approve(address(gachapon), type(uint256).max);
        gachapon.buyTicket(1);

        assertEq(gouda.balanceOf(tester), 400);
        assertEq(gouda.balanceOf(address(gachapon)), 600);

        Tickets tickets = Tickets(gachapon.getRaffleTickets(1));
        assertEq(tickets.ownerOf(1), tester);
    }

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

    function test_buyTicket_fail_RaffleNotActive() public {
        initializeMockRaffle();

        // too early
        vm.expectRevert(RaffleNotActive.selector);
        gachapon.buyTicket(1);

        // too late
        skip(1000000);
        vm.expectRevert(RaffleNotActive.selector);
        gachapon.buyTicket(1);
    }

    function test_buyTicket_fail_MintExceedsLimit() public {
        initializeMockRaffle();
        skip(200);

        gouda.mint(tester, 100000000);
        gouda.approve(address(gachapon), type(uint256).max);

        gachapon.buyTicket(1);

        vm.expectRevert(MintExceedsLimit.selector);
        gachapon.buyTicket(1);
    }

    /* ------------- initiateGrappler() ------------- */

    function test_initiateGrappler_fail_RaffleOngoing() public {
        initializeMockRaffle();
        skip(200);

        vm.expectRevert(RaffleOngoing.selector);
        gachapon.initiateGrappler(1);
    }

    function test_initiateGrappler_fail_RaffleRandomSeedSet() public {
        initializeMockRaffle();
        skip(500);

        gachapon.kickStuckMachine(1);

        vm.expectRevert(RaffleRandomSeedSet.selector);
        gachapon.initiateGrappler(1);
    }

    function test_initiateGrappler() public {
        initializeMockRaffle();
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

        vm.prank(alice);
        gachapon.buyTicket(1);
        vm.prank(bob);
        gachapon.buyTicket(1);
        vm.prank(chris);
        gachapon.buyTicket(1);

        skip(300);

        gachapon.kickStuckMachine(1);

        // (, , , , , , , , uint256[][] memory ids) = gachapon.queryRaffles(1, 2);
        // @note
        // uint256 numWinners = winners[0].length;
        // uint256 numToys = ids[0].length;

        // assertEq(numWinners, numToys);
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

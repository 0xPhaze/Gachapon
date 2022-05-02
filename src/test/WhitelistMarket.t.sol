// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {DSTestPlus} from "../../lib/solmate/src/test/utils/DSTestPlus.sol";
import {Vm} from "../../lib/forge-std/src/Vm.sol";
import {stdCheats} from "../../lib/forge-std/src/stdlib.sol";
import {console} from "../../lib/forge-std/src/console.sol";

import {MockERC721} from "../../lib/solmate/src/test/utils/mocks/MockERC721.sol";
import {MockERC20} from "../../lib/solmate/src/test/utils/mocks/MockERC20.sol";

import {MockMadMouse} from "./mocks/MockMadMouse.sol";
import {MockGouda} from "./mocks/MockGouda.sol";

import "../WhitelistMarket.sol";

contract TestWhitelistMarket is DSTestPlus, stdCheats {
    event BurnForWhitelist(address indexed user, bytes32 indexed id);

    Vm vm = Vm(HEVM_ADDRESS);

    WhitelistMarket market;

    MockGouda gouda;
    MockMadMouse troupe;
    MockMadMouse genesis;

    address bob = address(0xb0b);
    address alice = address(0xbabe);
    address tester = address(this);

    event log_array(uint256[] arr);
    event log_arrayAddress(address[] arr);

    function setUp() public {
        gouda = new MockGouda();
        troupe = new MockMadMouse();
        genesis = new MockMadMouse();

        market = new WhitelistMarket(IGouda(address(gouda)), IMadMouse(address(genesis)), IMadMouse(address(troupe)));

        vm.label(alice, "alice");
        vm.label(bob, "bob");
        vm.label(tester, "tester");

        vm.label(address(market), "market");
        vm.label(address(gouda), "gouda");
    }

    /* ------------- burnForWhitelist() ------------- */

    function test_burnForWhitelist() public {
        gouda.mint(alice, 500 ether);

        bytes32 hash = keccak256(
            abi.encode(
                block.timestamp, // start
                block.timestamp + 500, // end
                100 ether, // startPrice
                100 ether, // endPrice
                2, // maxEntries
                10, // maxSupply
                0 // requirement
            )
        );

        vm.expectEmit(true, false, false, false);
        emit BurnForWhitelist(alice, hash);

        vm.prank(alice, alice);
        market.burnForWhitelist(
            block.timestamp, // start
            block.timestamp + 500, // end
            100 ether, // startPrice
            100 ether, // endPrice
            2, // maxEntries
            10, // maxSupply
            0, // requirement
            0 // requirementData
        );

        assertEq(gouda.balanceOf(alice), 400 ether);

        vm.expectEmit(true, false, false, false);
        emit BurnForWhitelist(alice, hash);

        vm.warp(block.timestamp + 400);
        vm.prank(alice, alice);
        market.burnForWhitelist(
            block.timestamp, // start
            block.timestamp + 500, // end
            100 ether, // startPrice
            100 ether, // endPrice
            2, // maxEntries
            10, // maxSupply
            0, // requirement
            0 // requirementData
        );

        assertEq(gouda.balanceOf(alice), 300 ether);
    }

    /* ------------- Normal Auction ------------- */

    function test_burnForWhitelist_fail_NoWhitelistRemaining() public {
        gouda.mint(alice, 500 ether);
        gouda.mint(bob, 500 ether);

        vm.prank(alice, alice);
        market.burnForWhitelist(
            block.timestamp, // start
            block.timestamp + 500, // end
            100 ether, // startPrice
            100 ether, // endPrice
            1, // maxEntries
            1, // maxSupply
            0, // requirement
            0 // requirementData
        );

        vm.expectRevert(NoWhitelistRemaining.selector);
        vm.prank(bob, bob);
        market.burnForWhitelist(
            block.timestamp, // start
            block.timestamp + 500, // end
            100 ether, // startPrice
            100 ether, // endPrice
            1, // maxEntries
            1, // maxSupply
            0, // requirement
            0 // requirementData
        );
    }

    function test_burnForWhitelist_fail_MaxEntriesReached() public {
        gouda.mint(alice, 500 ether);

        vm.prank(alice, alice);
        market.burnForWhitelist(
            block.timestamp, // start
            block.timestamp + 500, // end
            100 ether, // startPrice
            100 ether, // endPrice
            1, // maxEntries
            2, // maxSupply
            0, // requirement
            0 // requirementData
        );

        vm.expectRevert(MaxEntriesReached.selector);
        vm.prank(alice, alice);
        market.burnForWhitelist(
            block.timestamp, // start
            block.timestamp + 500, // end
            100 ether, // startPrice
            100 ether, // endPrice
            1, // maxEntries
            2, // maxSupply
            0, // requirement
            0 // requirementData
        );
    }

    function test_burnForWhitelist_fail_NotActive() public {
        gouda.mint(alice, 500 ether);

        vm.expectRevert(NotActive.selector);
        vm.prank(alice, alice);
        market.burnForWhitelist(
            block.timestamp + 100, // start
            block.timestamp + 500, // end
            100 ether, // startPrice
            100 ether, // endPrice
            1, // maxEntries
            1, // maxSupply
            0, // requirement
            0 // requirementData
        );

        vm.warp(block.timestamp + 500);
        vm.expectRevert(NotActive.selector);
        vm.prank(alice, alice);
        market.burnForWhitelist(
            block.timestamp + 100, // start
            block.timestamp + 500, // end
            100 ether, // startPrice
            100 ether, // endPrice
            1, // maxEntries
            1, // maxSupply
            0, // requirement
            0 // requirementData
        );
    }

    /* ------------- Dutch Auction ------------- */

    function test_burnForWhitelist_DA() public {
        gouda.mint(alice, 1000 ether);

        uint256 balance;
        balance = gouda.balanceOf(alice);

        // start price
        vm.prank(alice, alice);
        market.burnForWhitelist(
            block.timestamp, // start
            block.timestamp + 100, // end
            200 ether, // startPrice
            100 ether, // endPrice
            10, // maxEntries
            10, // maxSupply
            0, // requirement
            0 // requirementData
        );

        assertEq(200 ether, balance - gouda.balanceOf(alice));

        balance = gouda.balanceOf(alice);

        // interpolated price
        vm.warp(23);
        vm.prank(alice, alice);
        market.burnForWhitelist(
            0, // start
            100, // end
            200 ether, // startPrice
            100 ether, // endPrice
            10, // maxEntries
            10, // maxSupply
            0, // requirement
            0 // requirementData
        );

        assertEq(200 ether - 23 ether, balance - gouda.balanceOf(alice));

        balance = gouda.balanceOf(alice);

        // end price
        vm.warp(500);
        vm.prank(alice, alice);
        market.burnForWhitelist(
            0, // start
            100, // end
            200 ether, // startPrice
            100 ether, // endPrice
            10, // maxEntries
            10, // maxSupply
            0, // requirement
            0 // requirementData
        );

        assertEq(100 ether, balance - gouda.balanceOf(alice));
    }

    function test_burnForWhitelist_fail_NotActive_DA() public {
        gouda.mint(alice, 500 ether);

        vm.expectRevert(NotActive.selector);
        vm.prank(alice, alice);
        market.burnForWhitelist(
            block.timestamp + 100, // start
            block.timestamp + 500, // end
            200 ether, // startPrice
            100 ether, // endPrice
            1, // maxEntries
            1, // maxSupply
            0, // requirement
            0 // requirementData
        );
    }

    function test_burnForWhitelist_fail_InvalidTimestamp() public {
        gouda.mint(alice, 500 ether);

        vm.warp(600);

        vm.expectRevert(InvalidTimestamp.selector);
        vm.prank(alice, alice);
        market.burnForWhitelist(
            block.timestamp + 500, // start
            block.timestamp + 100, // end
            200 ether, // startPrice
            100 ether, // endPrice
            1, // maxEntries
            1, // maxSupply
            0, // requirement
            0 // requirementData
        );
    }

    /* ------------- Requirements ------------- */

    function test_burnForWhitelist_fail_RequirementNotFulfilled() public {
        gouda.mint(alice, 500 ether);

        for (uint256 i = 1; i < 6; ++i) {
            vm.expectRevert(RequirementNotFulfilled.selector);
            vm.prank(alice, alice);
            market.burnForWhitelist(
                block.timestamp, // start
                block.timestamp + 500, // end
                100 ether, // startPrice
                100 ether, // endPrice
                1, // maxEntries
                1, // maxSupply
                1, // requirement
                0 // requirementData
            );
        }
    }

    function test_burnForWhitelist_Requirement1() public {
        gouda.mint(alice, 500 ether);
        genesis.mint(alice, 1);

        vm.prank(alice, alice);
        market.burnForWhitelist(
            block.timestamp, // start
            block.timestamp + 500, // end
            100 ether, // startPrice
            100 ether, // endPrice
            10, // maxEntries
            10, // maxSupply
            1, // requirement
            0 // requirementData
        );
    }

    function test_burnForWhitelist_Requirement2() public {
        gouda.mint(alice, 500 ether);
        troupe.mint(alice, 1);

        vm.prank(alice, alice);
        market.burnForWhitelist(
            block.timestamp, // start
            block.timestamp + 500, // end
            100 ether, // startPrice
            100 ether, // endPrice
            10, // maxEntries
            10, // maxSupply
            2, // requirement
            0 // requirementData
        );
    }

    function test_burnForWhitelist_Requirement3() public {
        gouda.mint(alice, 500 ether);
        gouda.mint(bob, 500 ether);
        troupe.mint(bob, 1);
        genesis.mint(alice, 1);

        // no requirement data

        vm.prank(alice, alice);
        market.burnForWhitelist(
            block.timestamp, // start
            block.timestamp + 500, // end
            100 ether, // startPrice
            100 ether, // endPrice
            10, // maxEntries
            10, // maxSupply
            3, // requirement
            0 // requirementData
        );

        vm.prank(bob, bob);
        market.burnForWhitelist(
            block.timestamp, // start
            block.timestamp + 500, // end
            100 ether, // startPrice
            100 ether, // endPrice
            10, // maxEntries
            10, // maxSupply
            3, // requirement
            0 // requirementData
        );

        // adding requirement data

        vm.prank(alice, alice);
        market.burnForWhitelist(
            block.timestamp, // start
            block.timestamp + 500, // end
            100 ether, // startPrice
            100 ether, // endPrice
            10, // maxEntries
            10, // maxSupply
            3, // requirement
            2 // requirementData
        );

        vm.prank(bob, bob);
        market.burnForWhitelist(
            block.timestamp, // start
            block.timestamp + 500, // end
            100 ether, // startPrice
            100 ether, // endPrice
            10, // maxEntries
            10, // maxSupply
            3, // requirement
            1 // requirementData
        );
    }

    function test_burnForWhitelist_Requirement4() public {
        gouda.mint(alice, 500 ether);
        troupe.mint(alice, 1);

        assert(troupe.getLevel(1) == 2);

        vm.prank(alice, alice);
        market.burnForWhitelist(
            block.timestamp, // start
            block.timestamp + 500, // end
            100 ether, // startPrice
            100 ether, // endPrice
            10, // maxEntries
            10, // maxSupply
            4, // requirement
            1 // requirementData
        );

        genesis.mint(alice, 1);

        assert(genesis.getLevel(1) == 2);

        vm.prank(alice, alice);
        market.burnForWhitelist(
            block.timestamp, // start
            block.timestamp + 500, // end
            100 ether, // startPrice
            100 ether, // endPrice
            10, // maxEntries
            10, // maxSupply
            4, // requirement
            5001 // requirementData
        );
    }

    function test_burnForWhitelist_Requirement5() public {
        gouda.mint(alice, 500 ether);
        troupe.mint(alice, 2);

        assert(troupe.getLevel(2) == 3);

        vm.prank(alice, alice);
        market.burnForWhitelist(
            block.timestamp, // start
            block.timestamp + 500, // end
            100 ether, // startPrice
            100 ether, // endPrice
            10, // maxEntries
            10, // maxSupply
            4, // requirement
            2 // requirementData
        );

        genesis.mint(alice, 2);

        assert(genesis.getLevel(2) == 3);

        vm.prank(alice, alice);
        market.burnForWhitelist(
            block.timestamp, // start
            block.timestamp + 500, // end
            100 ether, // startPrice
            100 ether, // endPrice
            10, // maxEntries
            10, // maxSupply
            4, // requirement
            5002 // requirementData
        );
    }

    function test_burnForWhitelist_fail_Requirement4() public {
        gouda.mint(bob, 500 ether);
        troupe.mint(bob, 1);
        genesis.mint(bob, 1);

        vm.expectRevert(RequirementNotFulfilled.selector);
        vm.prank(alice, alice);
        market.burnForWhitelist(
            block.timestamp, // start
            block.timestamp + 500, // end
            100 ether, // startPrice
            100 ether, // endPrice
            10, // maxEntries
            10, // maxSupply
            4, // requirement
            1 // requirementData
        );

        vm.expectRevert(RequirementNotFulfilled.selector);
        vm.prank(alice, alice);
        market.burnForWhitelist(
            block.timestamp, // start
            block.timestamp + 500, // end
            100 ether, // startPrice
            100 ether, // endPrice
            10, // maxEntries
            10, // maxSupply
            4, // requirement
            5001 // requirementData
        );
    }

    function test_burnForWhitelist_fail_Requirement5_InvalidOwner() public {
        gouda.mint(bob, 500 ether);
        troupe.mint(bob, 2);
        genesis.mint(bob, 2);

        vm.expectRevert(RequirementNotFulfilled.selector);
        vm.prank(alice, alice);
        market.burnForWhitelist(
            block.timestamp, // start
            block.timestamp + 500, // end
            100 ether, // startPrice
            100 ether, // endPrice
            10, // maxEntries
            10, // maxSupply
            5, // requirement
            2 // requirementData
        );

        vm.expectRevert(RequirementNotFulfilled.selector);
        vm.prank(alice, alice);
        market.burnForWhitelist(
            block.timestamp, // start
            block.timestamp + 500, // end
            100 ether, // startPrice
            100 ether, // endPrice
            10, // maxEntries
            10, // maxSupply
            5, // requirement
            5002 // requirementData
        );
    }

    function test_burnForWhitelist_fail_Requirement5_InvalidLevel() public {
        gouda.mint(bob, 500 ether);
        troupe.mint(bob, 1);
        genesis.mint(bob, 1);

        vm.expectRevert(RequirementNotFulfilled.selector);
        vm.prank(alice, alice);
        market.burnForWhitelist(
            block.timestamp, // start
            block.timestamp + 500, // end
            100 ether, // startPrice
            100 ether, // endPrice
            10, // maxEntries
            10, // maxSupply
            4, // requirement
            1 // requirementData
        );

        vm.expectRevert(RequirementNotFulfilled.selector);
        vm.prank(alice, alice);
        market.burnForWhitelist(
            block.timestamp, // start
            block.timestamp + 500, // end
            100 ether, // startPrice
            100 ether, // endPrice
            10, // maxEntries
            10, // maxSupply
            4, // requirement
            5001 // requirementData
        );
    }
}

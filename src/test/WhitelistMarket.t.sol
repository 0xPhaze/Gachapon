// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {DSTestPlus} from "../../lib/solmate/src/test/utils/DSTestPlus.sol";
import {Vm} from "../../lib/forge-std/src/Vm.sol";
import {stdCheats} from "../../lib/forge-std/src/stdlib.sol";
import {console} from "../../lib/forge-std/src/console.sol";

import {MockERC721} from "../../lib/solmate/src/test/utils/mocks/MockERC721.sol";
import {MockERC20} from "../../lib/solmate/src/test/utils/mocks/MockERC20.sol";

import "../WhitelistMarket.sol";

import "../lib/Ownable.sol";
import "../lib/Gouda.sol";

contract TestWhitelistMarket is DSTestPlus, stdCheats {
    Vm vm = Vm(HEVM_ADDRESS);

    WhitelistMarket market;
    Gouda gouda;

    address alice = address(0x1337);
    address bob = address(0x1338);
    address chris = address(0x1339);
    address tester = address(this);

    event log_array(uint256[] arr);
    event log_arrayAddress(address[] arr);

    function setUp() public {
        vm.label(alice, "alice");
        vm.label(bob, "bob");
        vm.label(chris, "chris");
        vm.label(tester, "tester");

        gouda = new Gouda();
        market = new WhitelistMarket(gouda);

        vm.label(address(market), "market");
        vm.label(address(gouda), "gouda");
    }

    /* ------------- addWhitelistSpots() ------------- */

    function test_addWhitelistSpots() public {
        market.addWhitelistSpots(0, 10, 300);

        (uint128 remaining, uint128 price) = market.whitelistSpots(0);

        assertEq(remaining, 10);
        assertEq(price, 300);
    }

    function test_addWhitelistSpots_fail_CallerNotOwner() public {
        vm.prank(alice);
        vm.expectRevert(CallerNotOwner.selector);
        market.addWhitelistSpots(0, 10, 300);
    }

    function test_addWhitelistSpots_fail_WhitelistIdInUse() public {
        market.addWhitelistSpots(0, 10, 300);

        vm.expectRevert(WhitelistIdInUse.selector);
        market.addWhitelistSpots(0, 10, 300);
    }

    event BurnForWhitelist(uint256 indexed id);

    /* ------------- burnForWhitelist() ------------- */

    function test_burnForWhitelist() public {
        market.addWhitelistSpots(0, 10, 300);
        gouda.mint(alice, 500);

        assertEq(gouda.balanceOf(alice), 500);

        vm.prank(alice);
        vm.expectEmit(true, false, false, false);
        emit BurnForWhitelist(0);
        market.burnForWhitelist(0);

        assertEq(gouda.balanceOf(alice), 200);

        (uint128 remaining, uint128 price) = market.whitelistSpots(0);
        assertEq(remaining, 9);
        assertEq(price, 300);
    }

    function test_burnForWhitelist_fail_NoWhitelistRemaining() public {
        market.addWhitelistSpots(0, 1, 300);
        gouda.mint(alice, 500);

        vm.prank(alice);
        market.burnForWhitelist(0);

        vm.expectRevert(NoWhitelistRemaining.selector);
        market.burnForWhitelist(0);
    }

    function test_burnForWhitelist_fail_MissingBalance() public {
        market.addWhitelistSpots(0, 10, 300);

        vm.prank(alice);
        vm.expectRevert("ERC20: burn amount exceeds balance");
        market.burnForWhitelist(0);
    }

    function test_burnForWhitelist_fail() public {
        vm.prank(alice);
        vm.expectRevert(NoWhitelistRemaining.selector);
        market.burnForWhitelist(0);
    }
}

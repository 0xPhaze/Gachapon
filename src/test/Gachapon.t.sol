// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import {DSTest} from "../../lib/ds-test/src/test.sol";
import {Vm} from "../../lib/forge-std/src/Vm.sol";
import {console} from "../../lib/forge-std/src/console.sol";

import {MockERC721} from "@rari-capital/solmate/src/test/utils/mocks/MockERC721.sol";

import "../Gachapon.sol";

contract TestGachapon is DSTest {
    Vm vm = Vm(HEVM_ADDRESS);

    Gachapon gachapon;

    address alice = address(0x1337);
    address bob = address(0x1338);
    address chris = address(0x1339);

    address tester = address(this);

    function setUp() public {
        gachapon = new Gachapon();

        vm.label(alice, "alice");
        vm.label(bob, "bob");
        vm.label(chris, "chris");
        vm.label(tester, "tester");
        vm.label(address(gachapon), "gachapon");
    }

    // function test_feedToysFail() public {
    //     (IERC721[] memory toys, uint256[] memory ids) = generateMockToys(1);
    //     vm.expectRevert();
    //     gachapon.feedToys(toys, ids, block.timestamp, block.timestamp, 10);
    // }

    function test_feedToys() public {
        (address[] memory toys, uint256[] memory ids) = generateMockToys(
            tester,
            5
        );

        for (uint256 i; i < 5; i++)
            IERC721(toys[i]).setApprovalForAll(address(gachapon), true);

        uint256 start = block.timestamp;
        uint256 end = block.timestamp + 8888;
        uint256 price = 6666;

        gachapon.feedToys(toys, ids, start, end, price);

        (
            address[][] memory allToys,
            uint256[][] memory allIds,
            address[] memory allTickets,
            uint256[] memory allStart,
            uint256[] memory allEnd,
            uint256[] memory allPrice,
            bool[] memory allActive,
            address[][] memory allWinners
        ) = gachapon.getAllRaffles();

        // Test Query
        assertEq(allToys.length, 1);
        assertEq(allIds.length, 1);
        assertEq(allTickets.length, 1);
        assertEq(allStart.length, 1);
        assertEq(allEnd.length, 1);
        assertEq(allPrice.length, 1);
        assertEq(allActive.length, 1);
        assertEq(allWinners.length, 1);

        for (uint256 i; i < ids.length; i++) {
            assertEq(allToys[0][i], toys[i]);
            assertEq(allIds[0][i], ids[i]);
            // assertNEq(allTickets[0][i], address(0));
        }

        assertEq(allStart[0], start);
        assertEq(allEnd[0], end);
        assertEq(allPrice[0], price);
        assertTrue(allActive[0]);

        assertEq(IERC721(allTickets[0]).totalSupply(), 0);
        assertEq(allWinners[0].length, 0);
    }
}

// function testMultiArray() returns (uint256[][] memory, uint256[][] memory) {
//     uint256[][] memory arr = new uint256[][](5);
//     for (uint256 i; i < 5; i++) {
//         arr[i] = new uint256[](3);
//         for (uint256 j; j < 3; j++) {
//             arr[i][j] = i + j;
//         }
//     }
//     return (arr, arr);
// }

function generateMockToys(address to, uint256 num)
    returns (address[] memory, uint256[] memory)
{
    address[] memory toys = new address[](num);
    uint256[] memory ids = new uint256[](num);

    for (uint256 i; i < num; i++) {
        MockERC721 mock = new MockERC721("", "");
        mock.mint(to, i * 13);
        toys[i] = address(mock);
        ids[i] = i * 13;
    }

    return (toys, ids);
}

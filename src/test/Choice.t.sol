//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {DSTestPlus} from "../../lib/solmate/src/test/utils/DSTestPlus.sol";
import {Vm} from "../../lib/forge-std/src/Vm.sol";

import {Choice} from "../lib/Choice.sol";

contract TestChoice is DSTestPlus {
    Vm vm = Vm(HEVM_ADDRESS);

    event log_array(uint256[]);

    function setUp() external {}

    function assertIsSet(uint256[] memory array) internal {
        bool unique;

        uint256 n = array.length;
        uint256 j;

        for (uint256 i; i < n; ++i) {
            unique = true;
            for (j = 0; j < n && unique; ++j) if (array[j] == array[i] && i != j) unique = false;
            if (!unique) {
                emit log_array(array);
                fail();
            }
        }
    }

    function test_selectNOfM(
        uint256 n,
        uint256 m,
        uint256 randomSeed
    ) public {
        n = n % 30;
        m = m % 1000;

        vm.assume(m > 0);
        vm.assume(m >= n);

        uint256[] memory res = Choice.selectNOfM(n, m, randomSeed);
        assertEq(res.length, n);
        assertIsSet(res);
    }

    function test_indexOfSelectNOfM(
        uint256 n,
        uint256 m,
        uint256 randomSeed
    ) public {
        n = n % 30;
        m = m % 1000;

        vm.assume(m > 0);
        vm.assume(m >= n);

        uint256[] memory res = Choice.selectNOfM(n, m, randomSeed);
        bool isSelect;
        uint256 index;
        for (uint256 i; i < n; ++i) {
            (isSelect, index) = Choice.indexOfSelectNOfM(res[i], n, m, randomSeed);

            assertEq(index, i);
            assertTrue(isSelect);
        }
    }
}

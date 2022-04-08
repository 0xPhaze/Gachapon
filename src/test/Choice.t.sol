//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// // import "ds-test/test.sol";
// import "forge-std/console.sol";
// import {DSTestPlus} from "@rari-capital/solmate/src/test/utils/DSTestPlus.sol";

// // contract Choice {
// //     function selectNOfM(
// //         uint256 n,
// //         uint256 m,
// //         uint256 r
// //     ) internal pure returns (uint256[] memory) {
// //     }
// // }

// contract TestGas is DSTestPlus {
//     event log_array(uint256[]);

//     function setUp() external {}

//     struct Data {
//         uint40 data1;
//         uint40 data2;
//         uint40 data3;
//         uint40 data4;
//         uint40 data5;
//     }

//     Data data = Data(4, 4, 4, 4, 4);

//     function test() public {
//         Data memory d = data;
//         d.data1--;
//         data = d;
//         console.log(data.data1);
//     }

//     function testChoice(
//         uint256 n,
//         uint256 m,
//         uint256 randomSeed
//     ) public {
//         n = n % 30;
//         m = m % 1000;

//         hevm.assume(m > 0);
//         hevm.assume(m >= n);

//         // uint256[] memory res = Choice.selectNOfM(n, m, randomSeed);
//         uint256[] memory res = Choice.selectNOfM16(n, m, randomSeed);
//         assertArrayUnique(res);
//         emit log_array(res);
//     }

//     function assertArrayUnique(uint256[] memory array) internal {
//         bool unique;

//         uint256 n = array.length;
//         uint256 j;

//         for (uint256 i; i < n; ++i) {
//             unique = true;
//             for (j = 0; j < n && unique; ++j)
//                 if (array[j] == array[i] && i != j) unique = false;
//             if (!unique) {
//                 console.log("duplicate found", array[i], array[j]);
//                 emit log_array(array);
//                 fail();
//             }
//         }
//     }

//     function testGasChoice() external {
//         for (uint256 i = 1; i < 30; i++) {
//             testChoice(i, i, i);
//         }
//         testChoice(9, 180, 11);
//         testChoice(11, 380, 11);
//         testChoice(21, 500, 12);
//         testChoice(13, 400, 15);
//         testChoice(17, 300, 13);
//         testChoice(12, 200, 14);
//         testChoice(15, 600, 15);
//     }
// }

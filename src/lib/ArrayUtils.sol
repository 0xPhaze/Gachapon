// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

library ArrayUtils {
    /* ------------- uint8 ------------- */

    function toMemory(uint8[1] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](1);
            for (uint256 i; i < 1; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint8[2] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](2);
            for (uint256 i; i < 2; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint8[3] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](3);
            for (uint256 i; i < 3; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint8[4] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](4);
            for (uint256 i; i < 4; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint8[5] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](5);
            for (uint256 i; i < 5; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint8[6] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](6);
            for (uint256 i; i < 6; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint8[7] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](7);
            for (uint256 i; i < 7; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint8[8] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](8);
            for (uint256 i; i < 8; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint8[9] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](9);
            for (uint256 i; i < 9; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint8[10] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](10);
            for (uint256 i; i < 10; ++i) out[i] = arr[i];
        }
    }

    /* ------------- uint16 ------------- */

    function toMemory(uint16[1] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](1);
            for (uint256 i; i < 1; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint16[2] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](2);
            for (uint256 i; i < 2; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint16[3] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](3);
            for (uint256 i; i < 3; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint16[4] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](4);
            for (uint256 i; i < 4; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint16[5] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](5);
            for (uint256 i; i < 5; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint16[6] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](6);
            for (uint256 i; i < 6; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint16[7] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](7);
            for (uint256 i; i < 7; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint16[8] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](8);
            for (uint256 i; i < 8; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint16[9] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](9);
            for (uint256 i; i < 9; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint16[10] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](10);
            for (uint256 i; i < 10; ++i) out[i] = arr[i];
        }
    }

    /* ------------- uint256 ------------- */

    function toMemory(uint256[1] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](1);
            for (uint256 i; i < 1; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint256[2] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](2);
            for (uint256 i; i < 2; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint256[3] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](3);
            for (uint256 i; i < 3; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint256[4] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](4);
            for (uint256 i; i < 4; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint256[5] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](5);
            for (uint256 i; i < 5; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint256[6] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](6);
            for (uint256 i; i < 6; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint256[7] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](7);
            for (uint256 i; i < 7; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint256[8] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](8);
            for (uint256 i; i < 8; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint256[9] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](9);
            for (uint256 i; i < 9; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint256[10] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](10);
            for (uint256 i; i < 10; ++i) out[i] = arr[i];
        }
    }
}

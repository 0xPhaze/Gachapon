// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {MockERC721} from "./MockERC721.sol";

// import {IMadMouse} from "../../lib/interfaces.sol";

contract MockMadMouse is MockERC721("MadMouse", "MMC") {
    function numStaked(address) external pure returns (uint256) {
        return 0;
    }

    function numOwned(address user) external view returns (uint256) {
        return balanceOf(user);
    }

    function getLevel(uint256 tokenId) external pure returns (uint256) {
        return 1 + (tokenId % 3);
    }

    function getDNA(uint256 tokenId) external pure returns (uint256) {
        return tokenId;
    }
}

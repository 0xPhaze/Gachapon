// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {Ownable} from "./lib/Ownable.sol";
import {Gouda} from "./lib/Gouda.sol";
import {console} from "../lib/forge-std/src/console.sol";

error NoWhitelistRemaining();
error WhitelistIdInUse();

contract WhitelistMarket is Ownable {
    event BurnForWhitelist(uint256 indexed id);

    struct WLSpot {
        uint128 remaining;
        uint128 price;
    }

    mapping(uint256 => WLSpot) public whitelistSpots;

    // Gouda constant gouda = Gouda(0x3aD30C5E3496BE07968579169a96f00D56De4C1A);
    Gouda immutable gouda;

    constructor(Gouda gouda_) {
        gouda = gouda_;
    }

    /* ------------- External ------------- */

    function burnForWhitelist(uint256 id) external {
        unchecked {
            WLSpot memory wlspot = whitelistSpots[id];
            if (wlspot.remaining == 0 || wlspot.price == 0) revert NoWhitelistRemaining();

            whitelistSpots[id] = WLSpot(wlspot.remaining - 1, wlspot.price);

            gouda.burnFrom(msg.sender, wlspot.price);
            emit BurnForWhitelist(id);
        }
    }

    /* ------------- Owner ------------- */

    function addWhitelistSpots(
        uint256 id,
        uint128 spots,
        uint128 price
    ) external onlyOwner {
        if (whitelistSpots[id].price != 0) revert WhitelistIdInUse();
        whitelistSpots[id] = WLSpot(spots, price);
    }
}

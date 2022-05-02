// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM`MMM NMM MMM MMM MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM  MMMMhMMMMMMM  MMMMMMMM MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMM  MM-MMMMM   MMMM    MMMM   lMMMDMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMM jMMMMl   MM    MMM  M  MMM   M   MMMM MMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMM MMMMMMMMM  , `     M   Y   MM  MMM  BMMMMMM MMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMM MMMMMMMMMMMM  IM  MM  l  MMM  X   MM.  MMMMMMMMMM MMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM.nlMMMMMMMMMMMMMMMMM]._  MMMMMMMMMMMMMMMNMMMMMMMMMMMMMM
// MMMMMMMMMMMMMM TMMMMMMMMMMMMMMMMMM          +MMMMMMMMMMMM:  rMMMMMMMMN MMMMMMMMMMMMMM
// MMMMMMMMMMMM MMMMMMMMMMMMMMMM                  MMMMMM           MMMMMMMM qMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMM^                   MMMb              .MMMMMMMMMMMMMMMMMMM
// MMMMMMMMMM MMMMMMMMMMMMMMM                     MM                  MMMMMMM MMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMM                     M                   gMMMMMMMMMMMMMMMMM
// MMMMMMMMu MMMMMMMMMMMMMMM                                           MMMMMMM .MMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMM                                           :MMMMMMMMMMMMMMMM
// MMMMMMM^ MMMMMMMMMMMMMMMl                                            MMMMMMMM MMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMM                                             MMMMMMMMMMMMMMMM
// MMMMMMM MMMMMMMMMMMMMMMM                                             MMMMMMMM MMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMM                                             MMMMMMMMMMMMMMMM
// MMMMMMr MMMMMMMMMMMMMMMM                                             MMMMMMMM .MMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMM                                           MMMMMMMMMMMMMMMMM
// MMMMMMM MMMMMMMMMMMMMMMMM                                         DMMMMMMMMMM MMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMM                              MMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMM|`MMMMMMMMMMMMMMMM         q                      MMMMMMMMMMMMMMMMMMM  MMMMMMM
// MMMMMMMMMTMMMMMMMMMMMMMMM                               qMMMMMMMMMMMMMMMMMMgMMMMMMMMM
// MMMMMMMMq MMMMMMMMMMMMMMMh                             jMMMMMMMMMMMMMMMMMMM nMMMMMMMM
// MMMMMMMMMM MMMMMMMMMMMMMMMQ      nc    -MMMMMn        MMMMMMMMMMMMMMMMMMMM MMMMMMMMMM
// MMMMMMMMMM.MMMMMMMMMMMMMMMMMMl            M1       `MMMMMMMMMMMMMMMMMMMMMMrMMMMMMMMMM
// MMMMMMMMMMMM MMMMMMMMMMMMMMMMMMMM               :MMMMMMMMMM MMMMMMMMMMMM qMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMM  MMMMMMX       MMMMMMMMMMMMMMM  uMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMM DMMMMMMMMM   IMMMMMMMMMMMMMMMMMMMMMMM   M   Y  MMMMMMMN MMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMM MMMMMM    ``    M      MM  MMM   , MMMM    Mv  MMM MMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMM MMh  Ml  .   M  MMMM  I  MMMT  M     :M   ,MMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMM MMMMMMMMt  MM  MMMMB m  ]MMM  MMMM   MMMMMM MMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMM MMMMM  MMM   TM   MM  9U  .MM  _MMMMM MMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMM YMMMMMMMn     MMMM    +MMMMMMM1`MMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM MMMMMMMMMMMMMMMMMMMMMMM MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM.`MMM MMM MMMMM`.MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM author: phaze MMM

import {Ownable} from "./lib/Ownable.sol";
import {IGouda, IMadMouse} from "./lib/interfaces.sol";

error NoWhitelistRemaining();
error MaxEntriesReached();
error ContractCallNotAllowed();
error NotActive();
error RequirementNotFulfilled();
error InvalidTimestamp();

contract WhitelistMarket is Ownable {
    event BurnForWhitelist(address indexed user, bytes32 indexed id);

    mapping(bytes32 => uint256) public totalSupply;
    mapping(bytes32 => mapping(address => uint256)) public numEntries;

    IGouda immutable gouda;
    IMadMouse immutable genesis;
    IMadMouse immutable troupe;

    constructor(
        IGouda gouda_,
        IMadMouse genesis_,
        IMadMouse troupe_
    ) {
        gouda = gouda_;
        genesis = genesis_;
        troupe = troupe_;
    }

    /* ------------- External ------------- */

    function burnForWhitelist(
        uint256 start,
        uint256 end,
        uint256 startPrice,
        uint256 endPrice,
        uint256 maxEntries,
        uint256 maxSupply,
        uint256 requirement,
        uint256 requirementData
    ) external noContract {
        unchecked {
            bytes32 hash = getWhitelistHash(start, end, startPrice, endPrice, maxEntries, maxSupply, requirement);

            uint256 price;
            if (startPrice <= endPrice) {
                // if no dutch-auction, make sure that we're in the valid timeframe
                // dutch auction sits at resting price
                if (block.timestamp < start || end < block.timestamp) revert NotActive();
                price = startPrice;
            } else {
                if (block.timestamp < start) revert NotActive();
                if (end < start) revert InvalidTimestamp();
                // assumptions: endPrice < startPrice; timestamp >= start; start <= end
                uint256 timestamp = block.timestamp > end ? end : block.timestamp;
                // overflow unlikely
                price = startPrice - ((startPrice - endPrice) * (timestamp - start)) / (end - start);
            }
            if (++totalSupply[hash] > maxSupply) revert NoWhitelistRemaining();
            if (++numEntries[hash][msg.sender] > maxEntries) revert MaxEntriesReached();
            if (requirement != 0 && !fulfillsRequirement(msg.sender, requirement, requirementData))
                revert RequirementNotFulfilled();

            gouda.burnFrom(msg.sender, price);
            emit BurnForWhitelist(msg.sender, hash);
        }
    }

    /* ------------- View ------------- */

    function getWhitelistHash(
        uint256 start,
        uint256 end,
        uint256 startPrice,
        uint256 endPrice,
        uint256 maxEntries,
        uint256 maxSupply,
        uint256 requirement
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(start, end, startPrice, endPrice, maxEntries, maxSupply, requirement));
    }

    // 1: genesis
    // 2: troupe
    // 3: genesis / troupe
    // 4: level >= 2
    // 5: level == 3
    function fulfillsRequirement(
        address user,
        uint256 requirement,
        uint256 data
    ) public returns (bool) {
        unchecked {
            if (requirement == 1 && genesis.numOwned(user) > 0) return true;
            else if (requirement == 2 && troupe.numOwned(user) > 0) return true;
            else if (
                requirement == 3 &&
                // specify data == 1 to direct that user is holding troupe and potentially save an sload;
                // or leave unspecified and worst-case check both
                ((data != 2 && troupe.numOwned(user) > 0) || (data != 1 && genesis.numOwned(user) > 0))
            ) return true;
            else if (
                requirement == 4 &&
                (
                    data > 5000 // specify owner-held id: data > 5000 refers to genesis collection
                        ? genesis.getLevel(data - 5000) > 1 && genesis.ownerOf(data - 5000) == user
                        : troupe.getLevel(data) > 1 && troupe.ownerOf(data) == user
                )
            ) return true;
            else if (
                requirement == 5 &&
                (
                    data > 5000
                        ? genesis.getLevel(data - 5000) > 2 && genesis.ownerOf(data - 5000) == user
                        : troupe.getLevel(data) > 2 && troupe.ownerOf(data) == user
                )
            ) return true;
            return false;
        }
    }

    /* ------------- Modifier ------------- */

    modifier noContract() {
        if (msg.sender != tx.origin) revert ContractCallNotAllowed();
        _;
    }
}

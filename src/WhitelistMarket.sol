// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {Ownable} from "./lib/Ownable.sol";
import {Gouda} from "./lib/Gouda.sol";
import {IMadMouse} from "./lib/interfaces.sol";

error WhitelistMarket__NoWhitelistRemaining();
error WhitelistMarket__MaxEntriesReached();
error WhitelistMarket__ContractCallNotAllowed();
error WhitelistMarket__NotActive();
error WhitelistMarket__RequirementNotFulfilled();

contract WhitelistMarket is Ownable {
    event BurnForWhitelist(address indexed user, bytes32 indexed id);

    mapping(bytes32 => uint256) public totalSupply;
    mapping(bytes32 => mapping(address => uint256)) public numEntries;

    // Gouda constant gouda = Gouda(0x3aD30C5E3496BE07968579169a96f00D56De4C1A);
    // address constant genesis = Gouda(0x3ad30c5e2985e960e89f4a28efc91ba73e104b77);
    // address constant troupe = Gouda(0x74d9d90a7fc261fbe92ed47b606b6e0e00d75e70);

    Gouda immutable gouda;
    IMadMouse immutable genesis;
    IMadMouse immutable troupe;

    constructor(
        Gouda gouda_,
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
        uint256 price,
        uint256 maxSupply,
        uint256 maxEntries,
        uint256 requirement,
        uint256 requirementData
    ) external noContract {
        unchecked {
            bytes32 hash = getWhitelistHash(start, end, price, maxSupply, maxEntries, requirement);

            if (++totalSupply[hash] > maxSupply) revert WhitelistMarket__NoWhitelistRemaining();
            if (++numEntries[hash][msg.sender] > maxEntries) revert WhitelistMarket__MaxEntriesReached();
            if (block.timestamp < start || end < block.timestamp) revert WhitelistMarket__NotActive();
            if (requirement != 0 && !fulfillsRequirement(msg.sender, requirement, requirementData))
                revert WhitelistMarket__RequirementNotFulfilled();

            gouda.burnFrom(msg.sender, price);
            emit BurnForWhitelist(msg.sender, hash);
        }
    }

    /* ------------- View ------------- */

    function getWhitelistHash(
        uint256 start,
        uint256 end,
        uint256 price,
        uint256 maxSupply,
        uint256 maxEntries,
        uint256 requirement
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(start, end, price, maxSupply, maxEntries, requirement));
    }

    function fulfillsRequirement(
        address user,
        uint256 requirement,
        uint256 data
    ) public returns (bool) {
        unchecked {
            if (requirement == 1 && genesis.numOwned(user) > 0) return true;
            if (requirement == 2 && troupe.numOwned(user) > 0) return true;
            if (
                requirement == 3 &&
                // specify data == 1 to direct that user is holding troupe and potentially save an sload;
                // or leave unspecified and worst-case check both
                ((data != 2 && troupe.numOwned(user) > 0) || (data != 1 && genesis.numOwned(user) > 0))
            ) return true;
            if (
                requirement == 4 &&
                (
                    data > 5000 // specify owner-held id: data > 5000 refers to genesis collection
                        ? genesis.getLevel(data - 5000) > 1 && genesis.ownerOf(data - 5000) == user
                        : troupe.getLevel(data) > 1 && troupe.ownerOf(data) == user
                )
            ) return true;
            if (
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
        if (msg.sender != tx.origin) revert WhitelistMarket__ContractCallNotAllowed();
        _;
    }
}

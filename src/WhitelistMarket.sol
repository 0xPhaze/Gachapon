// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {Ownable} from "./lib/Ownable.sol";
import {Gouda} from "./lib/Gouda.sol";

error WhitelistMarket__NoWhitelistRemaining();
error WhitelistMarket__MaxEntriesReached();
error WhitelistMarket__ContractCallNotAllowed();
error WhitelistMarket__NotActive();

contract WhitelistMarket is Ownable {
    event BurnForWhitelist(address indexed user, bytes32 indexed id);

    mapping(bytes32 => uint256) public totalSupply;
    mapping(bytes32 => mapping(address => uint256)) public numEntries;

    // Gouda constant gouda = Gouda(0x3aD30C5E3496BE07968579169a96f00D56De4C1A);
    Gouda immutable gouda;

    constructor(Gouda gouda_) {
        gouda = gouda_;
    }

    /* ------------- External ------------- */

    function burnForWhitelist(
        uint256 start,
        uint256 end,
        uint256 price,
        uint256 maxSupply,
        uint256 maxEntries
    ) external {
        bytes32 hash = getWhitelistHash(start, end, price, maxSupply, maxEntries);
        uint256 total = ++totalSupply[hash];

        if (total == maxSupply) revert WhitelistMarket__NoWhitelistRemaining();
        if (numEntries[hash][msg.sender] == maxEntries) revert WhitelistMarket__MaxEntriesReached();
        if (block.timestamp < start || end < block.timestamp) revert WhitelistMarket__NotActive();

        gouda.burnFrom(msg.sender, price);
        emit BurnForWhitelist(msg.sender, hash);
    }

    /* ------------- View ------------- */

    function getWhitelistHash(
        uint256 start,
        uint256 end,
        uint256 price,
        uint256 maxSupply,
        uint256 maxEntries
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(start, end, price, maxSupply, maxEntries));
    }

    /* ------------- Modifier ------------- */

    modifier noContract() {
        if (msg.sender != tx.origin) revert WhitelistMarket__ContractCallNotAllowed();
        _;
    }
}

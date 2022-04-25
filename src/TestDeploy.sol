// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {Gouda} from "./lib/Gouda.sol";
import {Gachapon} from "./Gachapon.sol";
import {AuctionHouse} from "./AuctionHouse.sol";
import {WhitelistMarket} from "./WhitelistMarket.sol";
import {Tickets} from "./Tickets.sol";

import {MockERC721} from "./lib/mocks/MockERC721.sol";

import {ArrayUtils} from "./lib/ArrayUtils.sol";
import {MockMadMouse} from "./lib/mocks/MockMadMouse.sol";
import {IMadMouse} from "./lib/interfaces.sol";

contract TestDeployGachapon {
    using ArrayUtils for *;

    Gouda public gouda;
    Tickets public tickets;
    Gachapon public gachapon;
    AuctionHouse public auctionHouse;
    WhitelistMarket public whitelistMarket;

    IMadMouse public genesis;
    IMadMouse public troupe;

    constructor(IMadMouse genesis_, IMadMouse troupe_) {
        genesis = genesis_;
        troupe = troupe_;

        gouda = new Gouda();
        gachapon = new Gachapon(gouda, genesis, troupe);
        auctionHouse = new AuctionHouse(gouda, genesis, troupe);
        whitelistMarket = new WhitelistMarket(gouda, genesis, troupe);

        tickets = new Tickets(gachapon);
        gachapon.setTicketsImplementation(address(tickets));
    }

    function init() external {
        address deployer = address(this);

        MockERC721 mock;
        uint256[] memory ids;

        mock = new MockERC721("Keijus", "");
        mock.setApprovalForAll(address(gachapon), true);

        ids = [1, 14, 27, 38].toMemory();
        for (uint256 i; i < ids.length; ++i) mock.mint(deployer, ids[i]);
        gachapon.feedToys(
            address(mock),
            ids,
            uint40(block.timestamp),
            uint40(block.timestamp + 10),
            7,
            uint16((uint256(type(uint16).max) * 100) / 66),
            30,
            0
        );

        mock = new MockERC721("Godjairs", "");
        mock.setApprovalForAll(address(gachapon), true);

        ids = [69].toMemory();
        for (uint256 i; i < ids.length; ++i) mock.mint(deployer, ids[i]);
        gachapon.feedToys(
            address(mock),
            ids,
            uint40(block.timestamp),
            uint40(block.timestamp + 800),
            7,
            uint16((uint256(type(uint16).max) * 100) / 80),
            30,
            0
        );

        mock = new MockERC721("Red Pandaz", "");
        mock.setApprovalForAll(address(gachapon), true);

        ids = [94, 28, 4859, 11].toMemory();
        for (uint256 i; i < ids.length; ++i) mock.mint(deployer, ids[i]);
        gachapon.feedToys(
            address(mock),
            ids,
            uint40(block.timestamp + 100),
            uint40(block.timestamp + 300),
            10,
            uint16((uint256(type(uint16).max) * 100) / 90),
            10,
            0
        );

        mock = new MockERC721("Mango Apes", "");
        mock.setApprovalForAll(address(gachapon), true);

        ids = [21, 45, 2].toMemory();
        for (uint256 i; i < ids.length; ++i) mock.mint(deployer, ids[i]);
        gachapon.feedToys(
            address(mock),
            ids,
            uint40(block.timestamp),
            uint40(block.timestamp + 900),
            8,
            uint16((uint256(type(uint16).max) * 100) / 90),
            2,
            0
        );

        mock = new MockERC721("Anonmice", "");
        mock.setApprovalForAll(address(gachapon), true);

        ids = [13].toMemory();
        for (uint256 i; i < ids.length; ++i) mock.mint(deployer, ids[i]);
        gachapon.feedToys(
            address(mock),
            ids,
            uint40(block.timestamp + 1000),
            uint40(block.timestamp + 4000),
            20,
            uint16((uint256(type(uint16).max) * 100) / 72),
            30,
            0
        );

        mock = new MockERC721("Squiwwels", "");
        mock.setApprovalForAll(address(gachapon), true);

        ids = [49, 99, 250].toMemory();
        for (uint256 i; i < ids.length; ++i) mock.mint(deployer, ids[i]);
        gachapon.feedToys(
            address(mock),
            ids,
            uint40(block.timestamp + 360000),
            uint40(block.timestamp + 400000),
            13,
            uint16((uint256(type(uint16).max) * 100) / 54),
            100,
            0
        );

        // auctions

        uint256 id;

        // mock = new MockERC721("Keijus", "");
        // mock.setApprovalForAll(address(auctionHouse), true);

        // id = 1;
        // mock.mint(deployer, id);
        // auctionHouse.createAuction(address(mock), uint40(id), 0, 0, 0, 3, uint40(block.timestamp), 1);

        mock = new MockERC721("Godjairs", "");
        mock.setApprovalForAll(address(auctionHouse), true);

        id = 69;
        mock.mint(deployer, id);
        auctionHouse.createAuction(
            address(mock),
            uint40(id),
            5,
            500,
            uint16((uint256(type(uint16).max) * 9) / 10),
            0,
            uint40(block.timestamp),
            900
        );

        mock = new MockERC721("Red Pandaz", "");
        mock.setApprovalForAll(address(auctionHouse), true);

        id = 94;
        mock.mint(deployer, id);
        auctionHouse.createAuction(address(mock), uint40(id), 0, 0, 0, 0, uint40(block.timestamp + 200), 3000);

        mock = new MockERC721("Mango Aped", "");
        mock.setApprovalForAll(address(auctionHouse), true);

        id = 21;
        mock.mint(deployer, id);
        auctionHouse.createAuction(
            address(mock),
            uint40(id),
            10,
            300,
            uint16((uint256(type(uint16).max) * 4) / 5),
            0,
            uint40(block.timestamp + 300),
            2000
        );

        mock = new MockERC721("Anonmice", "");
        mock.setApprovalForAll(address(auctionHouse), true);

        id = 13;
        mock.mint(deployer, id);
        auctionHouse.createAuction(
            address(mock),
            uint40(id),
            2,
            500,
            uint16((uint256(type(uint16).max) * 2) / 3),
            3,
            uint40(block.timestamp + 600),
            2000
        );

        // mock = new MockERC721("Squiwwels", "");
        // mock.setApprovalForAll(address(auctionHouse), true);

        // id = 49;
        // mock.mint(deployer, id);
        // auctionHouse.createAuction(address(mock), uint40(id), 0, 0, 0, 3, uint40(block.timestamp + 36000), 40000);

        gachapon.transferOwnership(msg.sender);
        auctionHouse.transferOwnership(msg.sender);
        whitelistMarket.transferOwnership(msg.sender);
    }
}

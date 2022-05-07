// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {Gachapon} from "../Gachapon.sol";
import {AuctionHouse} from "../AuctionHouse.sol";
import {WhitelistMarket} from "../WhitelistMarket.sol";
import {SoulboundTickets} from "../SoulboundTickets.sol";

import {MockGouda} from "./mocks/MockGouda.sol";
import {MockERC721} from "./mocks/MockERC721.sol";
import {MockMadMouse} from "./mocks/MockMadMouse.sol";

import {IGouda, IMadMouse} from "../lib/interfaces.sol";
import {ArrayUtils} from "./ArrayUtils.sol";

contract TestDeployGachapon {
    using ArrayUtils for *;

    IGouda public gouda;
    SoulboundTickets public tickets;
    Gachapon public gachapon;
    AuctionHouse public auctionHouse;
    WhitelistMarket public whitelistMarket;

    IMadMouse public genesis;
    IMadMouse public troupe;

    constructor(IMadMouse genesis_, IMadMouse troupe_) {
        genesis = genesis_;
        troupe = troupe_;

        gouda = IGouda(address(new MockGouda()));
        gachapon = new Gachapon(gouda, genesis, troupe);
        auctionHouse = new AuctionHouse(gouda, genesis, troupe);
        whitelistMarket = new WhitelistMarket(gouda, genesis, troupe);

        tickets = new SoulboundTickets(gachapon);
        gachapon.setTicketsImplementation(address(tickets));
    }

    function initRaffles() external {
        address deployer = address(this);

        MockERC721 mock;
        uint32[] memory ids;

        mock = new MockERC721("Land Of Valeria", "");
        mock.setApprovalForAll(address(gachapon), true);

        ids = [3877, 5592, 8877, 9048, 9911].toMemory32();
        for (uint256 i; i < ids.length; ++i) mock.mint(deployer, ids[i]);
        gachapon.feedToys(
            address(mock),
            ids,
            uint40(block.timestamp),
            uint40(block.timestamp + 10),
            7,
            uint8((uint256(255) * 66) / 100),
            30,
            0
        );

        mock = new MockERC721("Clementines Nightmare", "");
        mock.setApprovalForAll(address(gachapon), true);

        ids = [1003, 3898, 4064, 4936].toMemory32();
        for (uint256 i; i < ids.length; ++i) mock.mint(deployer, ids[i]);
        gachapon.feedToys(
            address(mock),
            ids,
            uint40(block.timestamp),
            uint40(block.timestamp + 1400),
            7,
            uint8((uint256(255) * 80) / 100),
            30,
            0
        );

        mock = new MockERC721("Dysto Apez", "");
        mock.setApprovalForAll(address(gachapon), true);

        ids = [3043].toMemory32();
        for (uint256 i; i < ids.length; ++i) mock.mint(deployer, ids[i]);
        gachapon.feedToys(
            address(mock),
            ids,
            uint40(block.timestamp + 500),
            uint40(block.timestamp + 2300),
            10,
            uint8((uint256(255) * 90) / 100),
            10,
            0
        );

        mock = new MockERC721("Illogics", "");
        mock.setApprovalForAll(address(gachapon), true);

        ids = [5742, 7484].toMemory32();
        for (uint256 i; i < ids.length; ++i) mock.mint(deployer, ids[i]);
        gachapon.feedToys(
            address(mock),
            ids,
            uint40(block.timestamp),
            uint40(block.timestamp + 1900),
            8,
            uint8((uint256(255) * 90) / 100),
            2,
            0
        );

        mock = new MockERC721("Kaiju Mutants", "");
        mock.setApprovalForAll(address(gachapon), true);

        ids = [279, 559].toMemory32();
        for (uint256 i; i < ids.length; ++i) mock.mint(deployer, ids[i]);
        gachapon.feedToys(
            address(mock),
            ids,
            uint40(block.timestamp + 1000),
            uint40(block.timestamp + 4000),
            20,
            uint8((uint256(255) * 72) / 100),
            30,
            0
        );

        mock = new MockERC721("Scolarz", "");
        mock.setApprovalForAll(address(gachapon), true);

        ids = [784, 2251].toMemory32();
        for (uint256 i; i < ids.length; ++i) mock.mint(deployer, ids[i]);
        gachapon.feedToys(
            address(mock),
            ids,
            uint40(block.timestamp + 360000),
            uint40(block.timestamp + 400000),
            13,
            uint8((uint256(255) * 54) / 100),
            100,
            0
        );

        // mock = new MockERC721("Star Wolvez", "");
        // mock.setApprovalForAll(address(gachapon), true);

        // ids = [2435, 3744, 4101, 4278, 4619].toMemory32();
        // for (uint256 i; i < ids.length; ++i) mock.mint(deployer, ids[i]);
        // gachapon.feedToys(
        //     address(mock),
        //     ids,
        //     uint40(block.timestamp + 360000),
        //     uint40(block.timestamp + 400000),
        //     13,
        //     uint8((uint256(255) * 54) / 100),
        //     100,
        //     0
        // );

        // mock = new MockERC721("Starcatchers", "");
        // mock.setApprovalForAll(address(gachapon), true);

        // ids = [2959, 5298].toMemory32();
        // for (uint256 i; i < ids.length; ++i) mock.mint(deployer, ids[i]);
        // gachapon.feedToys(
        //     address(mock),
        //     ids,
        //     uint40(block.timestamp + 360000),
        //     uint40(block.timestamp + 400000),
        //     13,
        //     uint8((uint256(255) * 54) / 100),
        //     100,
        //     0
        // );

        // mock = new MockERC721("Tasty Bonex XYZ", "");
        // mock.setApprovalForAll(address(gachapon), true);

        // ids = [312, 411].toMemory32();
        // for (uint256 i; i < ids.length; ++i) mock.mint(deployer, ids[i]);
        // gachapon.feedToys(
        //     address(mock),
        //     ids,
        //     uint40(block.timestamp + 360000),
        //     uint40(block.timestamp + 400000),
        //     13,
        ///    uint8((uint256(255) * 54) / 100),
        //     100,
        //     0
        // );
    }

    function initAuctions() external {
        // auctions

        address deployer = address(this);

        MockERC721 mock;

        uint256 id;

        mock = new MockERC721("Antonym Genesis", "");
        mock.setApprovalForAll(address(auctionHouse), true);

        id = 1334;
        mock.mint(deployer, id);
        auctionHouse.createAuction(
            address(mock),
            uint40(id),
            5,
            500,
            uint8((uint256(255) * 9) / 10),
            0,
            uint40(block.timestamp),
            1900
        );

        mock = new MockERC721("Arcade Land", "");
        mock.setApprovalForAll(address(auctionHouse), true);

        id = 7716;
        mock.mint(deployer, id);
        auctionHouse.createAuction(address(mock), uint40(id), 0, 0, 0, 0, uint40(block.timestamp + 900), 3000);

        mock = new MockERC721("Dysto Apez", "");
        mock.setApprovalForAll(address(auctionHouse), true);

        id = 1424;
        mock.mint(deployer, id);
        auctionHouse.createAuction(
            address(mock),
            uint40(id),
            10,
            300,
            uint8((uint256(255) * 4) / 5),
            0,
            uint40(block.timestamp + 700),
            2000
        );

        mock = new MockERC721("Karafuru", "");
        mock.setApprovalForAll(address(auctionHouse), true);

        id = 1035;
        mock.mint(deployer, id);
        auctionHouse.createAuction(
            address(mock),
            uint40(id),
            2,
            500,
            uint8((uint256(255) * 2) / 3),
            3,
            uint40(block.timestamp + 600),
            2000
        );

        mock = new MockERC721("Tasty Bones", "");
        mock.setApprovalForAll(address(auctionHouse), true);

        id = 2621;
        mock.mint(deployer, id);
        auctionHouse.createAuction(
            address(mock),
            uint40(id),
            2,
            500,
            uint8((uint256(255) * 2) / 3),
            3,
            uint40(block.timestamp + 600),
            2000
        );

        // mock = new MockERC721("Clementines Nightmare", "");
        // mock.setApprovalForAll(address(auctionHouse), true);

        // id = 3862;
        // mock.mint(deployer, id);
        // auctionHouse.createAuction(
        //     address(mock),
        //     uint40(id),
        //     2,
        //     500,
        //     uint8((uint256(255) * 2) / 3),
        //     3,
        //     uint40(block.timestamp + 600),
        //     2000
        // );

        // mock = new MockERC721("Kaiju Mutants", "");
        // mock.setApprovalForAll(address(auctionHouse), true);

        // id = 3727;
        // mock.mint(deployer, id);
        // auctionHouse.createAuction(
        //     address(mock),
        //     uint40(id),
        //     2,
        //     500,
        //     uint8((uint256(255) * 2) / 3),
        //     3,
        //     uint40(block.timestamp + 600),
        //     2000
        // );

        // mock = new MockERC721("Starcatchers", "");
        // mock.setApprovalForAll(address(auctionHouse), true);

        // id = 1442;
        // mock.mint(deployer, id);
        // auctionHouse.createAuction(
        //     address(mock),
        //     uint40(id),
        //     2,
        //     500,
        //     uint8((uint256(255) * 2) / 3),
        //     3,
        //     uint40(block.timestamp + 600),
        //     2000
        // );

        // mock = new MockERC721("Tasty Bones", "");
        // mock.setApprovalForAll(address(auctionHouse), true);

        // id = 4713;
        // mock.mint(deployer, id);
        // auctionHouse.createAuction(
        //     address(mock),
        //     uint40(id),
        //     2,
        //     500,
        //     uint8((uint256(255) * 2) / 3),
        //     3,
        //     uint40(block.timestamp + 600),
        //     2000
        // );

        gachapon.transferOwnership(msg.sender);
        auctionHouse.transferOwnership(msg.sender);
        whitelistMarket.transferOwnership(msg.sender);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.12;

import "./lib/ERC721.sol";
import {Gachapon} from "./Gachapon.sol";

error CallerNotApproved();
error CallerNotOwner();

contract Tickets is ERC721 {
    uint256 immutable raffleId;
    Gachapon immutable gachapon = Gachapon(msg.sender);

    uint256 public totalSupply;

    constructor(
        uint256 raffleId_,
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {
        raffleId = raffleId_;
    }

    function mint(address to) external onlyGachapon {
        ownerOf[totalSupply++] = to;
    }

    function burnFrom(address from, uint256 id) external onlyGachapon {
        if (ownerOf[id] != from) revert CallerNotOwner();

        emit Transfer(from, address(0), id);
        delete ownerOf[id];
    }

    modifier onlyGachapon() {
        if (msg.sender != address(gachapon)) revert CallerNotApproved();
        _;
    }

    function tokenURI(uint256 id)
        external
        view
        override
        returns (string memory)
    {
        return
            gachapon.isGoldenTicket(raffleId, id)
                ? "ipfs/QmcU3dhpgV9uWwgWQ7aPCsyZSYZDZMCKj1FrDJCEQAceoP/winning-ticket.json"
                : "ipfs/QmcU3dhpgV9uWwgWQ7aPCsyZSYZDZMCKj1FrDJCEQAceoP/raffle-ticket.json";
    }
}

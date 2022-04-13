// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {Gachapon} from "./Gachapon.sol";

error CallerNotOwner();
error CallerNotApproved();
error CallerNotOwnerNorApproved();

error MintExceedsLimit();

error TransferFromIncorrectOwner();
error TransferToNonERC721Receiver();
error TransferToZeroAddress();

error BurnFromIncorrectOwner();

error TransferDisabled();

contract Tickets {
    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    // event Approval(address indexed owner, address indexed spender, uint256 indexed id);
    // event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    mapping(uint256 => address) public ownerOf;
    mapping(address => uint256) public balanceOf;
    // mapping(uint256 => address) public getApproved;
    // mapping(address => mapping(address => bool)) public isApprovedForAll;

    Gachapon immutable gachapon;

    constructor(Gachapon gachapon_) {
        gachapon = gachapon_;
    }

    // /* ------------- External ------------- */

    // function approve(address spender, uint256 id) external virtual {
    //     address owner = ownerOf[id];

    //     if ((msg.sender != owner && !isApprovedForAll[owner][msg.sender])) revert CallerNotOwnerNorApproved();

    //     getApproved[id] = spender;

    //     emit Approval(owner, spender, id);
    // }

    // function setApprovalForAll(address operator, bool approved) external virtual {
    //     isApprovedForAll[msg.sender][operator] = approved;

    //     emit ApprovalForAll(msg.sender, operator, approved);
    // }

    // function transferFrom(
    //     address from,
    //     address to,
    //     uint256 id
    // ) public virtual {
    //     if (!transferEnabled) revert TransferDisabled();
    //     if (to == address(0)) revert TransferToZeroAddress();

    //     if (ownerOf[id] != from) revert TransferFromIncorrectOwner();
    //     if (msg.sender != from && !isApprovedForAll[from][msg.sender] && getApproved[id] != msg.sender)
    //         revert CallerNotOwnerNorApproved();

    //     ownerOf[id] = to;

    //     delete getApproved[id];

    //     emit Transfer(from, to, id);
    // }

    // function safeTransferFrom(
    //     address from,
    //     address to,
    //     uint256 id
    // ) external virtual {
    //     safeTransferFrom(from, to, id, "");
    // }

    // function safeTransferFrom(
    //     address from,
    //     address to,
    //     uint256 id,
    //     bytes memory data
    // ) public virtual {
    //     transferFrom(from, to, id);

    //     if (
    //         to.code.length != 0 &&
    //         IERC721Receiver(to).onERC721Received(msg.sender, from, id, data) !=
    //         IERC721Receiver(to).onERC721Received.selector
    //     ) revert TransferToNonERC721Receiver();
    // }

    // function supportsInterface(bytes4 interfaceId) external view virtual returns (bool) {
    //     return
    //         interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
    //         interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
    //         interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    // }

    /* ------------- View ------------- */

    function tokenURI(uint256 id) external view returns (string memory) {
        return gachapon.ticketsTokenURI(id);
    }

    function name() external view returns (string memory) {
        return gachapon.ticketsName();
    }

    function symbol() external view returns (string memory) {
        return gachapon.ticketsSymbol();
    }

    /* ------------- Restricted ------------- */

    // @note assumes correct handling by master contract in order to save gas
    function mint(address to, uint256 id) external onlyGachapon {
        if (balanceOf[to] == 1) revert MintExceedsLimit();

        ownerOf[id] = to;

        unchecked {
            ++balanceOf[to];
        }

        emit Transfer(address(0), to, id);
    }

    function burnFrom(address from, uint256 id) external onlyGachapon {
        if (ownerOf[id] != from) revert BurnFromIncorrectOwner();

        unchecked {
            --balanceOf[from];
        }

        emit Transfer(from, address(0), id);

        delete ownerOf[id];
        // delete getApproved[id];
    }

    modifier onlyGachapon() {
        if (msg.sender != address(gachapon)) revert CallerNotApproved();
        _;
    }

    /* ------------- O(N) Read Only ------------- */

    function ticketIdOf(address user) external view returns (uint256) {
        unchecked {
            uint256 supply = gachapon.ticketsSupply() + 1;
            for (uint256 id; id < supply; ++id) if (ownerOf[id] == user) return id;
            return 0;
        }
    }
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// import "./lib/ERC721.sol";
import {Gachapon} from "./Gachapon.sol";

error CallerNotOwner();
error CallerNotApproved();
error CallerNotOwnerNorApproved();

error IncorrectOwner();
error MaxSupplyReached();

error TransferFromIncorrectOwner();
error TransferToNonERC721Receiver();
error TransferToZeroAddress();

contract Tickets {
    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    event Approval(address indexed owner, address indexed spender, uint256 indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    Gachapon immutable gachapon;

    constructor(Gachapon gachapon_) {
        gachapon = gachapon_;
    }

    /* ------------- Public ------------- */

    function approve(address spender, uint256 id) public virtual {
        address owner = ownerOf[id];
        if ((msg.sender != owner && !isApprovedForAll[owner][msg.sender])) revert CallerNotOwnerNorApproved();

        getApproved[id] = spender;
        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        if (ownerOf[id] != from) revert TransferFromIncorrectOwner();
        if (to == address(0)) revert TransferToZeroAddress();
        if (msg.sender != from && !isApprovedForAll[from][msg.sender] && getApproved[id] != msg.sender)
            revert CallerNotOwnerNorApproved();

        ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        safeTransferFrom(from, to, id, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual {
        transferFrom(from, to, id);

        if (
            to.code.length != 0 &&
            IERC721Receiver(to).onERC721Received(msg.sender, from, id, data) !=
            IERC721Receiver(to).onERC721Received.selector
        ) revert TransferToNonERC721Receiver();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /* ------------- Restricted ------------- */

    // @note assumes correct id minting is handled by master contract (saves gas)
    function mint(address to, uint256 id) external onlyGachapon {
        // if (ownerOf[id] != address(0)) revert IncorrectOwner();
        // if (totalSupply == maxAdmission) revert MaxSupplyReached();
        ownerOf[id] = to;
        emit Transfer(address(0), to, id);
    }

    function burnFrom(address from, uint256 id) external onlyGachapon {
        if (ownerOf[id] != from) revert CallerNotOwner();

        emit Transfer(from, address(0), id);

        delete ownerOf[id];
        delete getApproved[id];
    }

    modifier onlyGachapon() {
        if (msg.sender != address(gachapon)) revert CallerNotApproved();
        _;
    }

    function tokenURI(uint256 id) external view returns (string memory) {
        return gachapon.ticketsTokenURI(id);
    }

    function name() external view returns (string memory) {
        return gachapon.ticketsName();
    }

    function symbol() external view returns (string memory) {
        return gachapon.ticketsSymbol();
    }

    /* ------------- O(N) Read Only ------------- */

    function balanceOf(address user) external view returns (uint256) {
        uint256 count;
        uint256 supply = gachapon.ticketsSupply();
        unchecked {
            for (uint256 i; i < supply; ++i) if (ownerOf[i] == user) ++count;
        }
        return count;
    }

    function tokenIdsOf(address user) external view returns (uint256[] memory ids) {
        uint256 balance = this.balanceOf(user);
        uint256 supply = gachapon.ticketsSupply();
        ids = new uint256[](balance);
        uint256 count;
        unchecked {
            for (uint256 i; i < supply; ++i) {
                if (ownerOf[i] == user) {
                    ids[count++] = i;
                    if (count == balance) break;
                }
            }
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

interface ITickets {
    function totalSupply() external returns (uint256);

    function mint(address to) external;

    function burnFrom(address from, uint256 id) external;

    // function tokenURI(uint256 id)
    //     external
    //     view
    //     override
    //     returns (string memory)
    // {
    //     return
    //         gachapon.isGoldenTicket(raffleId, id)
    //             ? "ipfs/QmcU3dhpgV9uWwgWQ7aPCsyZSYZDZMCKj1FrDJCEQAceoP/winning-ticket.json"
    //             : "ipfs/QmcU3dhpgV9uWwgWQ7aPCsyZSYZDZMCKj1FrDJCEQAceoP/raffle-ticket.json";
    // }
}

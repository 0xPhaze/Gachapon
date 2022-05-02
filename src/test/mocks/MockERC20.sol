// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "../../../lib/solmate/src/tokens/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol, 18) {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function burnFrom(address account, uint256 amount) public {
        // _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockGouda is ERC20("Gouda", "GOUDA") {
    function mint(address user, uint256 amount) external {
        _mint(user, amount);
    }

    function burnFrom(address account, uint256 amount) external {
        _burn(account, amount);
    }
}

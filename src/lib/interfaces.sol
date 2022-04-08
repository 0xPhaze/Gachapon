// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

interface IGouda {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external;

    function burnFrom(address account, uint256 amount) external;
}

interface IMadMouse {
    function numStaked(address user) external returns (uint256);
}

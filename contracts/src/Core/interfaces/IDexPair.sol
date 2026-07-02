// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

interface IDexPair {
    function initialise(address token0, address token1) external;
}
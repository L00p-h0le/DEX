// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;


interface IDexCallee {
    function dexV2Call(
        address sender,
        uint amount0Out,
        uint amount1Out,
        bytes calldata data
    ) external;
}
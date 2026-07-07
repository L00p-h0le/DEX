// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {DexLibrary} from "../../src/Periphery/libraries/DexLibrary.sol";

contract DexLibraryWrapper {

    function sortTokens(address tokenA, address tokenB) external pure returns (address, address) {
        return DexLibrary.sortTokens(tokenA, tokenB);
    }

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint) {
        return DexLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint) {
        return DexLibrary.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint) {
        return DexLibrary.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(address factory, uint amountIn, address[] memory path) external view returns (uint[] memory) {
        return DexLibrary.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(address factory, uint amountOut, address[] memory path) external view returns (uint[] memory) {
        return DexLibrary.getAmountsIn(factory, amountOut, path);
    }

    function pairFor(address factory, address tokenA, address tokenB) external pure returns (address) {
        return DexLibrary.pairFor(factory, tokenA, tokenB);
    }
}
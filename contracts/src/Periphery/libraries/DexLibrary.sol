// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IDexPair} from '../../Core/interfaces/IDexPair.sol';

/// @title DexLibrary
/// @notice Provides functions to perform routing and price calculations
library DexLibrary {

    error Identical_Address();
    error Zero_Address();
    error Insufficient_Amount();
    error Insufficient_Liquidity();
    error Insufficient_InputAmount();
    error Insufficient_OutputAmount();
    error Invalid_Path();

    /// @notice Sorts two token addresses
    /// @param tokenA First token address
    /// @param tokenB Second token address
    /// @return token0 Sorted token0 address
    /// @return token1 Sorted token1 address
    function sortTokens(address tokenA , address tokenB) internal pure returns (address token0 , address token1){
        if(tokenA == tokenB) revert Identical_Address();
        (token0 , token1) = tokenA < tokenB ? (tokenA , tokenB) : (tokenB , tokenA);
        if(token0 == address(0)) revert Zero_Address(); 
    }

    /// @notice Calculates the pair address for two tokens
    /// @param factory Address of the factory contract
    /// @param tokenA First token address
    /// @param tokenB Second token address
    /// @return pair The calculated pair address
    function pairFor(address factory , address tokenA , address tokenB) internal pure returns(address pair) {
        (address token0 , address token1) = sortTokens(tokenA , tokenB);
        pair = address(uint160(uint256(keccak256(abi.encodePacked(
            hex'ff' , 
            factory , 
            keccak256(abi.encodePacked(token0 , token1)),
            hex'6c7bf9dcd6d2962073cadd21ac067fba455f40a2e103ebc77d039321341bfc85'
            )))));
    }

    /// @notice Fetches the reserves for a given token pair
    /// @param factory Address of the factory contract
    /// @param tokenA First token address
    /// @param tokenB Second token address
    /// @return reserveA Reserve of tokenA
    /// @return reserveB Reserve of tokenB
    function getReserves(address factory , address tokenA , address tokenB) internal view returns(uint reserveA , uint reserveB) {
        (address token0,) = sortTokens(tokenA , tokenB);
        (uint reserve0 , uint reserve1 , ) = IDexPair(pairFor(factory , tokenA , tokenB)).getReserve(); 
        (reserveA ,reserveB) = tokenA == token0 ? (reserve0 , reserve1) : (reserve1 , reserve0);
    }

    /// @notice Given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    /// @param amountA Amount of tokenA
    /// @param reserveA Reserve of tokenA
    /// @param reserveB Reserve of tokenB
    /// @return amountB Equivalent amount of tokenB
    function quote(uint amountA , uint reserveA , uint reserveB) internal pure returns(uint amountB) {
        if(amountA == 0) revert Insufficient_Amount();
        if(reserveA == 0 || reserveB == 0) revert Insufficient_Liquidity();
        amountB = (amountA * reserveB) / reserveA;
    }

    /// @notice Given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    /// @param amountIn Amount of the input token
    /// @param reserveIn Reserve of the input token
    /// @param reserveOut Reserve of the output token
    /// @return amountOut Maximum amount of the output token
    function getAmountOut( uint amountIn , uint reserveIn , uint reserveOut) internal pure returns(uint amountOut) {
        if(amountIn == 0) revert Insufficient_InputAmount();
        if(reserveIn == 0 || reserveOut == 0) revert Insufficient_Liquidity();

        uint amountInWithFee = amountIn * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = (reserveIn * 1000) + amountInWithFee;
        amountOut = numerator / denominator;
    }

    /// @notice Given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    /// @param amountOut Desired amount of the output token
    /// @param reserveIn Reserve of the input token
    /// @param reserveOut Reserve of the output token
    /// @return amountIn Required amount of the input token
    function getAmountIn( uint amountOut , uint reserveIn , uint reserveOut) internal pure returns(uint amountIn){
        if(amountOut == 0) revert Insufficient_OutputAmount();
        if(reserveIn == 0 || reserveOut == 0) revert Insufficient_Liquidity();

        uint numerator = reserveIn * amountOut * 1000;
        uint denominator = (reserveOut - amountOut) * 997;

        amountIn = (numerator / denominator) + 1;        
    }

    /// @notice Performs chained getAmountOut calculations on any number of pairs
    /// @param factory Address of the factory contract
    /// @param amountIn Initial input amount
    /// @param path Array of token addresses representing the routing path
    /// @return amounts Array containing calculated amounts at each step
    function getAmountsOut( address factory , uint amountIn , address[] memory path ) internal view returns(uint[] memory amounts){
        if(path.length < 2) revert Invalid_Path();
        amounts = new uint[](path.length);
        amounts[0] = amountIn;

        for(uint i = 0; i < path.length - 1 ; i++){
            (uint reserveIn , uint reserveOut) = getReserves(factory , path[i] , path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i] , reserveIn , reserveOut);
        }
    }

    /// @notice Performs chained getAmountIn calculations on any number of pairs
    /// @param factory Address of the factory contract
    /// @param amountOut Desired final output amount
    /// @param path Array of token addresses representing the routing path
    /// @return amounts Array containing calculated amounts at each step
    function getAmountsIn( address factory , uint amountOut , address[] memory path) internal view returns(uint[] memory amounts){
        if(path.length < 2) revert Invalid_Path();
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;

        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}
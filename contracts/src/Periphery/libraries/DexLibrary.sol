// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IDexPair} from '../../Core/interfaces/IDexPair.sol';

library DexLibrary {

    error Identical_Address();
    error Zero_Address();
    error Insufficient_Amount();
    error Insufficient_Liquidity();
    error Insufficient_InputAmount();
    error Insufficient_OutputAmount();
    error Invalid_Path();

    function sortTokens(address tokenA , address tokenB) internal pure returns (address token0 , address token1){
        if(tokenA == tokenB) revert Identical_Address();
        (token0 , token1) = tokenA < tokenB ? (tokenA , tokenB) : (tokenB , tokenA);
        if(token0 == address(0)) revert Zero_Address(); 
    }

    function pairFor(address factory , address tokenA , address tokenB) internal pure returns(address pair) {
        (address token0 , address token1) = sortTokens(tokenA , tokenB);
        pair = address(uint160(uint256(keccak256(abi.encodePacked(
            hex'ff' , 
            factory , 
            keccak256(abi.encodePacked(token0 , token1)),
            hex'b5a099064a9f7c2a3b51200d0313d1e5be1698f177620b38a7c19394132dc417'
            )))));
    }

    function getReserves(address factory , address tokenA , address tokenB) internal view returns(uint reserveA , uint reserveB) {
        (address token0,) = sortTokens(tokenA , tokenB);
        (uint reserve0 , uint reserve1 , ) = IDexPair(pairFor(factory , tokenA , tokenB)).getReserve(); 
        (reserveA ,reserveB) = tokenA == token0 ? (reserve0 , reserve1) : (reserve1 , reserve0);
    }

    function quote(uint amountA , uint reserveA , uint reserveB) internal pure returns(uint amountB) {
        if(amountA == 0) revert Insufficient_Amount();
        if(reserveA == 0 || reserveB == 0) revert Insufficient_Liquidity();
        amountB = (amountA * reserveB) / reserveA;
    }

    function getAmountOut( uint amountIn , uint reserveIn , uint reserveOut) internal pure returns(uint amountOut) {
        if(amountIn == 0) revert Insufficient_InputAmount();
        if(reserveIn == 0 || reserveOut == 0) revert Insufficient_Liquidity();

        uint amountInWithFee = amountIn * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = (reserveIn * 1000) + amountInWithFee;
        amountOut = numerator / denominator;
    }

    function getAmountIn( uint amountOut , uint reserveIn , uint reserveOut) internal pure returns(uint amountIn){
        if(amountOut == 0) revert Insufficient_OutputAmount();
        if(reserveIn == 0 || reserveOut == 0) revert Insufficient_Liquidity();

        uint numerator = reserveIn * amountOut * 1000;
        uint denominator = (reserveOut - amountOut) * 997;

        amountIn = (numerator / denominator) + 1;        
    }

    function getAmountsOut( address factory , uint amountIn , address[] memory path ) internal view returns(uint[] memory amounts){
        if(path.length < 2) revert Invalid_Path();
        amounts = new uint[](path.length);
        amounts[0] = amountIn;

        for(uint i = 0; i < path.length - 1 ; i++){
            (uint reserveIn , uint reserveOut) = getReserves(factory , path[i] , path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i] , reserveIn , reserveOut);
        }
    }

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
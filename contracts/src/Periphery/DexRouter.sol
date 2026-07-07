// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IDexFactory} from '../Core/interfaces/IDexFactory.sol';
import {IDexPair} from '../Core/interfaces/IDexPair.sol';
import {DexLibrary} from './libraries/DexLibrary.sol';
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract DexRouter {
    using SafeERC20 for IERC20;

    address public immutable factory;
    
    error Expired();
    error Insufficient_AAmount();
    error Insufficient_BAmount();
    error Insufficient_OutputAmount();
    error Excessive_InputAmount();

    modifier ensure(uint deadline) {
        if(deadline < block.timestamp) revert Expired();
        _;
    }

    constructor(address _factory){
        factory = _factory;
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal virtual returns (uint amountA, uint amountB) {

        // create the pair if it doesn't exist yet
        if (IDexFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            IDexFactory(factory).createPair(tokenA, tokenB);
        }

        (uint reserveA, uint reserveB) = DexLibrary.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = DexLibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                    if(amountBOptimal < amountBMin) revert Insufficient_BAmount();
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = DexLibrary.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                    if(amountAOptimal < amountAMin) revert Insufficient_AAmount();
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external virtual ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = DexLibrary.pairFor(factory, tokenA, tokenB);

        {
            IERC20(tokenA).safeTransferFrom(msg.sender , pair , amountA);
            IERC20(tokenB).safeTransferFrom(msg.sender , pair , amountB);
            liquidity = IDexPair(pair).mint(to);
        }
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public virtual ensure(deadline) returns (uint amountA, uint amountB) {
        address pair = DexLibrary.pairFor(factory, tokenA, tokenB);
        IERC20(pair).safeTransferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint amount0, uint amount1) = IDexPair(pair).burn(to);
        (address token0,) = DexLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        if(amountA < amountAMin) revert Insufficient_AAmount();
        if(amountB < amountBMin) revert Insufficient_BAmount();
    }
 

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint[] memory amounts, address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {

            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = DexLibrary.sortTokens(input, output);
            uint amountOut = amounts[i + 1];

            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? DexLibrary.pairFor(factory, output, path[i + 2]) : _to;
            IDexPair(DexLibrary.pairFor(factory, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual ensure(deadline) returns (uint[] memory amounts) {
        amounts = DexLibrary.getAmountsOut(factory, amountIn, path);
        if(amounts[amounts.length - 1] < amountOutMin) revert Insufficient_OutputAmount();
        IERC20(path[0]).safeTransferFrom(
            msg.sender, DexLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual ensure(deadline) returns (uint[] memory amounts) {
        amounts = DexLibrary.getAmountsIn(factory, amountOut, path);
        if(amounts[0] > amountInMax) revert Excessive_InputAmount();
        IERC20(path[0]).safeTransferFrom(
            msg.sender, DexLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }
   
    // **** LIBRARY FUNCTIONS ****

    function quote(uint amountA, uint reserveA, uint reserveB) public pure virtual returns (uint amountB) {
        return DexLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public pure returns (uint amountOut) {
        return DexLibrary.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) public pure returns (uint amountIn) {
        return DexLibrary.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint amountIn, address[] memory path) public view returns (uint[] memory amounts) {
        return DexLibrary.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint amountOut, address[] memory path) public view returns (uint[] memory amounts) {
        return DexLibrary.getAmountsIn(factory, amountOut, path);
    }
}
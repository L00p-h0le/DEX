// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IDexFactory} from '../Core/interfaces/IDexFactory.sol';
import {IDexPair} from '../Core/interfaces/IDexPair.sol';
import {DexLibrary} from './libraries/DexLibrary.sol';
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title DexRouter
/// @notice Router for interacting with the DEX, handling liquidity management and token swaps
contract DexRouter {
    using SafeERC20 for IERC20;

    /// @notice The factory contract address
    address public immutable factory;
    
    error Expired();
    error Insufficient_AAmount();
    error Insufficient_BAmount();
    error Insufficient_OutputAmount();
    error Excessive_InputAmount();

    /// @notice Modifier to ensure the transaction is executed before the deadline
    /// @param deadline The timestamp after which the transaction will revert
    modifier ensure(uint deadline) {
        if(deadline < block.timestamp) revert Expired();
        _;
    }

    /// @notice Constructs the router with the factory address
    /// @param _factory The address of the DexFactory
    constructor(address _factory){
        factory = _factory;
    }

    // **** ADD LIQUIDITY ****
    /// @notice Internal helper to calculate optimal liquidity amounts
    /// @param tokenA The first token address
    /// @param tokenB The second token address
    /// @param amountADesired The desired amount of tokenA
    /// @param amountBDesired The desired amount of tokenB
    /// @param amountAMin The minimum acceptable amount of tokenA
    /// @param amountBMin The minimum acceptable amount of tokenB
    /// @return amountA The optimal amount of tokenA
    /// @return amountB The optimal amount of tokenB
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

    /// @notice Adds liquidity to a pair
    /// @param tokenA The first token address
    /// @param tokenB The second token address
    /// @param amountADesired The desired amount of tokenA
    /// @param amountBDesired The desired amount of tokenB
    /// @param amountAMin The minimum acceptable amount of tokenA
    /// @param amountBMin The minimum acceptable amount of tokenB
    /// @param to The recipient of the liquidity tokens
    /// @param deadline The transaction deadline
    /// @return amountA The actual amount of tokenA deposited
    /// @return amountB The actual amount of tokenB deposited
    /// @return liquidity The amount of liquidity tokens minted
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
    /// @notice Removes liquidity from a pair
    /// @param tokenA The first token address
    /// @param tokenB The second token address
    /// @param liquidity The amount of liquidity tokens to burn
    /// @param amountAMin The minimum acceptable amount of tokenA returned
    /// @param amountBMin The minimum acceptable amount of tokenB returned
    /// @param to The recipient of the withdrawn tokens
    /// @param deadline The transaction deadline
    /// @return amountA The actual amount of tokenA returned
    /// @return amountB The actual amount of tokenB returned
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
    /// @notice Internal helper to execute a chain of swaps
    /// @param amounts Array of amounts to swap at each step
    /// @param path Array of token addresses representing the routing path
    /// @param _to The final recipient address
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

    /// @notice Swaps an exact input amount for a maximum possible output amount
    /// @param amountIn The exact amount of input tokens
    /// @param amountOutMin The minimum acceptable amount of output tokens
    /// @param path Array of token addresses representing the routing path
    /// @param to The recipient of the output tokens
    /// @param deadline The transaction deadline
    /// @return amounts Array containing calculated amounts at each step
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

    /// @notice Swaps a variable input amount to receive an exact output amount
    /// @param amountOut The exact amount of output tokens
    /// @param amountInMax The maximum acceptable amount of input tokens
    /// @param path Array of token addresses representing the routing path
    /// @param to The recipient of the output tokens
    /// @param deadline The transaction deadline
    /// @return amounts Array containing calculated amounts at each step
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

    /// @notice Provides quote calculation
    /// @param amountA Amount of tokenA
    /// @param reserveA Reserve of tokenA
    /// @param reserveB Reserve of tokenB
    /// @return amountB Equivalent amount of tokenB
    function quote(uint amountA, uint reserveA, uint reserveB) public pure virtual returns (uint amountB) {
        return DexLibrary.quote(amountA, reserveA, reserveB);
    }

    /// @notice Calculates the maximum output amount for a given input amount
    /// @param amountIn Amount of the input token
    /// @param reserveIn Reserve of the input token
    /// @param reserveOut Reserve of the output token
    /// @return amountOut Maximum amount of the output token
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public pure returns (uint amountOut) {
        return DexLibrary.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    /// @notice Calculates the required input amount for a given output amount
    /// @param amountOut Desired amount of the output token
    /// @param reserveIn Reserve of the input token
    /// @param reserveOut Reserve of the output token
    /// @return amountIn Required amount of the input token
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) public pure returns (uint amountIn) {
        return DexLibrary.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    /// @notice Calculates the output amounts for a given input amount across a path
    /// @param amountIn Initial input amount
    /// @param path Array of token addresses representing the routing path
    /// @return amounts Array containing calculated amounts at each step
    function getAmountsOut(uint amountIn, address[] memory path) public view returns (uint[] memory amounts) {
        return DexLibrary.getAmountsOut(factory, amountIn, path);
    }

    /// @notice Calculates the required input amounts for a given output amount across a path
    /// @param amountOut Desired final output amount
    /// @param path Array of token addresses representing the routing path
    /// @return amounts Array containing calculated amounts at each step
    function getAmountsIn(uint amountOut, address[] memory path) public view returns (uint[] memory amounts) {
        return DexLibrary.getAmountsIn(factory, amountOut, path);
    }
}
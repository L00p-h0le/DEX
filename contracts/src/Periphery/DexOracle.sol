// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IDexFactory} from '../Core/interfaces/IDexFactory.sol';
import {IDexPair} from '../Core/interfaces/IDexPair.sol';
import {UQ112x112} from './libraries/UQ112x112.sol';
import {OracleLibrary} from "./libraries/OracleLibrary.sol";

/// @title DexOracle
/// @notice A time-weighted average price (TWAP) oracle for DEX pairs
contract DexOracle {

    /// @notice The period of time for the TWAP
    uint public constant PERIOD = 24 hours;
    uint224 constant Q112 = 2**112;

    /// @notice The pair contract this oracle tracks
    IDexPair public immutable pair;
    /// @notice Address of token0
    address public immutable token0;
    /// @notice Address of token1
    address public immutable token1;

    /// @notice Last cumulative price of token0
    uint public price0CumulativeLast;
    /// @notice Last cumulative price of token1
    uint public price1CumulativeLast;
    /// @notice Timestamp of the last update
    uint32 public blockTimestampLast;

    /// @notice Average price of token0 over the period
    uint224 public price0Average;
    /// @notice Average price of token1 over the period
    uint224 public price1Average;

    error No_Reserves();
    error Period_NotElapsed();
    error Pair_NotFound();
    error Invalid_Token();

    /// @notice Emitted when the oracle is updated
    /// @param price0Average The updated average price of token0
    /// @param price1Average The updated average price of token1
    /// @param timestamp The timestamp of the update
    event OracleUpdated(uint224 price0Average , uint224 price1Average , uint32 timestamp);

    /// @notice Constructs the DexOracle
    /// @param factory The factory contract address
    /// @param tokenA The address of the first token
    /// @param tokenB The address of the second token
    constructor(address factory, address tokenA, address tokenB){

        address pairAddress = IDexFactory(factory).getPair(tokenA, tokenB);
        if(pairAddress == address(0)) revert Pair_NotFound();

        pair = IDexPair(pairAddress);
        token0 = pair.token0();
        token1 = pair.token1();
        price0CumulativeLast = pair.price0CumulativeLast();
        price1CumulativeLast = pair.price1CumulativeLast(); 

        uint112 reserve0;
        uint112 reserve1;

        (reserve0, reserve1, blockTimestampLast) = pair.getReserve();
        if(reserve0 == 0 || reserve1 == 0) revert No_Reserves();

    }

    /// @notice Updates the TWAP values
    function update() external {

        (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) =
            OracleLibrary.currentCumulativePrices(address(pair));
            
        uint32 timeElapsed;
        unchecked{
           timeElapsed = blockTimestamp - blockTimestampLast; 
        }

        if(timeElapsed < PERIOD) revert Period_NotElapsed();

        unchecked{
            price0Average = (uint224((price0Cumulative - price0CumulativeLast) / timeElapsed));
            price1Average = (uint224((price1Cumulative - price1CumulativeLast) / timeElapsed));
        }
 
        price0CumulativeLast = price0Cumulative;
        price1CumulativeLast = price1Cumulative;
        blockTimestampLast = blockTimestamp;

        emit OracleUpdated(price0Average , price1Average , blockTimestamp);
    }

    /// @notice Calculates the equivalent amount of the other token given an input amount
    /// @param token The token address to price
    /// @param amountIn The amount of the input token
    /// @return amountOut The equivalent amount of the output token
    function consult(address token, uint amountIn) external view returns (uint amountOut) {

        if (token == token0) {
            amountOut = (uint256(price0Average) * amountIn) / Q112;
        } else {
            if(token != token1) revert Invalid_Token();
            amountOut = (uint256(price1Average) * (amountIn)) / Q112;
        }
    }
}
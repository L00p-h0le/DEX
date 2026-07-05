// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IDexFactory} from '../Core/interfaces/IDexFactory.sol';
import {IDexPair} from '../Core/interfaces/IDexPair.sol';
import {UQ112x112} from './libraries/UQ112x112.sol';
import {OracleLibrary} from "./libraries/OracleLibrary.sol";


contract DexOracle {

    uint public constant PERIOD = 24 hours;
    uint224 constant Q112 = 2**112;

    IDexPair public immutable pair;
    address public immutable token0;
    address public immutable token1;

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint32 public blockTimestampLast;

    uint224 public price0Average;
    uint224 public price1Average;

    error No_Reserves();
    error Period_NotElapsed();
    error Pair_NotFound();
    error Invalid_Token();

    event OracleUpdated(uint224 price0Average , uint224 price1Average , uint32 timestamp);

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

    function update() external {

        (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) =
            OracleLibrary.currentCumulativePrices(address(pair));
            
        uint32 timeElapsed;
        unchecked{
           timeElapsed = blockTimestamp - blockTimestampLast; 
        }

        if(timeElapsed< PERIOD) revert Period_NotElapsed();

        unchecked{
            price0Average = (uint224((price0Cumulative - price0CumulativeLast) / timeElapsed));
            price1Average = (uint224((price1Cumulative - price1CumulativeLast) / timeElapsed));
        }
 
        price0CumulativeLast = price0Cumulative;
        price1CumulativeLast = price1Cumulative;
        blockTimestampLast = blockTimestamp;

        emit OracleUpdated(price0Average , price1Average , blockTimestamp);
    }

    function consult(address token, uint amountIn) external view returns (uint amountOut) {

        if (token == token0) {
            amountOut = (uint256(price0Average) * amountIn) / Q112;
        } else {
            if(token != token1) revert Invalid_Token();
            amountOut = (uint256(price1Average) * (amountIn)) / Q112;
        }
    }
}
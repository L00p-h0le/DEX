// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IDexPair} from '../../Core/interfaces/IDexPair.sol';
import {UQ112x112} from './UQ112x112.sol';

// library with helper methods for oracles that are concerned with computing average prices
library OracleLibrary {
    using UQ112x112 for uint224;

    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    function currentCumulativePrices(
        address pair
    ) internal view returns (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IDexPair(pair).price0CumulativeLast();
        price1Cumulative = IDexPair(pair).price1CumulativeLast();

        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IDexPair(pair).getReserve();
        if (blockTimestampLast != blockTimestamp) {

            unchecked{
                uint32 timeElapsed = blockTimestamp - blockTimestampLast;
                price0Cumulative += uint(UQ112x112.encode(reserve1).uqdiv(reserve0)) * timeElapsed;
                price1Cumulative += uint(UQ112x112.encode(reserve0).uqdiv(reserve1)) * timeElapsed;
            }
            
        }
    }
}
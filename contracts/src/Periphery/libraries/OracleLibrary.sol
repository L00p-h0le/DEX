// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IDexPair} from '../../Core/interfaces/IDexPair.sol';
import {UQ112x112} from './UQ112x112.sol';

/// @title Oracle Library
/// @notice Helper methods for oracles that compute average prices
library OracleLibrary {
    using UQ112x112 for uint224;

    /// @notice Returns the current block timestamp within the range of uint32
    /// @return The current block timestamp as a uint32
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    /// @notice Returns the current cumulative prices of a pair
    /// @param pair The address of the pair contract
    /// @return price0Cumulative The cumulative price of token0
    /// @return price1Cumulative The cumulative price of token1
    /// @return blockTimestamp The timestamp at which the cumulative prices were taken
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
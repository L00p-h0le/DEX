// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

/// @title UQ112x112 Library
/// @notice Provides functions for fractional numbers of the form UQ112x112
library UQ112x112{
    /// @notice Constant representing 2^112
    uint224 constant Q112 = 2**112;

    /// @notice Encodes a uint112 into a UQ112x112
    /// @param y The number to encode
    /// @return z The encoded UQ112x112 representation
    function encode(uint112 y) internal pure returns (uint224 z){
        z = uint224(y) * Q112;
    }

    /// @notice Divides a UQ112x112 by a uint112, returning a UQ112x112
    /// @param x The UQ112x112 numerator
    /// @param y The uint112 denominator
    /// @return z The resulting UQ112x112
    function uqdiv(uint224 x , uint112 y) internal pure returns (uint224 z){
        z = x / uint224(y);
    }
}
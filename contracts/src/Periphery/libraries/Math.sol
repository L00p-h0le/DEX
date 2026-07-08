// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {FixedPointMathLib} from "solady/utils/FixedPointMathLib.sol";

/// @title Math Library
/// @notice Provides standard math utilities
library Math{
    /// @notice Calculates the square root of a given number
    /// @param x The number to calculate the square root for
    /// @return The square root of x
    function sqrt(uint256 x) internal pure returns (uint256){
        return FixedPointMathLib.sqrt(x);
    }

    /// @notice Returns the smaller of two numbers
    /// @param x First number
    /// @param y Second number
    /// @return The minimum of x and y
    function min(uint256 x , uint256 y) internal pure returns(uint256){
        return x < y ? x : y;
    }
}
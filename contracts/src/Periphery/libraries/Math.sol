// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {FixedPointMathLib} from "solady/utils/FixedPointMathLib.sol";

library Math{
    function sqrt(uint256 x) internal pure returns (uint256){
        return FixedPointMathLib.sqrt(x);
    }

    function min(uint256 x , uint256 y) internal pure returns(uint256){
        return x < y ? x : y;
    }
}
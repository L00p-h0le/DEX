// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IDexPair} from "./interfaces/IDexPair.sol";

contract DexPair is IDexPair {
    address public token0;
    address public token1;

    function initialise(address _token0, address _token1) external {
        token0 = _token0;
        token1 = _token1;
    }
}

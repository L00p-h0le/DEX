// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "./Core/DexPair.sol";

contract InitCode is Script {
    function run() public {
        bytes32 initHash = keccak256(type(DexPair).creationCode);
        console.log("INIT_CODE_HASH:");
        console.logBytes32(initHash);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {DexPair} from "../../src/Core/DexPair.sol";
import {DexFactory} from "../../src/Core/DexFactory.sol";
import {ERC20Mock} from "../../src/Mocks/MockERC20.sol";
import {Handler} from "./Handler.sol";

contract DexPairInvariantTest is Test {
    DexFactory factory;
    DexPair pair;
    ERC20Mock token0;
    ERC20Mock token1;
    Handler handler;

    function setUp() public {
        factory = new DexFactory(address(this));
        token0 = new ERC20Mock("Token0", "TK0");
        token1 = new ERC20Mock("Token1", "TK1");

        address pairAddress = factory.createPair(address(token0), address(token1));
        pair = DexPair(pairAddress);

        handler = new Handler(pair, token0, token1);

        targetContract(address(handler));
        
        handler.addLiquidity(100 ether, 100 ether);
    }

    function invariant_KMustNotDecrease() public {
        (uint112 reserve0, uint112 reserve1,) = pair.getReserve();
        uint currentK = uint256(reserve0) * uint256(reserve1);
        
        assertGe(currentK, handler.expectedMinK());
    }
}

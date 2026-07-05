// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {DexFactory} from "../src/Core/DexFactory.sol";
import {DexPair} from "../src/Core/DexPair.sol";
import {DexOracle} from "../src/Periphery/DexOracle.sol";
import {ERC20Mock} from "../src/Mocks/MockERC20.sol";

contract DexOracleTest is Test {
    DexFactory factory;
    DexPair pair;
    DexOracle oracle;

    ERC20Mock tokenA;
    ERC20Mock tokenB;
    
    address token0;
    address token1;

    address alice = address(1);

    function setUp() public {
        factory = new DexFactory(address(this));
        
        tokenA = new ERC20Mock("Token A", "TKNA");
        tokenB = new ERC20Mock("Token B", "TKNB");
        
        address pairAddress = factory.createPair(address(tokenA), address(tokenB));
        pair = DexPair(pairAddress);
        
        token0 = pair.token0();
        token1 = pair.token1();
        
        // Mint some tokens to alice for liquidity
        ERC20Mock(token0).mint(alice, 1000 ether);
        ERC20Mock(token1).mint(alice, 1000 ether);
        
        vm.startPrank(alice);
        ERC20Mock(token0).transfer(address(pair), 100 ether);
        ERC20Mock(token1).transfer(address(pair), 100 ether);
        pair.mint(alice);
        vm.stopPrank();

        // Advance time a bit to avoid blockTimestamp = 0 issues if any
        vm.warp(block.timestamp + 10);
        
        oracle = new DexOracle(address(factory), token0, token1);
    }
    
    function testConstructorRevertsIfNoReserves() public {
        ERC20Mock tokenC = new ERC20Mock("Token C", "TKNC");
        ERC20Mock tokenD = new ERC20Mock("Token D", "TKND");
        
        factory.createPair(address(tokenC), address(tokenD));
        
        vm.expectRevert(DexOracle.No_Reserves.selector);
        new DexOracle(address(factory), address(tokenC), address(tokenD));
    }
    
    function testConstructorRevertsIfPairNotFound() public {
        ERC20Mock tokenC = new ERC20Mock("Token C", "TKNC");
        ERC20Mock tokenD = new ERC20Mock("Token D", "TKND");
        
        vm.expectRevert(DexOracle.Pair_NotFound.selector);
        new DexOracle(address(factory), address(tokenC), address(tokenD));
    }
    
    function testUpdateRevertsIfPeriodNotElapsed() public {
        vm.expectRevert(DexOracle.Period_NotElapsed.selector);
        oracle.update();
    }
    
    function testUpdate() public {
        vm.warp(block.timestamp + 24 hours);
        
        oracle.update();
        
        uint224 price0Average = oracle.price0Average();
        uint224 price1Average = oracle.price1Average();
        
        assertEq(price0Average, uint224(2**112));
        assertEq(price1Average, uint224(2**112));
    }
    
    function testConsult() public {
        // Advance time and update first to have a valid TWAP
        vm.warp(block.timestamp + 24 hours);
        oracle.update();
        
        uint amountIn = 1 ether;
        
        uint amountOut0 = oracle.consult(token0, amountIn);
        uint amountOut1 = oracle.consult(token1, amountIn);
        
        // Since ratio is 1:1, amountOut should be exactly equal to amountIn
        assertEq(amountOut0, 1 ether);
        assertEq(amountOut1, 1 ether);
    }
    
    function testConsultRevertsOnInvalidToken() public {
        vm.warp(block.timestamp + 24 hours);
        oracle.update();
        
        ERC20Mock invalidToken = new ERC20Mock("Invalid", "INV");
        
        vm.expectRevert(DexOracle.Invalid_Token.selector);
        oracle.consult(address(invalidToken), 1 ether);
    }
    
    function testUpdateWithPriceChange() public {
        // 1. Initial state: 100 ether of each token. Ratio 1:1.
        vm.warp(block.timestamp + 12 hours);
        
        // 2. Someone swaps, changing the reserves and price
        vm.startPrank(alice);
        ERC20Mock(token0).transfer(address(pair), 10 ether);
        pair.swap(0, 9 ether, alice, "");
        vm.stopPrank();
        
        // 3. Advance time to complete the 24 hour period
        vm.warp(block.timestamp + 12 hours);
        
        oracle.update();
        
        // The price should have adjusted
        uint224 price0Average = oracle.price0Average();
        uint224 price1Average = oracle.price1Average();
        
        uint224 initialPrice = uint224(2**112);
        
        assertTrue(price0Average != initialPrice);
        assertTrue(price1Average != initialPrice);
        
        assertTrue(price0Average < initialPrice); // Price 0 went down 
        assertTrue(price1Average > initialPrice); // Price 1 went up
    }

    function testConsultWithoutUpdateDoesNotRevert() public {
        // Call consult() without calling update() first (after constructor)
        // Should not revert and should return 0 based on uninitialized averages
        uint amountOut0 = oracle.consult(token0, 1 ether);
        uint amountOut1 = oracle.consult(token1, 1 ether);
        
        assertEq(amountOut0, 0);
        assertEq(amountOut1, 0);
    }
    
    function testConsecutiveUpdates() public {
        // First update
        vm.warp(block.timestamp + 24 hours);
        oracle.update();
        
        uint224 price0First = oracle.price0Average();
        
        // Change price
        vm.startPrank(alice);
        ERC20Mock(token0).transfer(address(pair), 10 ether);
        pair.swap(0, 9 ether, alice, "");
        vm.stopPrank();
        
        // Advance exactly PERIOD for second update
        vm.warp(block.timestamp + 24 hours);
        oracle.update();
        
        uint224 price0Second = oracle.price0Average();
        
        // The new average should be different because it accumulates from the first update
        assertTrue(price0Second != price0First);
    }
}

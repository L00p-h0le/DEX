// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {DexFactory} from "../src/Core/DexFactory.sol";
import {DexPair} from "../src/Core/DexPair.sol";
import {DexRouter} from "../src/Periphery/DexRouter.sol";
import {ERC20Mock} from "../src/Mocks/MockERC20.sol";
import {DexLibrary} from "../src/Periphery/libraries/DexLibrary.sol";

import {IDexPair} from "../src/Core/interfaces/IDexPair.sol";

contract DexRouterTest is Test {
    DexFactory factory;
    DexRouter router;
    ERC20Mock tokenA;
    ERC20Mock tokenB;
    ERC20Mock tokenC;

    address alice = address(1);
    address bob = address(2);

    function setUp() public {
        factory = new DexFactory(address(this));
        router = new DexRouter(address(factory));

        tokenA = new ERC20Mock("TokenA", "A");
        tokenB = new ERC20Mock("TokenB", "B");
        tokenC = new ERC20Mock("TokenC", "C");

        tokenA.mint(alice, 10000 ether);
        tokenB.mint(alice, 10000 ether);
        tokenC.mint(alice, 10000 ether);

        vm.startPrank(alice);
        tokenA.approve(address(router), type(uint256).max);
        tokenB.approve(address(router), type(uint256).max);
        tokenC.approve(address(router), type(uint256).max);
        vm.stopPrank();
    }

    // `addLiquidity` - creates pair if not exists, deposits correct amounts, mints LP tokens
    function test_addLiquidity_CreatesPairAndMintsTokens() public {
        vm.startPrank(alice);

        assertEq(factory.getPair(address(tokenA), address(tokenB)), address(0));

        (uint amountA, uint amountB, uint liquidity) = router.addLiquidity(
            address(tokenA),
            address(tokenB),
            100 ether,
            100 ether,
            0,
            0,
            alice,
            block.timestamp + 100
        );

        assertEq(amountA, 100 ether);
        assertEq(amountB, 100 ether);
        assertGt(liquidity, 0);

        address pair = factory.getPair(address(tokenA), address(tokenB));
        assertTrue(pair != address(0));

        assertEq(DexPair(pair).balanceOf(alice), liquidity);
        assertEq(tokenA.balanceOf(pair), 100 ether);
        assertEq(tokenB.balanceOf(pair), 100 ether);
        
        vm.stopPrank();
    }

    // `addLiquidity` - reverts when deadline expired
    function test_addLiquidity_RevertsWhenDeadlineExpired() public {
        vm.startPrank(alice);

        vm.expectRevert(DexRouter.Expired.selector);
        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            100 ether,
            100 ether,
            0,
            0,
            alice,
            block.timestamp - 1 // Expired
        );

        vm.stopPrank();
    }

    // `addLiquidity` - reverts when slippage exceeded
    function test_addLiquidity_RevertsWhenSlippageExceeded() public {
        vm.startPrank(alice);

        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            100 ether,
            100 ether,
            0,
            0,
            alice,
            block.timestamp + 100
        );

        vm.expectRevert(DexRouter.Insufficient_BAmount.selector);
        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            50 ether,
            100 ether,
            40 ether,
            60 ether, // Slippage threshold for B
            alice,
            block.timestamp + 100
        );

        vm.expectRevert(DexRouter.Insufficient_AAmount.selector);
        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            100 ether,
            50 ether,
            60 ether, // Slippage threshold for A
            40 ether,
            alice,
            block.timestamp + 100
        );

        vm.stopPrank();
    }

    // `removeLiquidity` - returns correct token amounts, burns LP tokens
    function test_removeLiquidity_ReturnsAmountsAndBurnsLPTokens() public {
        vm.startPrank(alice);

        (, , uint liquidity) = router.addLiquidity(
            address(tokenA),
            address(tokenB),
            100 ether,
            100 ether,
            0,
            0,
            alice,
            block.timestamp + 100
        );

        address pair = factory.getPair(address(tokenA), address(tokenB));
        
        DexPair(pair).approve(address(router), liquidity);

        uint balABefore = tokenA.balanceOf(alice);
        uint balBBefore = tokenB.balanceOf(alice);

        (uint amountA, uint amountB) = router.removeLiquidity(
            address(tokenA),
            address(tokenB),
            liquidity,
            0,
            0,
            alice,
            block.timestamp + 100
        );

        assertGt(amountA, 0);
        assertGt(amountB, 0);
        assertEq(tokenA.balanceOf(alice), balABefore + amountA);
        assertEq(tokenB.balanceOf(alice), balBBefore + amountB);
        assertEq(DexPair(pair).balanceOf(alice), 0);

        vm.stopPrank();
    }

    // `removeLiquidity` - reverts when slippage exceeded
    function test_removeLiquidity_RevertsWhenSlippageExceeded() public {
        vm.startPrank(alice);

        (, , uint liquidity) = router.addLiquidity(
            address(tokenA),
            address(tokenB),
            100 ether,
            100 ether,
            0,
            0,
            alice,
            block.timestamp + 100
        );

        address pair = factory.getPair(address(tokenA), address(tokenB));
        DexPair(pair).approve(address(router), liquidity);

        vm.expectRevert(DexRouter.Insufficient_AAmount.selector);
        router.removeLiquidity(
            address(tokenA),
            address(tokenB),
            liquidity,
            100 ether, // High minimum A
            0,
            alice,
            block.timestamp + 100
        );

        vm.expectRevert(DexRouter.Insufficient_BAmount.selector);
        router.removeLiquidity(
            address(tokenA),
            address(tokenB),
            liquidity,
            0,
            100 ether, // High minimum B
            alice,
            block.timestamp + 100
        );

        vm.stopPrank();
    }

    // `swapExactTokensForTokens` - correct output amount, single hop
    function test_swapExactTokensForTokens_SingleHop() public {
        vm.startPrank(alice);

        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            100 ether,
            100 ether,
            0,
            0,
            alice,
            block.timestamp + 100
        );

        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);

        uint amountIn = 10 ether;
        uint[] memory expectedAmounts = router.getAmountsOut(amountIn, path);

        uint balBBefore = tokenB.balanceOf(bob);

        uint[] memory amounts = router.swapExactTokensForTokens(
            amountIn,
            0,
            path,
            bob,
            block.timestamp + 100
        );

        assertEq(amounts[0], expectedAmounts[0]);
        assertEq(amounts[1], expectedAmounts[1]);

        assertEq(tokenB.balanceOf(bob), balBBefore + expectedAmounts[1]);

        vm.stopPrank();
    }

    // `swapExactTokensForTokens` - reverts when output below minimum
    function test_swapExactTokensForTokens_RevertsWhenOutputBelowMinimum() public {
        vm.startPrank(alice);

        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            100 ether,
            100 ether,
            0,
            0,
            alice,
            block.timestamp + 100
        );

        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);

        uint amountIn = 10 ether;
        
        vm.expectRevert(DexRouter.Insufficient_OutputAmount.selector);
        router.swapExactTokensForTokens(
            amountIn,
            10 ether, // Min output
            path,
            bob,
            block.timestamp + 100
        );

        vm.stopPrank();
    }

    // `swapTokensForExactTokens` - correct input amount, single hop
    function test_swapTokensForExactTokens_SingleHop() public {
        vm.startPrank(alice);

        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            100 ether,
            100 ether,
            0,
            0,
            alice,
            block.timestamp + 100
        );

        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);

        uint amountOut = 5 ether;
        uint[] memory expectedAmounts = router.getAmountsIn(amountOut, path);

        uint balABefore = tokenA.balanceOf(alice);
        uint balBBefore = tokenB.balanceOf(bob);

        uint[] memory amounts = router.swapTokensForExactTokens(
            amountOut,
            10 ether, // max in
            path,
            bob,
            block.timestamp + 100
        );

        assertEq(amounts[0], expectedAmounts[0]);
        assertEq(amounts[1], expectedAmounts[1]);

        assertEq(tokenA.balanceOf(alice), balABefore - expectedAmounts[0]);
        assertEq(tokenB.balanceOf(bob), balBBefore + amountOut);

        vm.stopPrank();
    }

    // `swapTokensForExactTokens` - reverts when input exceeds maximum
    function test_swapTokensForExactTokens_RevertsWhenInputExceedsMaximum() public {
        vm.startPrank(alice);

        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            100 ether,
            100 ether,
            0,
            0,
            alice,
            block.timestamp + 100
        );

        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);

        uint amountOut = 5 ether;
        
        vm.expectRevert(DexRouter.Excessive_InputAmount.selector);
        router.swapTokensForExactTokens(
            amountOut,
            1 ether, // max in
            path,
            bob,
            block.timestamp + 100
        );

        vm.stopPrank();
    }

    // Multi-hop swap through two pairs
    function test_swapExactTokensForTokens_MultiHop() public {
        vm.startPrank(alice);

        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            100 ether,
            100 ether,
            0,
            0,
            alice,
            block.timestamp + 100
        );

        router.addLiquidity(
            address(tokenB),
            address(tokenC),
            100 ether,
            100 ether,
            0,
            0,
            alice,
            block.timestamp + 100
        );

        address[] memory path = new address[](3);
        path[0] = address(tokenA);
        path[1] = address(tokenB);
        path[2] = address(tokenC);

        uint amountIn = 10 ether;
        uint[] memory expectedAmounts = router.getAmountsOut(amountIn, path);

        uint balCBefore = tokenC.balanceOf(bob);

        uint[] memory amounts = router.swapExactTokensForTokens(
            amountIn,
            0,
            path,
            bob,
            block.timestamp + 100
        );

        assertEq(amounts.length, 3);
        assertEq(amounts[0], expectedAmounts[0]);
        assertEq(amounts[1], expectedAmounts[1]);
        assertEq(amounts[2], expectedAmounts[2]);

        assertEq(tokenC.balanceOf(bob), balCBefore + expectedAmounts[2]);

        vm.stopPrank();
    }
}

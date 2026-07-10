// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";


import {DexPair} from "../src/Core/DexPair.sol";
import {DexFactory} from "../src/Core/DexFactory.sol";
import {IDexPair} from "../src/Core/interfaces/IDexPair.sol";
import {ERC20Mock} from "../src/Mocks/MockERC20.sol";

contract DexPairTest is Test {

    DexFactory factory;
    DexPair pair;

    ERC20Mock token0;
    ERC20Mock token1;

    address alice = address(1);
    address bob = address(2);

    function setUp() public {

        factory = new DexFactory(address(this));

        // Deploy mock tokens
        token0 = new ERC20Mock("Token0", "TK0");
        token1 = new ERC20Mock("Token1", "TK1");

        // Deploy pair
        address pairAddress = factory.createPair(address(token0), address(token1));
        pair = DexPair(pairAddress);

        // Mint tokens
        token0.mint(alice, 1000 ether);
        token1.mint(alice, 1000 ether);

        token0.mint(bob, 1000 ether);
        token1.mint(bob, 1000 ether);

        // Approvals
        vm.startPrank(alice);

        token0.approve(address(pair), type(uint256).max);
        token1.approve(address(pair), type(uint256).max);

        vm.stopPrank();

        vm.startPrank(bob);

        token0.approve(address(pair), type(uint256).max);
        token1.approve(address(pair), type(uint256).max);

        vm.stopPrank();
    }
    
    function _addInitialLiquidity() internal {
        token0.mint(address(this), 100 ether);
        token1.mint(address(this), 100 ether);

        token0.transfer(address(pair), 100 ether);
        token1.transfer(address(pair), 100 ether);

        pair.mint(address(this));
}

   
    function testMintInitialLiquidity() public {

        vm.startPrank(alice);

        token0.transfer(address(pair),100 ether);
        token1.transfer(address(pair),100 ether);

        uint liquidity = pair.mint(alice);

        vm.stopPrank();

        assertGt(liquidity,0);

        (uint112 reserve0,uint112 reserve1,) = pair.getReserve();

        assertEq(reserve0,100 ether);
        assertEq(reserve1,100 ether);

        assertEq(pair.balanceOf(alice),liquidity);
    }

    function testMintSecondLiquidityProvider() public {

        vm.startPrank(alice);

        token0.transfer(address(pair),100 ether);
        token1.transfer(address(pair),100 ether);

        pair.mint(alice);

        vm.stopPrank();


        vm.startPrank(bob);

        token0.transfer(address(pair),50 ether);
        token1.transfer(address(pair),50 ether);

        uint liquidity = pair.mint(bob);

        vm.stopPrank();

        assertGt(liquidity,0);

        (uint112 reserve0,uint112 reserve1,) = pair.getReserve();

        assertEq(reserve0,150 ether);
        assertEq(reserve1,150 ether);

        assertEq(pair.balanceOf(bob),liquidity);
    }

    function testMintRevertIfNoLiquidity() public {

        vm.expectRevert(
            DexPair.Insufficient_LiquidityMinted.selector
        );

        pair.mint(alice);
    }

    function testBurnLiquidity() public {

        vm.startPrank(alice);

        token0.transfer(address(pair),100 ether);
        token1.transfer(address(pair),100 ether);

        pair.mint(alice);

        uint liquidity = pair.balanceOf(alice);

        pair.transfer(address(pair),liquidity);

        pair.burn(alice);

        vm.stopPrank();

        (uint112 reserve0,uint112 reserve1,) = pair.getReserve();

        assertEq(
            reserve0,
            token0.balanceOf(address(pair))
        );

        assertEq(
            reserve1,
            token1.balanceOf(address(pair))
        );
    }

    function testBurnReturnsTokens() public {

        vm.startPrank(alice);

        token0.transfer(address(pair),100 ether);
        token1.transfer(address(pair),100 ether);

        pair.mint(alice);

        uint liquidity = pair.balanceOf(alice);

        pair.transfer(address(pair),liquidity);

        uint token0Before = token0.balanceOf(alice);
        uint token1Before = token1.balanceOf(alice);

        pair.burn(alice);

        vm.stopPrank();

        assertGt(
            token0.balanceOf(alice),
            token0Before
        );

        assertGt(
            token1.balanceOf(alice),
            token1Before
        );
    }

    function testBurnRevertWithoutLiquidity() public {

        vm.expectRevert(
            DexPair.Insufficient_LiquidityBurned.selector
        );

        pair.burn(alice);
    }

    //Swap Test

    function testSwapToken0ForToken1() public {
        _addInitialLiquidity();

        uint amountIn = 10 ether;
        uint amountOut = 9 ether; // valid amount

        token0.mint(address(this), amountIn);
        token0.transfer(address(pair), amountIn);

        uint token1Before = token1.balanceOf(address(this));

        pair.swap(0, amountOut, address(this), "");

        uint token1After = token1.balanceOf(address(this));

        assertEq(token1After - token1Before, amountOut);

        (uint112 reserve0, uint112 reserve1,) = pair.getReserve();

        assertEq(reserve0, 110 ether);
        assertEq(reserve1, 91 ether);
    }

    function testSwapToken1ForToken0() public {
        _addInitialLiquidity();

        uint amountIn = 10 ether;
        uint amountOut = 9 ether;

        token1.mint(address(this), amountIn);
        token1.transfer(address(pair), amountIn);

        uint token0Before = token0.balanceOf(address(this));

        pair.swap(amountOut, 0, address(this), "");

        uint token0After = token0.balanceOf(address(this));

        assertEq(token0After - token0Before, amountOut);

        (uint112 reserve0, uint112 reserve1,) = pair.getReserve();

        assertEq(reserve0, 91 ether);
        assertEq(reserve1, 110 ether);
    }

    function testSwapMaintainsKInvariant() public {
        _addInitialLiquidity();

        (uint112 reserve0Before, uint112 reserve1Before,) = pair.getReserve();

        uint oldK = uint(reserve0Before) * uint(reserve1Before);

        token0.mint(address(this), 10 ether);
        token0.transfer(address(pair), 10 ether);

        pair.swap(0, 9 ether, address(this), "");

        (uint112 reserve0After, uint112 reserve1After,) = pair.getReserve();

        uint newK = uint(reserve0After) * uint(reserve1After);

        assertGe(newK, oldK);
    }

    function testSwapRevertZeroOutputs() public {
        _addInitialLiquidity();

        vm.expectRevert(DexPair.Insufficient_OutputAmount.selector);

        pair.swap(0, 0, address(this), "");
    }

    function testSwapRevertOutputGreaterThanReserve() public {
        _addInitialLiquidity();

        vm.expectRevert(DexPair.Insufficient_Liquidity.selector);

        pair.swap(0, 101 ether, address(this), "");
    }

    function testSwapRevertNoInputProvided() public {
        _addInitialLiquidity();

        vm.expectRevert(DexPair.Insufficient_InputAmount.selector);

        pair.swap(0, 5 ether, address(this), "");
    }

    function testSwapRevertToToken0() public {
        _addInitialLiquidity();

        token0.mint(address(this), 10 ether);
        token0.transfer(address(pair), 10 ether);

        vm.expectRevert(DexPair.InvalidAddress.selector);

        pair.swap(0, 5 ether, address(token0), "");
    }

    function testSwapRevertToToken1() public {
        _addInitialLiquidity();

        token0.mint(address(this), 10 ether);
        token0.transfer(address(pair), 10 ether);

        vm.expectRevert(DexPair.InvalidAddress.selector);

        pair.swap(0, 5 ether, address(token1), "");
    }

    function testFuzz_MintInitialLiquidity(uint96 amount0, uint96 amount1) public {
        vm.assume(amount0 > pair.MINIMUM_LIQUIDITY());
        vm.assume(amount1 > pair.MINIMUM_LIQUIDITY());
        vm.assume(amount0 <= 1000 ether);
        vm.assume(amount1 <= 1000 ether);

        vm.startPrank(alice);

        token0.transfer(address(pair), amount0);
        token1.transfer(address(pair), amount1);

        uint liquidity = pair.mint(alice);

        vm.stopPrank();

        assertGt(liquidity, 0);

        (uint112 reserve0, uint112 reserve1,) = pair.getReserve();

        assertEq(reserve0, amount0);
        assertEq(reserve1, amount1);
        assertEq(pair.balanceOf(alice), liquidity);
    }

    function testFuzz_SwapMaintainsKInvariant(uint96 amountIn) public {
        vm.assume(amountIn > 0);
        vm.assume(amountIn < 1000 ether);
        _addInitialLiquidity();

        (uint112 reserve0Before, uint112 reserve1Before,) = pair.getReserve();
        uint oldK = uint(reserve0Before) * uint(reserve1Before);

        token0.mint(address(this), amountIn);
        token0.transfer(address(pair), amountIn);

        uint amountInWithFee = uint(amountIn) * 997;
        uint numerator = amountInWithFee * uint(reserve1Before);
        uint denominator = (uint(reserve0Before) * 1000) + amountInWithFee;
        uint maxAmountOut = numerator / denominator;
        
        vm.assume(maxAmountOut > 0);

        pair.swap(0, maxAmountOut, address(this), "");

        (uint112 reserve0After, uint112 reserve1After,) = pair.getReserve();
        uint newK = uint(reserve0After) * uint(reserve1After);

        assertGe(newK, oldK);
    }

}
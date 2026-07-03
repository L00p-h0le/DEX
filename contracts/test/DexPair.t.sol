// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";

import {DexPair} from "../src/Core/DexPair.sol";
import {ERC20Mock} from "../src/Mocks/MockERC20.sol";

contract DexPairTest is Test {

    DexPair pair;

    ERC20Mock token0;
    ERC20Mock token1;

    address alice = address(1);
    address bob = address(2);

    function setUp() public {

        // Deploy mock tokens
        token0 = new ERC20Mock("Token0", "TK0");
        token1 = new ERC20Mock("Token1", "TK1");

        // Deploy pair
        pair = new DexPair();

        // Initialize pair
        pair.initialise(address(token0), address(token1));

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

}
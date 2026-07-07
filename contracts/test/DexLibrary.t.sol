// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import {DexLibraryWrapper} from "../src/Mocks/MockDexLibrary.sol";
import {DexLibrary} from "../src/Periphery/libraries/DexLibrary.sol";

import {DexFactory} from "../src/Core/DexFactory.sol";
import {DexPair} from "../src/Core/DexPair.sol";
import {ERC20Mock} from "../src/Mocks/MockERC20.sol";

contract DexLibraryTest is Test {
    DexLibraryWrapper wrapper;

    DexFactory factory;
    ERC20Mock tokenA;
    ERC20Mock tokenB;
    ERC20Mock tokenC;

    DexPair pairAB;
    DexPair pairBC;

    function setUp() public {
        wrapper = new DexLibraryWrapper();

        factory = new DexFactory(address(this));

        tokenA = new ERC20Mock("A", "A");
        tokenB = new ERC20Mock("B", "B");
        tokenC = new ERC20Mock("C", "C");

        pairAB = DexPair(factory.createPair(address(tokenA), address(tokenB)));
        pairBC = DexPair(factory.createPair(address(tokenB), address(tokenC)));

        tokenA.mint(address(pairAB), 1000 ether);
        tokenB.mint(address(pairAB), 2000 ether);
        pairAB.mint(address(this));

        tokenB.mint(address(pairBC), 3000 ether);
        tokenC.mint(address(pairBC), 6000 ether);
        pairBC.mint(address(this));
    }

    ////////////////////////////////////////////////////////////
    // sortTokens
    ////////////////////////////////////////////////////////////

    function test_sortTokens_ReturnsSortedOrder() public view{
        (address token0, address token1) =
            wrapper.sortTokens(address(tokenB), address(tokenA));

        assertLt(uint160(token0), uint160(token1));
    }

    function test_sortTokens_RevertIdenticalAddresses() public {
        vm.expectRevert(DexLibrary.Identical_Address.selector);

        wrapper.sortTokens(address(tokenA), address(tokenA));
    }

    function test_sortTokens_RevertZeroAddress() public {
        vm.expectRevert(DexLibrary.Zero_Address.selector);

        wrapper.sortTokens(address(0), address(tokenA));
    }

    ////////////////////////////////////////////////////////////
    // quote
    ////////////////////////////////////////////////////////////

    function test_quote_ReturnsCorrectAmount() public view {
        uint amount = wrapper.quote(10 ether, 100 ether, 200 ether);

        assertEq(amount, 20 ether);
    }

    function test_quote_RevertZeroAmount() public {
        vm.expectRevert(DexLibrary.Insufficient_Amount.selector);

        wrapper.quote(0, 100, 100);
    }

    function test_quote_RevertZeroReserves() public {
        vm.expectRevert(DexLibrary.Insufficient_Liquidity.selector);

        wrapper.quote(10, 0, 100);
    }

    ////////////////////////////////////////////////////////////
    // getAmountOut
    ////////////////////////////////////////////////////////////

    function test_getAmountOut_ReturnsCorrectOutput() public view {
        uint amountOut =
            wrapper.getAmountOut(1000, 10000, 10000);

        // Expected:
        // amountInWithFee = 997000
        // numerator = 9,970,000,000
        // denominator = 10,997,000
        assertEq(amountOut, 906);
    }

    function test_getAmountOut_RevertZeroInput() public {
        vm.expectRevert(DexLibrary.Insufficient_InputAmount.selector);

        wrapper.getAmountOut(0, 1000, 1000);
    }

    function test_getAmountOut_RevertZeroReserves() public {
        vm.expectRevert(DexLibrary.Insufficient_Liquidity.selector);

        wrapper.getAmountOut(100, 0, 1000);
    }

    ////////////////////////////////////////////////////////////
    // getAmountIn
    ////////////////////////////////////////////////////////////

    function test_getAmountIn_ReturnsCorrectInput() public view {
        uint amountIn =
            wrapper.getAmountIn(906, 10000, 10000);

        assertEq(amountIn, 1000);
    }

    function test_getAmountIn_RevertZeroOutput() public {
        vm.expectRevert(DexLibrary.Insufficient_OutputAmount.selector);

        wrapper.getAmountIn(0, 1000, 1000);
    }

    function test_getAmountIn_RevertZeroReserve() public {
        vm.expectRevert(DexLibrary.Insufficient_Liquidity.selector);

        wrapper.getAmountIn(100, 0, 1000);
    }

    ////////////////////////////////////////////////////////////
    // pairFor
    ////////////////////////////////////////////////////////////

    function test_pairFor_ReturnsCorrectPairAddress() public view {
        address predicted =
            wrapper.pairFor(
                address(factory),
                address(tokenA),
                address(tokenB)
            );

        assertEq(predicted, address(pairAB));
    }

    ////////////////////////////////////////////////////////////
    // getAmountsOut
    ////////////////////////////////////////////////////////////

    function test_getAmountsOut_TwoHopPath() public view {
        address[] memory path = new address[](3);

        path[0] = address(tokenA);
        path[1] = address(tokenB);
        path[2] = address(tokenC);

        uint[] memory amounts =
            wrapper.getAmountsOut(
                address(factory),
                100 ether,
                path
            );

        assertEq(amounts.length, 3);

        assertEq(amounts[0], 100 ether);

        assertGt(amounts[1], 0);
        assertGt(amounts[2], 0);
    }

    function test_getAmountsOut_RevertInvalidPath() public {
        address[] memory path = new address[](1);

        path[0] = address(tokenA);

        vm.expectRevert(DexLibrary.Invalid_Path.selector);

        wrapper.getAmountsOut(
            address(factory),
            1 ether,
            path
        );
    }

    ////////////////////////////////////////////////////////////
    // getAmountsIn
    ////////////////////////////////////////////////////////////

    function test_getAmountsIn_TwoHopPath() public view {
        address[] memory path = new address[](3);

        path[0] = address(tokenA);
        path[1] = address(tokenB);
        path[2] = address(tokenC);

        uint[] memory amounts =
            wrapper.getAmountsIn(
                address(factory),
                10 ether,
                path
            );

        assertEq(amounts.length, 3);

        assertEq(amounts[2], 10 ether);

        assertGt(amounts[0], 0);
        assertGt(amounts[1], 0);
    }

    function test_getAmountsIn_RevertInvalidPath() public {
        address[] memory path = new address[](1);

        path[0] = address(tokenA);

        vm.expectRevert(DexLibrary.Invalid_Path.selector);

        wrapper.getAmountsIn(
            address(factory),
            1 ether,
            path
        );
    }
}
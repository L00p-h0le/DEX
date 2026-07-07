// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

import {DexFactory} from "../src/Core/DexFactory.sol";
import {DexPair} from "../src/Core/DexPair.sol";
import {ERC20Mock} from "../src/Mocks/MockERC20.sol";
import {IDexFactory} from "../src/Core/interfaces/IDexFactory.sol";

contract DexFactoryTest is Test {

    DexFactory factory;

    ERC20Mock tokenA;
    ERC20Mock tokenB;
    ERC20Mock tokenC;

    address feeSetter = address(100);
    address alice = address(1);

    function setUp() public {
        vm.prank(feeSetter);
        factory = new DexFactory(feeSetter);

        tokenA = new ERC20Mock("TokenA", "A");
        tokenB = new ERC20Mock("TokenB", "B");
        tokenC = new ERC20Mock("TokenC", "C");
    }


    function testConstructorSetsFeeToSetter() public view {
        assertEq(factory.feeToSetter(), feeSetter);
    }

    function testCreatePair() public {

        address pair = factory.createPair(
            address(tokenA),
            address(tokenB)
        );

        assertTrue(pair != address(0));

        assertEq(
            factory.getPair(address(tokenA), address(tokenB)),
            pair
        );

        assertEq(
            factory.getPair(address(tokenB), address(tokenA)),
            pair
        );

        assertEq(factory.allPairsLength(), 1);

        (address token0, address token1) = address(tokenA) < address(tokenB) 
            ? (address(tokenA), address(tokenB)) 
            : (address(tokenB), address(tokenA));

        bytes32 salt = keccak256(abi.encodePacked(token0, token1));

        address predicted = vm.computeCreate2Address(
            salt,
            keccak256(type(DexPair).creationCode),
            address(factory)
        );
        assertEq(pair, predicted);
    }

    function testPairInitializedCorrectly() public {

        address pair = factory.createPair(
            address(tokenA),
            address(tokenB)
        );

        (address token0, address token1) = address(tokenA) < address(tokenB)
            ? (address(tokenA), address(tokenB))
            : (address(tokenB), address(tokenA));

        assertEq(DexPair(pair).token0(), token0);
        assertEq(DexPair(pair).token1(), token1);
    }

    function testEmitsPairCreatedEvent() public {

        (address token0, address token1) =
            address(tokenA) < address(tokenB)
            ? (address(tokenA), address(tokenB))
            : (address(tokenB), address(tokenA));

        vm.expectEmit(true, true, false, false);

        emit IDexFactory.PairCreated(
            token0,
            token1,
            address(0), //placeholder
            1
        );

        factory.createPair(address(tokenA), address(tokenB));
    }

    function testRevertIfIdenticalAddresses() public {

        vm.expectRevert(DexFactory.IdenticalAddresses.selector);

        factory.createPair(
            address(tokenA),
            address(tokenA)
        );
    }

    function testRevertIfZeroAddress() public {

        vm.expectRevert(DexFactory.ZeroAddress.selector);

        factory.createPair(
            address(0),
            address(tokenA)
        );
    }

    function testRevertIfPairAlreadyExists() public {

        factory.createPair(
            address(tokenA),
            address(tokenB)
        );

        vm.expectRevert(DexFactory.TokenPairExists.selector);

        factory.createPair(
            address(tokenA),
            address(tokenB)
        );
    }

    function testRevertIfReversePairExists() public {

        factory.createPair(
            address(tokenA),
            address(tokenB)
        );

        vm.expectRevert(DexFactory.TokenPairExists.selector);

        factory.createPair(
            address(tokenB),
            address(tokenA)
        );
    }

    function testSetFeeTo() public {

        address newFeeTo = address(999);
        vm.prank(feeSetter);
        factory.setFeeTo(newFeeTo);
        assertEq(factory.feeTo(), newFeeTo);
    }

    function testOnlyFeeSetterCanSetFeeTo() public {

        vm.prank(alice);
        vm.expectRevert(DexFactory.Forbidden.selector);
        factory.setFeeTo(address(123));
    }

    function testMultiplePairsCreated() public {

        factory.createPair(address(tokenA), address(tokenB));
        factory.createPair(address(tokenA), address(tokenC));

        assertEq(factory.allPairsLength(), 2);
    }
}
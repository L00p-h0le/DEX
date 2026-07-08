// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {DexPair} from "../../src/Core/DexPair.sol";
import {ERC20Mock} from "../../src/Mocks/MockERC20.sol";

contract Handler is Test {
    DexPair pair;
    ERC20Mock token0;
    ERC20Mock token1;

    uint256 public expectedMinK;

    constructor(DexPair _pair, ERC20Mock _token0, ERC20Mock _token1) {
        pair = _pair;
        token0 = _token0;
        token1 = _token1;
    }

    function addLiquidity(uint96 amount0, uint96 amount1) public {
        amount0 = uint96(bound(amount0, 1000, 1000 ether));
        amount1 = uint96(bound(amount1, 1000, 1000 ether));

        token0.mint(address(this), amount0);
        token1.mint(address(this), amount1);

        token0.transfer(address(pair), amount0);
        token1.transfer(address(pair), amount1);

        try pair.mint(address(this)) {
            (uint112 reserve0, uint112 reserve1,) = pair.getReserve();
            expectedMinK = uint256(reserve0) * uint256(reserve1);
        } catch {}
    }

    function removeLiquidity(uint256 amount) public {
        uint256 balance = pair.balanceOf(address(this));
        if (balance == 0) return;
        
        amount = bound(amount, 1, balance);

        pair.transfer(address(pair), amount);
        try pair.burn(address(this)) {
            (uint112 reserve0, uint112 reserve1,) = pair.getReserve();
            expectedMinK = uint256(reserve0) * uint256(reserve1);
        } catch {}
    }

    function swapToken0ForToken1(uint96 amountIn) public {
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserve();
        if (reserve0 == 0 || reserve1 == 0) return;

        amountIn = uint96(bound(amountIn, 1, reserve0 / 2)); 

        token0.mint(address(this), amountIn);
        token0.transfer(address(pair), amountIn);

        uint amountInWithFee = uint256(amountIn) * 997;
        uint numerator = amountInWithFee * uint256(reserve1);
        uint denominator = (uint256(reserve0) * 1000) + amountInWithFee;
        uint amountOut = numerator / denominator;

        if (amountOut == 0) return;

        try pair.swap(0, amountOut, address(this), "") {} catch {}
    }

    function swapToken1ForToken0(uint96 amountIn) public {
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserve();
        if (reserve0 == 0 || reserve1 == 0) return;

        amountIn = uint96(bound(amountIn, 1, reserve1 / 2));

        token1.mint(address(this), amountIn);
        token1.transfer(address(pair), amountIn);

        uint amountInWithFee = uint256(amountIn) * 997;
        uint numerator = amountInWithFee * uint256(reserve0);
        uint denominator = (uint256(reserve1) * 1000) + amountInWithFee;
        uint amountOut = numerator / denominator;

        if (amountOut == 0) return;

        try pair.swap(amountOut, 0, address(this), "") {} catch {}
    }
}

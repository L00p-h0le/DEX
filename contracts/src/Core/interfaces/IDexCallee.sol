// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

/// @title IDexCallee Interface
/// @notice Interface for contracts that want to be called by the DEX pair contract during a flash swap
interface IDexCallee {
    /// @notice Called to execute custom logic after a swap but before the tokens are paid back
    /// @param sender The address that initiated the swap
    /// @param amount0Out The amount of token0 sent out
    /// @param amount1Out The amount of token1 sent out
    /// @param data Any data passed through by the caller
    function dexV2Call(
        address sender,
        uint amount0Out,
        uint amount1Out,
        bytes calldata data
    ) external;
}
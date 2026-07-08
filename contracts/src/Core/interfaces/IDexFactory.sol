// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

/// @title IDexFactory Interface
/// @notice Interface for the DEX factory contract
interface IDexFactory {

    /// @notice Emitted when a pair is created
    /// @param token0 Address of the first token
    /// @param token1 Address of the second token
    /// @param pair Address of the created pair
    /// @param totalPairs Total number of pairs created so far
    event PairCreated(address indexed token0, address indexed token1, address pair, uint totalPairs);

    /// @notice Returns the address that receives the protocol fee
    /// @return The feeTo address
    function feeTo() external view returns (address);

    /// @notice Returns the address that can set the feeTo address
    /// @return The feeToSetter address
    function feeToSetter() external view returns (address);

    /// @notice Returns the pair address for a given token pair
    /// @param tokenA The first token
    /// @param tokenB The second token
    /// @return pair The pair address
    function getPair(address tokenA, address tokenB) external view returns (address pair);

    /// @notice Returns the pair address at the given index
    /// @param index The index of the pair
    /// @return pair The pair address
    function allPairs(uint index) external view returns (address pair);

    /// @notice Returns the total number of pairs created
    /// @return The total number of pairs
    function allPairsLength() external view returns (uint);

    /// @notice Creates a new pair for the given tokens
    /// @param tokenA The first token
    /// @param tokenB The second token
    /// @return pair The address of the created pair
    function createPair(address tokenA, address tokenB) external returns (address pair);

    /// @notice Sets the feeTo address
    /// @param feeTo_ The new feeTo address
    function setFeeTo(address feeTo_) external;
}
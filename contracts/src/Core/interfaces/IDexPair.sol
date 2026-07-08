// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

/// @title IDexPair Interface
/// @notice Interface for the DEX pair contract
interface IDexPair {

    /// @notice Emitted when liquidity is minted
    /// @param sender The address that minted the liquidity
    /// @param amount0 The amount of token0 deposited
    /// @param amount1 The amount of token1 deposited
    event Mint(address indexed sender, uint amount0, uint amount1);

    /// @notice Emitted when liquidity is burned
    /// @param sender The address that burned the liquidity
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    /// @param to The address receiving the withdrawn tokens
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);

    /// @notice Emitted when a swap occurs
    /// @param sender The address that initiated the swap
    /// @param amount0In The amount of token0 swapped in
    /// @param amount1In The amount of token1 swapped in
    /// @param amount0Out The amount of token0 swapped out
    /// @param amount1Out The amount of token1 swapped out
    /// @param to The address receiving the swapped tokens
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );

    /// @notice Emitted when the reserves are synced
    /// @param reserve0 The synced reserve of token0
    /// @param reserve1 The synced reserve of token1
    event Sync(uint112 reserve0, uint112 reserve1);

    /// @notice Returns the minimum liquidity minted to address(0)
    /// @return The minimum liquidity amount
    function MINIMUM_LIQUIDITY() external pure returns (uint);

    /// @notice Returns the factory address
    /// @return The factory address
    function factory() external view returns (address);

    /// @notice Returns the token0 address
    /// @return The token0 address
    function token0() external view returns (address);

    /// @notice Returns the token1 address
    /// @return The token1 address
    function token1() external view returns (address);

    /// @notice Returns the current reserves and the timestamp of the last interaction
    /// @return reserve0 The reserve of token0
    /// @return reserve1 The reserve of token1
    /// @return blockTimestampLast The timestamp of the last interaction
    function getReserve() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    /// @notice Returns the cumulative price of token0
    /// @return The cumulative price of token0
    function price0CumulativeLast() external view returns (uint);

    /// @notice Returns the cumulative price of token1
    /// @return The cumulative price of token1
    function price1CumulativeLast() external view returns (uint);

    /// @notice Returns the K invariant of the pair from the last interaction
    /// @return The K invariant
    function kLast() external view returns (uint);

    /// @notice Mints liquidity tokens to the given address
    /// @param to The address to receive the liquidity tokens
    /// @return liquidity The amount of liquidity tokens minted
    function mint(address to) external returns (uint liquidity);

    /// @notice Burns liquidity tokens and sends underlying tokens to the given address
    /// @param to The address to receive the underlying tokens
    /// @return amount0 The amount of token0 returned
    /// @return amount1 The amount of token1 returned
    function burn(address to) external returns (uint amount0, uint amount1);

    /// @notice Swaps tokens
    /// @param amount0Out The amount of token0 to receive
    /// @param amount1Out The amount of token1 to receive
    /// @param to The address to receive the swapped tokens
    /// @param data Any data passed through by the caller for flash swaps
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

    /// @notice Initializes the pair
    /// @param token0 The address of token0
    /// @param token1 The address of token1
    function initialise(address token0, address token1) external;
}
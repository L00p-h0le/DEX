// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {DexPair} from "./DexPair.sol";
import {IDexFactory} from "./interfaces/IDexFactory.sol";
import {IDexPair} from "./interfaces/IDexPair.sol";

/// @title DexFactory
/// @notice Core factory contract for deploying DEX pairs
contract DexFactory is IDexFactory {
    /// @notice Address receiving the protocol fee
    address public feeTo;
    /// @notice Address authorized to set feeTo
    address public immutable feeToSetter;

    /// @notice Mapping from token pair to their pair address
    mapping(address => mapping(address => address)) public getPair;
    /// @notice Array of all created pair addresses
    address[] public allPairs;

    error IdenticalAddresses();
    error ZeroAddress();
    error TokenPairExists();
    error Forbidden();

    /// @notice Constructor for the factory
    /// @param _feeToSetter The initial feeToSetter address
    constructor(address _feeToSetter) {
        feeToSetter = _feeToSetter;
    }

    /// @notice Returns the total number of pairs created
    /// @return The length of the allPairs array
    function allPairsLength() external view returns (uint){
        return allPairs.length;
    }

    /// @notice Creates a new pair for the given tokens
    /// @param tokenA The first token
    /// @param tokenB The second token
    /// @return pair The address of the created pair
    function createPair(address tokenA , address tokenB) external returns (address pair){
        if(tokenA == tokenB) revert IdenticalAddresses();

        (address token0 , address token1) = tokenA < tokenB ? (tokenA , tokenB) : (tokenB , tokenA);

        if(token0 == address(0)) revert ZeroAddress();
        if(getPair[token0][token1] != address(0)) revert TokenPairExists();

        bytes32 salt = keccak256(abi.encodePacked(token0 , token1));

        pair = address(new DexPair{salt: salt}());

        IDexPair(pair).initialise(token0 , token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);

    }

    /// @notice Sets the feeTo address
    /// @param _feeTo The new feeTo address
    function setFeeTo(address _feeTo) external{
        if(msg.sender != feeToSetter) revert Forbidden(); 
        feeTo = _feeTo;
    }
}

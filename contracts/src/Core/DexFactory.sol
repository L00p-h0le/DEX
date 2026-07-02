// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {DexPair} from "./DexPair.sol";
import {IDexFactory} from "./interfaces/IDexFactory.sol";
import {IDexPair} from "./interfaces/IDexPair.sol";

contract DexFactory is IDexFactory {
    address public feeTo;
    address public immutable feeToSetter;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    error IdenticalAddresses();
    error ZeroAddress();
    error TokenPairExists();
    error Forbidden();


    constructor(address _feeToSetter) {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external view returns (uint){
        return allPairs.length;
    }

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

    function setFeeTo(address _feeTo) external{
        if(msg.sender != feeToSetter) revert Forbidden(); 
        feeTo = _feeTo;
    }
}


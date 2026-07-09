// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {ERC20Mock} from "../src/Mocks/MockERC20.sol";

contract DeployTokens is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        ERC20Mock tokenA = new ERC20Mock("USD Coin", "USDC");
        ERC20Mock tokenB = new ERC20Mock("Wrapped Bitcoin", "WBTC");

        // Mint some tokens to deployer for testing
        tokenA.mint(deployer, 1000000 ether);
        tokenB.mint(deployer, 1000000 ether);

        console.log("USDC deployed at:", address(tokenA));
        console.log("WBTC deployed at:", address(tokenB));

        vm.stopBroadcast();
    }
}
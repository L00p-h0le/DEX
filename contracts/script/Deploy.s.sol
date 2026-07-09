// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {DexFactory} from "../src/Core/DexFactory.sol";
import {DexRouter} from "../src/Periphery/DexRouter.sol";

contract DeployDex is Script {
    function run() external {
        // Load deployer private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying DexProtocol...");
        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy Factory
        // deployer becomes feeToSetter — controls protocol fee switch
        DexFactory factory = new DexFactory(deployer);
        console.log("DexFactory deployed at:", address(factory));

        // Deploy Router
        DexRouter router = new DexRouter(address(factory));
        console.log("DexRouter deployed at:", address(router));

        vm.stopBroadcast();

        console.log("---");
        console.log("Deployment complete.");
        console.log("Factory:", address(factory));
        console.log("Router:", address(router));
        console.log("feeToSetter:", deployer);
    }
}
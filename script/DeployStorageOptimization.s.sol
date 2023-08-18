//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {StorageOptimization} from "../src/StorageOptimization/StorageOptimization.sol";

contract DeployStorageOptimization is Script {
    function run() public returns (StorageOptimization) {
        vm.startBroadcast();
        StorageOptimization storageOptimization = new StorageOptimization();
        vm.stopBroadcast();
        return storageOptimization;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {DecentralizedStableCoin} from "src/DecentralizedStableCoin.sol";

contract DeployDSCEngine is Script {
    function run() external returns (DecentralizedStableCoin, DSCEngine) {
        address[] memory tokenAddresses = new address[](2);

        vm.startBroadcast();

        DecentralizedStableCoin dsc = new DecentralizedStableCoin();
        DSCEngine dscEngine = new DSCEngine(tokenAddresses, priceFeedAddresses, dsc.address);

        vm.stopBoradcast();
    }
}

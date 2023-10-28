//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {DSCEngine} from "src/DSCEngine.sol";


contract DeployDSCEngine is Script{
    function run() public returns(DSCEngine){

        address[] memory tokenAddresses = new address[](2);

        vm.startBroadcast();

        DSCEngine dscEngine = new DSCEngine(tokenAddresses, priceFeedAddresses, dscAddress);
        
    }

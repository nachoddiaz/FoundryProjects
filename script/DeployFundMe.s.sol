// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFundMe is Script {
    function run() public returns (FundMe, HelperConfig) {
        //Before startBroadcast -> Simulated Tx! -> Costs no gas
        HelperConfig helperConfig = new HelperConfig();
        address PriceFeed = helperConfig.ActiveNetworkConfig();

        //After startBroadcast -> Real Tx! -> Costs gas
        vm.startBroadcast();

        //This is the price feed of the ETH/USD pair in Sepolia
        FundMe fundMe = new FundMe(PriceFeed);

        //fundMe.fund();
        //FundMe(payable(mostRecentlyDeployed)).fund{value: 1 ether}();
        //console.log(fundMe.getBalance());

        vm.stopBroadcast();
        return (fundMe, helperConfig);
    }
}

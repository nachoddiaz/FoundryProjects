//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {FundMe} from "../src/FundMe.sol";

contract FundFundMe is Script {
    uint256 constant SENT_VALUE = 0.1 ether;

    function fundFundMe(address mostRecentlyContactDeployed) public {
        vm.startBroadcast();
        FundMe(payable(mostRecentlyContactDeployed)).fund{value: SENT_VALUE};
        vm.stopBroadcast();
        console.log("FundMe contract funded with %s", SENT_VALUE);
    }

    function run() external {
        address mostRecentlyContactDeployed = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);
        fundFundMe(mostRecentlyContactDeployed);
    }
}

contract WithdrawFundMe is Script {
    function withdrawFundMe(address mostRecentlyContactDeployed) public {
        vm.startBroadcast();
        console.log("Funds remain in FundMe contract %s", address(this).balance);
        FundMe(mostRecentlyContactDeployed).withdraw();
        vm.stopBroadcast();
        console.log("Funds remain in FundMe contract %s", address(this).balance);
        console.log("Funds remain in FundMe contract %s", address(mostRecentlyContactDeployed).balance);
    }

    function run() external {
        address mostRecentlyContactDeployed = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);
        withdrawFundMe(mostRecentlyContactDeployed);
    }
}

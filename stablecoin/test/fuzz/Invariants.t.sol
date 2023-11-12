//SPDX-License-Identifier: MIT

//WE are going to use hadler to set up the enviroment

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {DeployDSC} from "script/DeployDSC.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Handler} from "./Handler.t.sol";

contract Invariants is StdInvariant, Test {
    DSCEngine public dscEngine;
    DecentralizedStableCoin public dsc;
    HelperConfig public config;
    Handler handler;

    address weth;
    address wbtc;

    function setUp() external {
        DeployDSC deployer = new DeployDSC();
        (dsc, dscEngine, config) = deployer.run();
        (,, weth, wbtc,) = config.ActiveNetworkConfig();
        handler = new Handler(dscEngine, dsc);
        //So the target of all the invariant tests will be the hanlder where we specify the functions to follow
        targetContract(address(handler));
    }

    function invariant_protocolMustHaveMoreValueThanTotalSuplly() public view {
        //Get the value of all the collateral of the protocol and compare to the debt (minted)
        uint256 totalSupply = dsc.totalSupply();
        uint256 totalWethDeposited = IERC20(weth).balanceOf(address(dscEngine));
        uint256 totalWbtcDeposited = IERC20(wbtc).balanceOf(address(dscEngine));

        console.log("totalWethDeposited: %s", totalWethDeposited);
        console.log("totalWbtcDeposited: %s", totalWbtcDeposited);
        console.log("totalSupply: %s", totalSupply);
        console.log("minted function called %s times", handler.timesMintFunctionIsCalled());

        uint256 totalColateralValueInUsd =
            dscEngine.getUsdValue(totalWethDeposited, weth) + dscEngine.getUsdValue(totalWbtcDeposited, wbtc);

        assert(totalColateralValueInUsd >= totalSupply);
    }
}

//Manages the order wie call functions

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {DeployDSC} from "script/DeployDSC.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";

contract Handler is Test {

    ERC20Mock weth;
    ERC20Mock wbtc;    
    //Only call redeem function if there is collateral to redeem

    //1.Set up the contracts that the handler are going to handle
    DSCEngine dscEngine;
    DecentralizedStableCoin dsc;

    constructor(DSCEngine _dscEngine, DecentralizedStableCoin _dsc) {
        dscEngine = _dscEngine;
        dsc = _dsc;

        address [] memory collateralTokens = dscEngine.getCollateralTokens();
        weth = ERC20Mock(collateralTokens[0]);
        wbtc = ERC20Mock(collateralTokens[1]);
    }

    //Write the functinos neede to alocate collateral
    function depositCollateral(uint256 collateralSeed, uint256 amountCollateral) public {
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        dscEngine.depositCollateral(address(collateral), amountCollateral);
    }

    //Helper Functions

    function _getCollateralFromSeed(uint256 collateralSeed) private view returns(ERC20Mock){

        if(collateralSeed % 2 == 0){
            return weth;
        }   return wbtc;
    }
}

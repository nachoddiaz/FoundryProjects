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

    //1.Set up the contracts that the handler are going to handle
    DSCEngine dscEngine;
    DecentralizedStableCoin dsc;

    ERC20Mock weth;
    ERC20Mock wbtc;    
    

    //////////////////////////////
    //      Ghost Variables     //
    //////////////////////////////

    uint256 public timesMintFunctionIsCalled;

    uint256 MAX_DEPOSIT_SIZE = type(uint96).max; // = 7.9228163e+28

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
        //Bound is a function that we use to limit the amount of collateral that we can deposit
        amountCollateral = bound(amountCollateral, 1 , MAX_DEPOSIT_SIZE);

        vm.startPrank(msg.sender);
        collateral.mint(msg.sender, amountCollateral);
        collateral.approve(address(dscEngine),amountCollateral);
        dscEngine.depositCollateral(address(collateral), amountCollateral);
        vm.stopPrank();
    }

    function redeemCollateral(uint256 collateralSeed, uint256 amountCollateral) public{
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        uint256 maxCollateralToRedeem = dscEngine.getS_collateralDoposited(msg.sender, address(collateral));
        //maxCollatelaToReddem can be 0 and in that case, function breaks

        amountCollateral = bound(amountCollateral, 0 , maxCollateralToRedeem);
        if(amountCollateral == 0){
            return;
        }
        vm.startPrank(msg.sender);
        dscEngine.redeemCollatreral(address(collateral), amountCollateral);
        vm.stopPrank();
    }

    function mintDSC(uint amount, uint256 collateralSeed) public{
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        uint256 maxAmountToMint = dscEngine.getMaxAmountToMint(msg.sender, address(collateral));
        if(maxAmountToMint < 0){
            return;
        }
        timesMintFunctionIsCalled++;
        amount = bound(amount, 0 , maxAmountToMint);
        if(amount == 0){
            return;
        } 
        vm.startPrank(msg.sender);
        dscEngine.mintDSC(amount);
        vm.stopPrank();
        
    }

    //Helper Functions

    function _getCollateralFromSeed(uint256 collateralSeed) private view returns(ERC20Mock){

        if(collateralSeed % 2 == 0){
            return weth;
        }   return wbtc;
    }
}

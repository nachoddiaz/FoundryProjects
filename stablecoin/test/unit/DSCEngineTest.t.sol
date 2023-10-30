// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {DeployDSC} from "script/DeployDSC.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";

contract DSCEngineTest is Test {
    DeployDSC deployer;
    DSCEngine dscEngine;
    DecentralizedStableCoin dsc;
    HelperConfig config;

    address ethUsdPriceFeedAddress;
    address weth;

    address immutable i_USER = makeAddr("user");
    uint256 immutable i_amount_collateral = 10 ether;
    uint256 immutable i_collateral_deposited = 1 ether;
    uint256 constant i_starting_erc20_balance = 10 ether;
    uint8 constant GAS_PRICE = 1;

    function setUp() external {
        deployer = new DeployDSC();
        (dsc, dscEngine, config) = deployer.run();
        (ethUsdPriceFeedAddress,, weth,,) = config.ActiveNetworkConfig();

        ERC20Mock(weth).mint(address(dscEngine), i_amount_collateral);
    }

    ////////////////////////
    //     Price tests    //
    ////////////////////////

    function testGetUsdValue() external {
        uint256 amount = 15e18; //We have 15 ETH, each consts 2000USD -> 30000USD
        uint256 expectedValue = 30000;
        uint256 actualValue = dscEngine.getUsdValue(amount, weth);
        assertEq(actualValue, expectedValue);
    }

    //////////////////////////////////
    //   Deposit Collateral tests   //
    //////////////////////////////////

    function testDepositCollateral() external {}

    function testRevertsIfCollateralZero() external {
        vm.startPrank(i_USER);
        //function approveInternal(address owner,address spender,uint256 value)
        ERC20Mock(weth).approve(address(dscEngine), i_amount_collateral);

        vm.expectRevert();
        dscEngine.depositCollateral(weth, 0);
        vm.stopPrank();
    }

    // function testEventEmited() external{
    //     vm.startPrank(i_USER);
    //     //function approveInternal(address owner,address spender,uint256 value)
    //     ERC20Mock(weth).approve(address(dscEngine),i_amount_collateral );

    //     dscEngine.depositCollateral(weth, i_collateral_deposited);
    //     vm.expectEmit(true, true, true, true);
    //     emit CollateralDoposited(address(i_USER), weth, i_collateral_deposited);
    //     dscEngine.depositCollateral();
    //     vm.stopPrank();
    // }

    ////////////////////
    // Modifier Tests //
    ////////////////////

    function testGreaterThanZero() external {
        vm.expectRevert();
        dscEngine.depositCollateral(weth, 0);
    }

    function testIsTokenAllowed() external {}

    //////////////////////////////////
    // Get Account Collateral tests //
    //////////////////////////////////

    function testAccountCollareral() external {
        uint256 actualCollateral = dscEngine._getAccountCollateralValueInUsd(i_USER);
    }
}

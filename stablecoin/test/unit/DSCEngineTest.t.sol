// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {DeployDSC} from "script/DeployDSC.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";

contract DSCEngineTest is Test {
    DSCEngine public dscEngine;
    DecentralizedStableCoin public dsc;
    HelperConfig public config;

    address ethUsdPriceFeedAddress;
    address weth;
    address btcUsdPriceFeedAddress;
    address wbtc;

    address immutable i_USER = makeAddr("user");
    address immutable i_LIQUIDATOR = makeAddr("liquidator");
    uint256 i_amount_collateral = 1 ether;
    uint256 i_amount_minted = 1000;
    uint256 i_amount_minted_breaks_health_factor = 2000;
    uint256 i_amount_to_redeem_ok = 0.3 ether;
    uint256 i_amount_to_redeem_fail = 2 ether;
    uint256 i_amount_burn_ok = 100;
    uint256 i_amount_burn_fail_because_breaks_health_factor = 500;
    uint256 i_amount_burn_fail_because_burned_greater_minted = 4000;
    uint256 constant i_starting_erc20_balance = 10 ether;
    uint8 constant GAS_PRICE = 1;
    uint256 private constant LIQUIDATION_THRESHOLD = 70; //70% overcollateralized
    uint256 private constant LIQUIDATION_DECIMALS = 100;

    function setUp() external {
        DeployDSC deployer = new DeployDSC();
        (dsc, dscEngine, config) = deployer.run();
        (ethUsdPriceFeedAddress, btcUsdPriceFeedAddress, weth, wbtc,) = config.ActiveNetworkConfig();

        vm.deal(i_USER, i_starting_erc20_balance);

        ERC20Mock(weth).mint(i_USER, i_starting_erc20_balance);
    }

    /////////////////////////
    //   Constructor test  //
    /////////////////////////

    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function testRevertsIfTokenLenghtDoesntMatchPriceFeeds() public {
        tokenAddresses.push(weth);
        priceFeedAddresses.push(ethUsdPriceFeedAddress);
        priceFeedAddresses.push(btcUsdPriceFeedAddress);

        vm.expectRevert(DSCEngine.DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength.selector);
        new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));
    }

    ////////////////////////
    //     Price tests    //
    ////////////////////////

    function testGetUsdValue() public {
        uint256 amount = 15e18; //We have 15 ETH, each consts 2000USD -> 30000USD
        uint256 expectedValue = 30000e18;
        uint256 actualValue = dscEngine.getUsdValue(amount, weth);
        assertEq(actualValue, expectedValue);
    }

    function testGetTokenAmountFromUsd() public {
        uint256 amount = 15e18; //We have 15 USD, each ETH costs 2000USD -> 15USD/2000USD = 0.0075ETH
        uint256 expectedValue = 75e14;
        uint256 actualValue = dscEngine.getTokenAmountFromUsd(weth, amount);
        assertEq(actualValue, expectedValue);
    }

    //////////////////////////////////
    //   Deposit Collateral tests   //
    //////////////////////////////////

    function testRevertsIfCollateralZero() external {
        vm.startPrank(i_USER);
        //function approveInternal(address owner,address spender,uint256 value)
        ERC20Mock(weth).approve(address(dscEngine), i_amount_collateral);

        vm.expectRevert();
        dscEngine.depositCollateral(weth, 0);
        vm.stopPrank();
    }

    function testRevertsIfTokenIsntAllowed() external {
        //Creation of a new token to try
        ERC20Mock randomToken = new ERC20Mock("onix","O", i_USER, i_amount_collateral);

        vm.startPrank(i_USER);
        vm.expectRevert(DSCEngine.DSCEngine__TokenNotSupported.selector);
        dscEngine.depositCollateral(address(randomToken), i_amount_collateral);
    }

    modifier depositCollateral() {
        vm.startPrank(i_USER);
        ERC20Mock(weth).approve(address(dscEngine), i_amount_collateral);
        dscEngine.depositCollateral(weth, i_amount_collateral);
        vm.stopPrank();
        _;
    }

    function testCollateralBalanceUpdated() external {
        vm.startPrank(i_USER);
        uint256 Before_getS_collateralDoposited = dscEngine.getS_collateralDoposited(i_USER, weth);
        ERC20Mock(weth).approve(address(dscEngine), i_amount_collateral);
        dscEngine.depositCollateral(weth, i_amount_collateral);
        uint256 After_getS_collateralDoposited = dscEngine.getS_collateralDoposited(i_USER, weth);
        vm.stopPrank();

        assertEq(Before_getS_collateralDoposited + i_amount_collateral, After_getS_collateralDoposited);
    }

    function testDepositEventEmited() external {}

    function testCanDepositAndGetAccountInfo() public depositCollateral {
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = dscEngine.getAccountInformation(i_USER);

        //First we convert the collateral deposited to ETH
        uint256 expectedDepositedAmountInETH = dscEngine.getTokenAmountFromUsd(weth, collateralValueInUsd);
        assertEq(totalDscMinted, 0);
        assertEq(expectedDepositedAmountInETH, i_amount_collateral);
    }

    //////////////////////////////////
    //     Mint Collateral tests    //
    //////////////////////////////////

    modifier mintDSC() {
        vm.startPrank(i_USER);
        dscEngine.mintDSC(i_amount_minted);
        vm.stopPrank();
        _;
    }

    modifier mintDSCBreaksHealthFactor() {
        vm.startPrank(i_USER);
        dscEngine.mintDSC(i_amount_minted_breaks_health_factor);
        _;
    }

    function testRevertsIfCollateralZeroWhileMinting() external {
        vm.startPrank(i_USER);
        vm.expectRevert();
        dscEngine.mintDSC(0);
        vm.stopPrank();
    }

    function testUserToAmountDCSMinted() external depositCollateral {
        vm.startPrank(i_USER);

        uint256 Before_getS_DSCMinted = dscEngine.getS_DSCMinted(i_USER);
        dscEngine.mintDSC(i_amount_minted);
        uint256 After_getS_DSCMinted = dscEngine.getS_DSCMinted(i_USER);

        vm.stopPrank();

        assertEq(Before_getS_DSCMinted + i_amount_minted, After_getS_DSCMinted);
    }

    //To calculate th health factor we need to deposit the colateral and mint some DSC
    function testHealthFactor() external depositCollateral mintDSC {
        (uint256 mintedDSC, uint256 collateralValue) = dscEngine.getAccountInformation(i_USER);

        uint256 realHealthFactor = ((collateralValue * LIQUIDATION_THRESHOLD / LIQUIDATION_DECIMALS) / mintedDSC);
        uint256 expectedHealthFactor = dscEngine.get_healthFactor(i_USER);

        assertEq(realHealthFactor, expectedHealthFactor);
    }

    /*
    * dev We try to mint more DSC than the health factor allows, then it reverts
    */
    function test_revertIfHealthFactorIsBroken() external depositCollateral mintDSC {
        //uint256 healthFactor = dscEngine.get_healthFactor(i_USER);
        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DCSEnfine__HealthFactorBelowMinimum.selector,0));
        dscEngine.mintDSC(i_amount_minted);
        //To know the balance of DSC that have our User
        console.log(dsc.balanceOf(i_USER));
    }

    //////////////////////////////
    // _Redeem Collateral Tests //
    //////////////////////////////

    function testRedeemFunctionWorksCorrectly() external depositCollateral {
        console.log(dscEngine.getS_collateralDoposited(i_USER, weth));
        dscEngine.get_redeemCollateral(weth, i_amount_to_redeem_ok, i_USER, i_LIQUIDATOR);
        console.log(dscEngine.getS_collateralDoposited(i_USER, weth));
    }

    function testCollateralBalanceUpdatedWhenRedeemed() external depositCollateral mintDSC {
        vm.startPrank(i_USER);
        uint256 Before_getS_collateralRedeemed = dscEngine.getS_collateralDoposited(i_USER, weth);
        ERC20Mock(weth).approve(address(dscEngine), i_amount_collateral);
        dscEngine.get_redeemCollateral(weth, i_amount_collateral, i_USER, i_LIQUIDATOR);
        uint256 After_getS_collateralRedeemed = dscEngine.getS_collateralDoposited(i_USER, weth);
        vm.stopPrank();
        console.log(dscEngine.getS_collateralDoposited(i_USER, weth));

        assertEq(Before_getS_collateralRedeemed - i_amount_collateral, After_getS_collateralRedeemed);
    }

    function testEventEmitedWhenRedeemed() external {}

    function test_revertIfAmountToRedeemGreaterThanCollateralDeposited() external depositCollateral {
        console.log(dscEngine.getS_collateralDoposited(i_USER, weth));
        vm.expectRevert(DSCEngine.DSCEngine__RedeemedMoreThanCollateralDeposited.selector);
        dscEngine.get_redeemCollateral(weth, i_amount_to_redeem_fail, i_USER, i_LIQUIDATOR);
        console.log(dscEngine.getS_collateralDoposited(i_USER, weth));
    }

    ///////////////////////////////
    //   Burn Collateral Tests   //
    ///////////////////////////////

    function testDscBalanceIsUpdated() external depositCollateral mintDSC {
        vm.startPrank(i_USER);
        dsc.approve(address(dscEngine), i_amount_burn_ok);
        uint256 Before_getS_DSCburned = dscEngine.getS_DSCMinted(i_USER);
        dscEngine.get_burnCollateral(i_amount_burn_ok, i_USER, i_USER);
        uint256 After_getS_DSCBurned = dscEngine.getS_DSCMinted(i_USER);
        vm.stopPrank();

        assertEq(Before_getS_DSCburned, After_getS_DSCBurned + i_amount_burn_ok);
    }

    /*
    * dev Cant break health factor when burning DSC cause we are minoring debt
    */
    function testRevertsIfAmount2BurnBreaksHealthFactor() external depositCollateral mintDSC {
        vm.startPrank(i_USER);
        console.log("health Factor", dscEngine.get_healthFactor(i_USER));
        //1400000000000000000
        dsc.approve(address(dscEngine), i_amount_burn_fail_because_breaks_health_factor);
        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DCSEnfine__HealthFactorBelowMinimum.selector,0));
        dscEngine.get_burnCollateral(i_amount_burn_fail_because_breaks_health_factor, i_USER, i_USER);
        vm.stopPrank();
    }

    function testRevertsIfAmount2Burn_greater_DSCMinted() external depositCollateral mintDSC {
        vm.startPrank(i_USER);
        dsc.approve(address(dscEngine), i_amount_burn_fail_because_burned_greater_minted);
        vm.expectRevert(DSCEngine.DSCEngine__BurnMoreThanDSCMinted.selector);
        dscEngine.get_burnCollateral(i_amount_burn_fail_because_burned_greater_minted, i_USER, i_USER);
        vm.stopPrank();
    }

    ///////////////////////////////////
    // Get Account Information tests //
    ///////////////////////////////////

    //////////////////////////////////
    //      Liquidation tests       //
    //////////////////////////////////
}

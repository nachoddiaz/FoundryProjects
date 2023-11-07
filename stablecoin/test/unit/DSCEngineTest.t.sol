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
    address btcUsdPriceFeedAddress;
    address wbtc;

    address immutable i_USER = makeAddr("user");
    uint256 i_amount_collateral = 1 ether;
    uint256 constant i_starting_erc20_balance = 10 ether;
    uint8 constant GAS_PRICE = 1;

    function setUp() external {
        deployer = new DeployDSC();
        (dsc, dscEngine, config) = deployer.run();
        (ethUsdPriceFeedAddress, btcUsdPriceFeedAddress, weth, wbtc,) = config.ActiveNetworkConfig();

        if (block.chainid == 31337) {
            vm.deal(i_USER, i_starting_erc20_balance);
        }

        ERC20Mock(weth).mint(address(dscEngine), i_starting_erc20_balance);
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
        uint256 expectedValue = 30000;
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

    function testDepositCollateral() external {}

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
        vm.expectRevert(DSCEngine.DSCEngine__MustBeMoreThanZero.selector);
        dscEngine.depositCollateral(address(randomToken), i_amount_collateral);
    }

    modifier depositCollateral(){
        vm.startPrank(i_USER);
        ERC20Mock(weth).approve(address(dscEngine), i_amount_collateral);
        dscEngine.depositCollateral(weth, i_amount_collateral);
        vm.stopPrank();
        _;
    }

    function testCollateralBalanceUpdated() external {}

    function testDepositEventEmited() external {}

    function testCanDepositAndGetAccountInfo() public depositCollateral{
        (uint256 mintedDSCValue, uint256 collateralValue) = dscEngine.getAccountInformation(i_USER);

        //We dont call the mint function -> mintedDSCValue = 0
        uint256 expectedTotalDscminted = 0;
        uint256 expectedCollateralValueInUsd = dscEngine.getTokenAmountFromUsd(weth, collateralValue);
        assertEq(mintedDSCValue, expectedTotalDscminted);
        assertEq(collateralValue, expectedCollateralValueInUsd);    



    }

    ////////////////////
    // Modifier Tests //
    ////////////////////



    //////////////////////////////////
    // Get Account Collateral tests //
    //////////////////////////////////

    // function testAccountCollareral() external {
    //     uint256 actualCollateral = dscEngine._getAccountCollateralValueInUsd(i_USER);
    // }
}

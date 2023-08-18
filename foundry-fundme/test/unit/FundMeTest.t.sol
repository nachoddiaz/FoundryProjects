// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

//import {StdCheats} from "forge-std/StdCheats.sol";
//import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract FundMeTest is Test {
    //Declaro las variables
    FundMe fundMe;
    HelperConfig helperConfig;

    //i_** for immutable variables
    //s_** for storage variables
    //Mayus for constants
    //We create a fake user that will be used to test the contract
    address immutable i_USER = makeAddr("user");
    uint256 immutable i_sent_value = 0.1 ether;
    uint256 constant INITIAL_ETH = 10 ether;
    uint256 constant GAS_PRICE = 1;

    //SetUp test always runs before any test
    function setUp() external {
        //This is the ETH/USD pair in the Sepolia testnet
        DeployFundMe deployFundMe = new DeployFundMe();
        (fundMe, helperConfig) = deployFundMe.run();
        //Set the user with some inital ETH
        vm.deal(i_USER, INITIAL_ETH);
    }

    function testMinFund() external {
        assertEq(fundMe.MIN_USD(), 50e18);
    }

    function testOwnerIsMsgSender() public {
        //El dueño del contrato será el que lo despliegue, este contrato lo despliega en la linea 13
        assertEq(fundMe.i_owner(), msg.sender);
    }

    function testVersionAccurated() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
        console.log(version);
    }

    //This test passes if not enough ETH has been sent
    function testFundFailsIfIsntEnoughETH() public {
        //Indica que esperamos que la siguiente linea de código falle
        vm.expectRevert();
        fundMe.fund{value: 0.0001 ether}();
    }

    //We can create modifiers to reuse code
    modifier funded() {
        //we use the fake address we set up before
        vm.prank(i_USER);
        fundMe.fund{value: i_sent_value}();
        _;
    }

    function testFundUpdatesFundedDataStructure() public funded {
        uint256 amountFunded = fundMe.getFundsDepositedByAddress(i_USER);
        console.log(amountFunded);
        assertEq(amountFunded, i_sent_value);
    }

    function testAddsFunderToArray() public funded {
        address funder = fundMe.getFunder(0);
        assertEq(funder, i_USER);
    }

    function testBalanceUpdatedIfFund() public funded {
        uint256 balance = fundMe.getBalance();
        assertEq(balance, i_sent_value);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(i_USER);
        fundMe.withdraw();
    }

    function testwithdrawWithSingleFunder() public funded {
        //Arrange
        uint256 staringOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(endingOwnerBalance, staringOwnerBalance + startingFundMeBalance);
    }

    function testWithdrawWithMultipleFunders() public funded {
        //Arrange
        //if we want to convert an uint to an address we need to use uint160
        //cause an address takes 160 bits
        uint160 numFunders = 10;
        uint160 startingIndex = 1;
        for (uint160 i = startingIndex; i < numFunders; i++) {
            //sets up a prank in an address with some ETH in it
            hoax(address(i), i_sent_value);
            fundMe.fund{value: i_sent_value}();
        }
        uint256 staringOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        //gasleft() is a function from the solidty Docs
        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE);
        //all between startPrank and StopPrank will be executed by the address we set up
        // vm.startPrank(fundMe.getOwner());
        // fundMe.withdraw();
        // vm.stopPrank();
        //vm.Startprank() + vm.StopPrank() uses 307 more gas than using only vm.prank
        //Thats beacuse stopPrank reset msg.sender to its previous value
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        uint256 gasEnd = gasleft();
        //tx.gasPrice is a function from the solidity Docs that returns the current gas price in wei
        uint256 gasUsedinUsd = (gasStart - gasEnd) * tx.gasprice;
        console.log(gasUsedinUsd);

        //Assert
        assertEq(fundMe.getBalance(), 0);
        assertEq(staringOwnerBalance + startingFundMeBalance, fundMe.getOwner().balance);
    }

    function testWithdrawWithMultipleFundersCheaper() public funded {
        //Arrange
        uint160 numFunders = 10;
        uint160 startingIndex = 1;
        for (uint160 i = startingIndex; i < numFunders; i++) {
            hoax(address(i), i_sent_value);
            fundMe.fund{value: i_sent_value}();
        }
        uint256 staringOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.cheaperWithraw();

        //Assert
        assertEq(fundMe.getBalance(), 0);
        assertEq(staringOwnerBalance + startingFundMeBalance, fundMe.getOwner().balance);
    }

    function testFundDepositedByAddressReinitializedWhenWithdraw() public {
        fundMe.fund{value: i_sent_value}();
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();
        assertEq(fundMe.getFundsDepositedByAddress(i_USER), 0);
    }

    function testFundersArrayReinitializedWhenWithdraw() public {
        vm.startPrank(fundMe.getOwner());
        fundMe.fund{value: i_sent_value}();

        fundMe.withdraw();
        vm.stopPrank();
        assertEq(fundMe.getFundersArray().length, 0);
    }

    function testCheaperWithdraw(uint256 x) public {
        // fundMe.setNumber(x);
        // assertEq(fundMe.number(), x);
    }
}

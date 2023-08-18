//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {FundFundMe, WithdrawFundMe} from "../../script/Interactions.s.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract InteractionsTest is Test {
    FundMe public fundMe;
    HelperConfig public helperConfig;

    address immutable i_USER = makeAddr("user");
    address immutable i_USER_2 = address(1);
    uint256 immutable i_sent_value = 0.1 ether;
    uint256 constant INITIAL_ETH = 10 ether;

    function setUp() external {
        DeployFundMe deploy = new DeployFundMe();
        (fundMe, helperConfig) = deploy.run();
        vm.deal(i_USER_2, INITIAL_ETH);
    }

    function testUserCanFundAndWithdraw() public {
        //Act
        FundFundMe fundFundMe = new FundFundMe();
        fundFundMe.fundFundMe(address(fundMe));

        WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
        withdrawFundMe.withdrawFundMe(address(fundMe));

        //Assert
        assertEq(address(fundMe).balance, 0);
    }
}

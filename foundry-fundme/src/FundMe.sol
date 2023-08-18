// SPDX-License-Identifier: MIT

// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

pragma solidity ^0.8.0;

//////////////////
//   IMPORTS    //
//////////////////

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

/////////////////
//    ERRORS   //
/////////////////

error FundMe__OnlyOwner();

contract FundMe {
    //extends the functionality of the uint256 data type  to the functions inside the PriceConverter library
    using PriceConverter for uint256;

    //////////////////
    //   Variables  //
    //////////////////
    //Constants & immutables are not in storage, they are in the bytecode of the cotnract
    //Variables inside functions are either in sotrage, they are in memory
    uint256 public constant MIN_USD = 50 * 10 ** 18;
    address public immutable i_owner;
    mapping(address => uint256) private s_amountFundedByFunder;
    address[] private s_funders;
    AggregatorV3Interface private s_priceFeed;

    //////////////////
    //   Modifiers  //
    //////////////////

    modifier isOwner() {
        if (msg.sender != i_owner) {
            revert FundMe__OnlyOwner();
        }
        _;
    }

    //////////////////
    //   Functions  //
    //////////////////

    // Functions Order:
    //// constructor
    //// receive
    //// fallback
    //// external
    //// public
    //// internal
    //// private
    //// view / pure

    //Al desplegar el contrato le indicamos que feed de precios vamos a usar
    constructor(address priceFeed) {
        s_priceFeed = AggregatorV3Interface(priceFeed);
        i_owner = msg.sender;
    }

    function fund() public payable {
        //require(msg.value.getConversionRate(msg.value) >= MIN_USD, "deposit more ETH");
        require(msg.value.getConversionRate(s_priceFeed) >= MIN_USD, "deposit more ETH");
        s_amountFundedByFunder[msg.sender] += msg.value;
        s_funders.push(msg.sender);
    }

    function withdraw() public isOwner {
        //Here we do SLOAD in each iteration of the loop cause we read s_funders.length , soo expensive
        for (uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++) {
            address funder = s_funders[funderIndex];
            s_amountFundedByFunder[funder] = 0;
        }
        //reinicia el vector de funders
        s_funders = new address[](0);
        (bool success,) = i_owner.call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }

    function cheaperWithraw() public isOwner {
        //Si pasamos la variable s_funders a una variable local, no tenemos que hacer SLOAD en cada iteración
        //Solo hacemos SLOAD una vez
        //El resto de veces hacemos MLOAD, que es mucho más barato -> 3 de gas
        address[] memory _funders = s_funders;
        for (uint256 funderIndex = 0; funderIndex < _funders.length; funderIndex++) {
            address funder = _funders[funderIndex];
            s_amountFundedByFunder[funder] = 0;
        }
        s_funders = new address[](0);
        (bool success,) = i_owner.call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }

    // Ether is sent to contract
    //      is msg.data empty?
    //          /   \
    //         yes  no
    //         /     \
    //    receive()?  fallback()
    //     /   \
    //   yes   no
    //  /        \
    //receive()  fallback()

    // fallback() external payable {
    //     fund();
    // }

    // receive() external payable {
    //     fund();
    //}

    //////////////////
    //   Getters    //
    //////////////////

    function getFundsDepositedByAddress(address _fundingAddress) public view returns (uint256) {
        return s_amountFundedByFunder[_fundingAddress];
    }

    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getFundersArray() external view returns (address[] memory) {
        return s_funders;
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    //This function is expendable because we can know the balance
    //using address(ContractName).balance
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}

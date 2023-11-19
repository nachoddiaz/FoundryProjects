//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;


import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
/*
*  @title Oracle Library for Decentralized Stable Coin
*  @author Nacho Díaz 
*  @dev This library is used to check if there is stale data in the oracle
*  If price is stale, the function will revert. DSCEngine will freeze
*/
library OracleLib {
    function stalePriceCheck(AggregatorV3Interface priceFeed)public{
        
    }
    
}
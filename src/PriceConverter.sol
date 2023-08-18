// SPDX-License-Identifier: MIT

import {FundMe} from "./FundMe.sol";

pragma solidity ^0.8.0;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface _priceFeed) internal view returns (uint256) {
        //AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        (, int256 answer,,,) = _priceFeed.latestRoundData();
        return uint256(answer * 10 ** 10);
    }

    function getConversionRate(uint256 _amount, AggregatorV3Interface _priceFeed) internal view returns (uint256) {
        uint256 price = getPrice(_priceFeed);
        uint256 UsdAmount = (_amount * price) / (10 ** 18);
        return UsdAmount;
    }
}

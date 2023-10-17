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

pragma solidity 0.8.19;

/*
*  @title DSCEngine
*  @author Nacho Díaz
*  
*  This contract is desinged to be as minimal as possible
*  The goal is to maintain the vlaue of the coin pegged to 1 USD
*
*  Has an Exogenous Collateral, is dollar pegged and is Algorithmic Stable
*
*  The system should be Ovdrcollateralized. 
*  THE VALUE OF THE COLLATERAL SHOLDNT BE LESS THAN THE USD VALUE OF ALL THE DSC
*
*  @notice This contract governs the DecentralizedStableCoin contract.
*  @notice This contract handles the logic for minting, redeeming DSC and deposit/withdraw collateral
*
*/

contract DSCEngine {

    
    ///////////////////
    //    Errors     //
    ///////////////////
    error DSCEngine__MustBeMoreThanZero();

    ///////////////////
    //   Modifers    //
    ///////////////////

    modifier GreaterThanZero(uint256 _amount) {
        require(_amount > 0, DSCEngine__MustBeMoreThanZero());
        _;
    } 

    modifier isTokenAllowed(address _token) {
        require
        
    }
        
    }


    /////////////////////
    // State Variables //
    /////////////////////

    mapping (address token => address priceFeed) private s_priceFeeds; //TokenToPriceFeed

    ///////////////////
    //   Functions   //
    ///////////////////

    constructor() {}
 

    ////////////////////////
    // External Functions //
    ////////////////////////

    /**
    * @param tokenCollateralAddress -> Address of the collateral token
    * @param amountCollateral -> Amount of collateral to deposit
    */
    function depositCollateralAndMintDSC(address tokenCollateralAddress, uint256 amountCollateral) external GreaterThanZero(amountCollateral) {

    }

  

    function depositCollatreral() external {}

    function redeemCollateralForDSC() external {}

    function redeemCollatreral() external {}

    function mintDSC() external {}

    function burnDSC() external {}

    function liquidate() external {}

    function getHealthFactor() external {}
}

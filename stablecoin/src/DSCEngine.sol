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

pragma solidity ^0.8.19;

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

import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";
//So we can use the nonReentrant modifier
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
//So we can use the transferFrom function
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract DSCEngine is ReentrancyGuard {
    ///////////////////
    //    Errors     //
    ///////////////////
    error DSCEngine__MustBeMoreThanZero();
    error DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
    error DSCEngine__TokenNotSupported();
    error DSCEngine__DepositCollateralFailed();

    ///////////////////
    //    Events     //
    ///////////////////

    //Using indexed we can filter the events by the indexed parameters causethis parameter will be indexed by the Ethereum node's log system
    //Ex. show all the "CollarerDoposited" events for a specific user
    event CollateralDoposited(address indexed user, address indexed token, uint256 amountCollateral);

    ///////////////////
    //   Modifers    //
    ///////////////////

    modifier GreaterThanZero(uint256 _amount) {
        //Custom errors cant be used with the require statement
        if (_amount > 0) revert DSCEngine__MustBeMoreThanZero();
        _;
    }

    modifier isTokenAllowed(address _token) {
        //If _token is not in the mapping, it returns 0x0 address thats equals to address(0)
        if (s_priceFeeds[_token] != address(0)) revert DSCEngine__TokenNotSupported();
        _;
    }

    /////////////////////
    // State Variables //
    /////////////////////

    mapping(address token => address priceFeed) private s_priceFeeds; //TokenToPriceFeed
    mapping(address user => mapping(address token => uint256 amountCollateral)) private s_collateralDoposited; //UserToAmountCollateral
    mapping(address user => uint256 amountDCSMinted) private s_DSCMinted; //UserToAmountDCSMinted
    address[] private s_collateraltokens; //Array where we store the collateral token addresses

    DecentralizedStableCoin private immutable i_dsc;

    ///////////////////
    //   Functions   //
    ///////////////////

    /*
    * @param tokenAddresses -> Array of token addresses
    * @param priceFeedAddresses -> Array of price feed addresses
    * @param dscAddress -> Address of the DSC contract
    */
    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddresses, address dscAddress) {
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
        }

        //Set the alowed tokens
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
            s_collateraltokens.push(tokenAddresses[i]);
        }
        i_dsc = DecentralizedStableCoin(dscAddress);
    }

    ////////////////////////
    // External Functions //
    ////////////////////////

    /**
     * @param tokenCollateralAddress -> Address of the collateral token
     * @param amountCollateral -> Amount of collateral to deposit
     */
    function depositCollateralAndMintDSC(address tokenCollateralAddress, uint256 amountCollateral)
        external
        GreaterThanZero(amountCollateral)
        isTokenAllowed(tokenCollateralAddress)
        //We use nonReentrant to avoid reentrancy attacks cause this is an external function. Uses more gas
        nonReentrant
    {
        s_collateralDoposited[msg.sender][tokenCollateralAddress] =
            s_collateralDoposited[msg.sender][tokenCollateralAddress] + amountCollateral;

        emit CollateralDoposited(msg.sender, tokenCollateralAddress, amountCollateral);

        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
        if (!success) revert DSCEngine__DepositCollateralFailed();
    }

    function depositCollatreral() external {}

    function redeemCollateralForDSC() external {}

    function redeemCollatreral() external {}


    /*
    * @param amountToMint -> Amount of DSC to mint
    * @notice Need more collateral then the minimum collateral ratio
    */
    function mintDSC(uint256 amountToMint) external GreaterThanZero(amountToMint) nonReentrant {
        s_DSCMinted[msg.sender] = s_DSCMinted[msg.sender] + amountToMint;
        _revertIfHealthFactorIsBroken(msg.sender);
        
    }

    function burnDSC() external {}

    function liquidate() external {}

    function getHealthFactor() external {}



    ////////////////////////
    // Internal Functions //
    ////////////////////////

    //We use _FunctionName to indicate that the function is internal

    

    function _getCollateralAndMintedDSCValue(address) internal returns (uint256 mintedDSCValue, uint256 collateralValue) {
        //1. Get the collateral value
        collateralValue = _getAccountCollateralValue(user);
        //2. Get the minted DSC value
        mintedDSCValue = s_DSCMinted[msg.sender];
        //3. Return both values
    }

    /*
    * @param user -> Address of the user
    * @return -> Health Factor of the user
    * @notice Health Factor = (CollateralValue * CollateralRatio) / MintedDSCValue
    * @notice If a user goes below 1, they can get liquidated
    */
    function _healthFactor(address user)  internal returns (uint256) {
        (uint256 mintedDSCValue, int256 collateralValue) = _getCollateralAndMintedDSCValue(user);
        
    }

    function _revertIfHealthFactorIsBroken(address minter) internal view{
        //1. Check Health Factor

        //2. Revert if not enough collateral
        
    }





    ////////////////////////
    //   View Functions   //
    ////////////////////////



    function _getAccountCollateralValue(address user) public view returns (uint256) {
        //1. Get the collateral value
            //1.1 get the amount of each token that has been deposited
            for(uint256 i=0; i<s_collateraltokens.length; i++){
                address token = s_collateraltokens[i];
                uint256 amountCollateral = s_collateralDoposited[user][token];
                //1.2 get the price in USD of each token
                uint256 amountCollateralInUsd = s_priceFeeds[token]
                //1.3 multiply the amount of each token by the price in USD of each token
                uint256 total = total + amountCollateral;
            }
            
            
        //2. Return the collateral value
    }

    function getUsdValue(uint256 ammount, address token) public view returns (uint256) {

        //1. Get the price in USD of the token
        //2. Multiply the amount by the price in USD of the token
        //3. Return the value in USD
    }
}

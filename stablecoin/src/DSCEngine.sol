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
import {console} from "forge-std/Test.sol";
import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";
//So we can use the nonReentrant modifier
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
//So we can use the transferFrom function
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from
    "lib/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract DSCEngine is ReentrancyGuard {
    ///////////////////
    //    Errors     //
    ///////////////////
    error DSCEngine__MustBeMoreThanZero();
    error DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
    error DSCEngine__TokenNotSupported();
    error DSCEngine__DepositCollateralFailed();
    error DCSEnfine__HealthFactorBelowMinimum(uint256 healthFactor);
    error DCSEngine__HealthFactorBelowMinimum();
    error DSCEngine__MintFailed();
    error DSCEngine__RedeemCollateralFailed();
    error DSCEngine__BurnDSCFailed();
    error DSCEngine__HealthFactorOk(address user);
    error DSCEngine__LiquidationFailed();
    error DSCEngine__HealthFactorNotImproved();
    error DSCEngine__RedeemedMoreThanCollateralDeposited();
    error DSCEngine__BurnMoreThanDSCMinted();

    ///////////////////
    //    Events     //
    ///////////////////

    //Using indexed we can filter the events by the indexed parameters causethis parameter will be indexed by the Ethereum node's log system
    //Ex. show all the "CollarerDoposited" events for a specific user
    event CollateralDeposited(address indexed user, address indexed token, uint256 amountCollateral);
    event CollateralRedeemed(
        address indexed redeemedFrom, address indexed redeemedTo, address indexed token, uint256 amountCollateral
    );
    event DSCBurned(address indexed user, uint256 amountDSC);

    ///////////////////
    //   Modifers    //
    ///////////////////

    modifier GreaterThanZero(uint256 _amount) {
        //Custom errors cant be used with the require statement
        if (_amount == 0) revert DSCEngine__MustBeMoreThanZero();
        _;
    }

    modifier isTokenAllowed(address _token) {
        //If _token is not in the mapping, it returns 0x0 address thats equals to address(0)
        if (s_priceFeeds[_token] == address(0)) revert DSCEngine__TokenNotSupported();
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

    uint256 private constant FEED_PRECISION = 1e10;
    uint256 immutable ETHDECIMALS = 1e18;
    uint256 private constant LIQUIDATION_THRESHOLD = 70; //70% overcollateralized
    uint256 private constant LIQUIDATION_DECIMALS = 100;
    uint256 private constant MIN_HEALTH_FACTOR = 1e18;
    uint256 private constant LIQUIDATION_BONUS = 10; //10% of the debt goes to liqiudators
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

    /*
    * @param tokenCollateralAddress -> Address of the collateral token
    * @param amountCollateral -> Amount of collateral to deposit
    * @param amountDscToMint -> Amount of DSC to mint
    * @notice this function will deposit collateral and mint DSC in the same tx
    * @notice need more collateral than 1.5x the amount of DSC minted 
    */

    function depositCollateralAndMintDSC(
        address tokenCollateralAddress,
        uint256 amountCollateral,
        uint256 amountDscToMint
    ) external {
        depositCollateral(tokenCollateralAddress, amountCollateral);
        mintDSC(amountDscToMint);
    }

    /*
    * @param tokenCollateralAddress -> Address of the collateral token
    * @param amountCollateral -> Amount of collateral to redeem
    * @param amountToBurn -> Amount of DSC to burn
    * @notice this function will redeem collateral and burn DSC in the same tx
    */
    function redeemCollateralForDSC(address tokenCollateralAddress, uint256 amountCollateral, uint256 amountToBurn)
        external
    {
        redeemCollatreral(tokenCollateralAddress, amountCollateral);
        burnDSC(amountToBurn);
        //both functions check healthFactor
    }

    ////////////////////////
    //  Public Functions  //
    ////////////////////////

    /**
     * @param tokenCollateralAddress -> Address of the collateral token
     * @param amountCollateral -> Amount of collateral to deposit
     */
    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        public
        GreaterThanZero(amountCollateral)
        isTokenAllowed(tokenCollateralAddress)
        //We use nonReentrant to avoid reentrancy attacks cause this is an external function. Uses more gas
        nonReentrant
    {
        s_collateralDoposited[msg.sender][tokenCollateralAddress] =
            s_collateralDoposited[msg.sender][tokenCollateralAddress] + amountCollateral;

        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);

        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
        if (!success) revert DSCEngine__DepositCollateralFailed();
    }

    /*
    * @param amountToMint -> Amount of DSC to mint
    * @notice Need more collateral then the minimum collateral ratio
    */
    function mintDSC(uint256 amountToMint) public GreaterThanZero(amountToMint) nonReentrant {
        s_DSCMinted[msg.sender] = s_DSCMinted[msg.sender] + amountToMint;
        _revertIfHealthFactorIsBroken(msg.sender);

        bool minted = i_dsc.mint(msg.sender, amountToMint);
        if (!minted) {
            revert DSCEngine__MintFailed();
        }
    }

    //Health factor must be greater than 1 after collateral pulled
    function redeemCollatreral(address tokenCollateralAddress, uint256 amountCollateral)
        public
        GreaterThanZero(amountCollateral)
        isTokenAllowed(tokenCollateralAddress)
        nonReentrant
    {
        _redeemCollateral(tokenCollateralAddress, amountCollateral, msg.sender, msg.sender);
        //Just to be sure that the user has enough collateral
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    function burnDSC(uint256 amount) public GreaterThanZero(amount) {
        _burnDSC(amount, msg.sender, msg.sender);
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    //If someone is near liquidation, we need someoune to liquidate him
    //To achieve that, the liquidator burns the debt and keep the collateral of the first debtor
    //1. the contract need to call redeem and burn to keep the DSC value stable

    /*
    * @param tokenCollateralAddress -> Address of the collateral token
    * @param user -> Address of the user that has a healtFactor below MIN_HEALTH_FACTOR
    * @param debtToCover -> Amount of DSC to burn to improve the healthFactor of the user
    * @notice Partial liquidations are allowed
    * @notice The liquidator will get the collateral of the user -> Big incentive
    * @notice The function assumes the protocol will be 150% overcollateralized to work
    * @notice The msg.sender must be the liquidator
    */
    function liquidate(address tokenCollateralAddress, address user, uint256 debtToCover)
        private
        GreaterThanZero(debtToCover)
        isTokenAllowed(tokenCollateralAddress)
        nonReentrant
    {
        //Check Health Factor of the user
        uint256 startingHealthFactor = _healthFactor(user);
        if (startingHealthFactor >= MIN_HEALTH_FACTOR) {
            revert DSCEngine__HealthFactorOk(user);
        }
        //1. Burn the debt of the user

        uint256 tokenAmountFromDebtCovered = getTokenAmountFromUsd(tokenCollateralAddress, debtToCover);
        //Liquidators need some incentive -> give them 10% of the debt
        uint256 bonusToLiquidators = (tokenAmountFromDebtCovered * LIQUIDATION_BONUS) / LIQUIDATION_DECIMALS;

        uint256 totalCollateralToRedeem = tokenAmountFromDebtCovered + bonusToLiquidators;
        _redeemCollateral(tokenCollateralAddress, totalCollateralToRedeem, user, msg.sender);
        //Burn the debt of the user
        _burnDSC(debtToCover, user, msg.sender);

        uint256 endingUserHealthFacotr = _healthFactor(user);
        if (endingUserHealthFacotr <= startingHealthFactor) {
            revert DSCEngine__HealthFactorNotImproved();
        }
        _revertIfHealthFactorIsBroken(msg.sender);

        //Who will get the remain collateral -> debtToCover - bonusToLiquidators?

        bool success = IERC20(tokenCollateralAddress).transfer(msg.sender, bonusToLiquidators);
        if (!success) {
            revert DSCEngine__LiquidationFailed();
        }
    }

    ////////////////////////
    // Internal Functions //
    ////////////////////////

    //We use _FunctionName to indicate that the function is internal

    /*
    * @param tokenCollateralAddress -> Address of the collateral token
    * @param amountCollateral -> Amount of collateral to deposit
    * @param from -> Address of the user thats is going to be liquidated
    * @param to -> Address of the liquidator and de receiver of the reward
    */
    function _redeemCollateral(
        address tokenCollateralAddress,
        uint256 amountCollateralToRedeem,
        address from,
        address to
    ) private {
        if (s_collateralDoposited[from][tokenCollateralAddress] < amountCollateralToRedeem) {
            revert DSCEngine__RedeemedMoreThanCollateralDeposited();
        }
        s_collateralDoposited[from][tokenCollateralAddress] -= amountCollateralToRedeem;
        emit CollateralRedeemed(from, to, tokenCollateralAddress, amountCollateralToRedeem);

        bool success = IERC20(tokenCollateralAddress).transfer(to, amountCollateralToRedeem);
        if (!success) {
            revert DSCEngine__RedeemCollateralFailed();
        }
    }

    /*
    * @param amountDscToBurn -> Amount of DSC to burn
    * @param ownerOfCollateral -> Address of the user that has a healtFactor below MIN_HEALTH_FACTOR
    * @param DscFrom -> Address of the user that is going to burn the DSC
    * @dev Do not call this function unless the function calling checks the healthFactors
    */
    function _burnDSC(uint256 amountDscToBurn, address ownerOfCollateral, address DscFrom) private {
        if (s_DSCMinted[ownerOfCollateral] < amountDscToBurn) {
            revert DSCEngine__BurnMoreThanDSCMinted();
        }

        s_DSCMinted[ownerOfCollateral] -= amountDscToBurn;
        emit DSCBurned(ownerOfCollateral, amountDscToBurn);

        //We cant burn tokens without passing them previously to the contract,
        //Thats why first we transfer the tokens from the msg.sender to the contract
        //bool success = i_dsc.burn(amountDscToBurn);
        bool success = i_dsc.transferFrom(DscFrom, address(this), amountDscToBurn);
        if (!success) {
            revert DSCEngine__BurnDSCFailed();
        }
        i_dsc.burn(amountDscToBurn);
    }

    function _getAccountInformation(address user)
        private
        view
        returns (uint256 mintedDSCValue, uint256 collateralValue)
    {
        //1. Get the collateral value
        collateralValue = _getAccountCollateralValueInUsd(user);
        //2. Get the minted DSC value
        mintedDSCValue = s_DSCMinted[user];
        //3. Return both values
    }

    /*
    * @param user -> Address of the user
    * @return -> Health Factor of the user
    * @notice Health Factor = (CollateralValue * CollateralRatio) / MintedDSCValue
    * @notice If a user goes below 1, they can get liquidated
    */
    function _healthFactor(address user) private view returns (uint256) {
        (uint256 mintedDSCValueInUSD, uint256 collateralValueInUSD) = _getAccountInformation(user);
        if (mintedDSCValueInUSD == 0) {
            return type(uint256).max;
        }
        return uint256((collateralValueInUSD * LIQUIDATION_THRESHOLD / LIQUIDATION_DECIMALS) / (mintedDSCValueInUSD));
    }

    function _revertIfHealthFactorIsBroken(address minter) internal view {
        //1. Check Health Factor
        if (_healthFactor(minter) < MIN_HEALTH_FACTOR) {
            console.log("health factor is",_healthFactor(minter));
            //2. Revert if not enough collateral
            revert DCSEnfine__HealthFactorBelowMinimum(_healthFactor(minter));
        }
    }

    ////////////////////////
    //   View Functions   //
    ////////////////////////

    function _getAccountCollateralValueInUsd(address user) public view returns (uint256 amountCollateralInUsd) {
        //1. Get the collateral value
        //1.1 get the amount of each token that has been deposited
        for (uint256 i = 0; i < s_collateraltokens.length; i++) {
            address token = s_collateraltokens[i];
            uint256 amountCollateral = s_collateralDoposited[user][token];
            //1.2 get the price in USD of each token
            amountCollateralInUsd += getUsdValue(amountCollateral, token);
        }
        return amountCollateralInUsd;

        //2. Return the collateral value
    }

    function getUsdValue(uint256 amount, address token) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        //1. Get the price in USD of the token
        (, int256 price,,,) = priceFeed.latestRoundData();
        //2. Multiply the amount by the price in USD of the token
        //3. Return the value in USD -> ETHDECIMALS to get the value in USD, not in USD * 10e18
        return uint256(((uint256(price) * FEED_PRECISION) * amount) / (ETHDECIMALS));
    }

    //This function is the inverse of getUsdValue
    function getTokenAmountFromUsd(address token, uint256 usdAmountInWei) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (, int256 price,,,) = priceFeed.latestRoundData();
        //returns the amount of tokens that the debtToCover is worth
        return uint256((ETHDECIMALS * usdAmountInWei) / (uint256(price) * FEED_PRECISION));
    }

    function getAccountInformation(address user)
        external
        view
        returns (uint256 mintedDSCValue, uint256 collateralValue)
    {
        (mintedDSCValue, collateralValue) = _getAccountInformation(user);
        return (mintedDSCValue, collateralValue);
    }

    function getS_collateralDoposited(address user, address token) external view returns (uint256) {
        return s_collateralDoposited[user][token];
    }

    function getS_DSCMinted(address user) external view returns (uint256) {
        return s_DSCMinted[user];
    }

    function get_healthFactor(address user) external view returns (uint256) {
        return _healthFactor(user);
    }

    function get_revertIfHealthFactorIsBroken(address minter) external view {
        _revertIfHealthFactorIsBroken(minter);
    }

    function get_redeemCollateral(address tokenCollateralAddress, uint256 amountCollateral, address from, address to)
        external
    {
        _redeemCollateral(tokenCollateralAddress, amountCollateral, from, to);
    }

    function get_burnCollateral(uint256 amountDscToBurn, address ownerOfCollateral, address DscFrom) external {
        _burnDSC(amountDscToBurn, ownerOfCollateral, DscFrom);
    }

    function getCollateralTokens() external view returns (address[] memory) {
        return s_collateraltokens;
    }

    function getMaxAmountToMint(address user, address token) external view returns (uint256) {
        uint256 collaterlaDeposited = s_collateralDoposited[user][token];
        uint256 mintedDSCValue = s_DSCMinted[user];
        uint256 canMint = ((collaterlaDeposited * LIQUIDATION_THRESHOLD / LIQUIDATION_DECIMALS) - mintedDSCValue);
        return canMint;
    }

    function getCollateralTokenPriceFeed(address token) external view returns(address){
        return s_priceFeeds[token];

    }
}

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

pragma solidity ^0.8.18;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
//So the owner (DSCEngine) can own the contract
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
/*
*  @title Decentralized Stable Coin
*  @author Nacho Díaz
*  Collateral: Exogenous (ETH & BTC)
*  Minting : Algorithmic
*  Relative Stability: Pegged to USD
*
*  This contract is governated by DSCEngine.
*  This is just the ERC20 implementation of the stablecoin
*
*/

error DecentralizedStableCoin__MustBeMoreThanZero();
error DecentralizedStableCoin__BurnAmountExceedsBalance();
error DecentralizedStableCoin__NotZeroAddress();

contract DecentralizedStableCoin is ERC20Burnable, Ownable {
    //constructor() ERC20("DecentralizedStableCoin", "DSC") Ownable(0xF39fD6E51aad88F6F4CE6aB8827279CffFb92263) {}
    //Because we use v4.8.3 of openzeppelin, we dont need to use the constructor of ERC20 withouot Ownable(addressOftheContractOwner)
    //If we use the most recent version of openzeppelin, we need to use the constructor of ERC20 with Ownable(addressOftheContractOwner)

    constructor() ERC20("DecentralizedStableCoin", "DSC") {}

    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (_amount <= 0) revert DecentralizedStableCoin__MustBeMoreThanZero();
        if (balance < _amount) revert DecentralizedStableCoin__BurnAmountExceedsBalance();
        //The super. burn llama al método burn del contrato ERC20Burnable
        super.burn(_amount);
    }

    function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
        if (_to == address(0)) revert DecentralizedStableCoin__NotZeroAddress();
        if (_amount <= 0) revert DecentralizedStableCoin__MustBeMoreThanZero();
        _mint(_to, _amount);
        return true;
    }
}

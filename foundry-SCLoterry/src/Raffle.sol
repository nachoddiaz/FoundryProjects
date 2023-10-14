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

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.18;




/**
 * @title Raffle
 * @author Nacho Díaz
 * @notice This contract is for a creating an automated Raffle in Foundry
 * @dev Implements Chainlink VRF v2
 */
contract Raffle{

    error Raffle__NotEnoughFunds();
 
    uint256 immutable private i_entranceFee;
    address payable[] private s_players;


    /////////////////////
    //     Events      //
    /////////////////////

    event EnterRaffle(address indexed _player, uint256 _amount);

    constructor(uint256 _entranceFee) {
        i_entranceFee = _entranceFee;
    }

    function enterRaffle() external payable {
        //More gas efficient than require
        if(msg.value < i_entranceFee) {
            revert Raffle__NotEnoughFunds();
        }
        s_players.push(payable(msg.sender));
        emit EnterRaffle(msg.sender, msg.value);
    }

    function pickWinner() public {

    }

    function distributeFunds() public{

    }

    ///////////////////
    //    Getters    //
    ///////////////////


    function getEntranceFee() public view returns(uint256){
        return i_entranceFee;
    }
 

}
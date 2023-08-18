// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract StorageOptimization {
    uint256 favoriteNumber; //Is not immutable or constant, so it is in storage, at slot 0
    bool favoriteBool; //Like above but sotre in slot 1
    uint256[] Array; //The lenght of the array stored in slot 2. The data is stored in keccak256(2)
    mapping(uint256 => uint256) public map; //A empty slot is held in slot 3. Elements will be stored in keccak(h(k), p)
    //where h is a function but is based on the type. For uint256, it just pads the hex
    //k is the key in hex
    //p is the position in the array, in this case is 3

    //Variables down here are in the bytecode cause they are immutable or constant
    uint256 constant NOT_IN_STORAGE = 123;
    uint256 immutable NEITHER_IN_STORAGE;

    constructor() {
        //When we declare vairables here, we call the SSTORE opcode, which costs 20k gas the first time
        //and 5k gas the next times
        favoriteNumber = 5; //SSTORE
        favoriteBool = true; //SSTORE
        Array.push(234); //SSTORE
        map[0] = 123; //SSTORE

        NEITHER_IN_STORAGE = 123;
    }

    // function doSome() public {
    //     //When we declare variables here, we call the SLOAD opcode, which costs 800 gas
    //     uint256 nowVar = 1;
    //     bool newBool = true;
    // }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

contract SimpleStorage {
    /* Consts*/
    uint256 public myFavNumber;

    struct Person {
        string name;
        uint256 favNumber;
    }

    mapping(string => uint256) public name2favNumber;

    Person[] public people;

    function store(uint256 _favNumber) public {
        myFavNumber = _favNumber;
    }

    function retrieve() public view returns (uint256) {
        return myFavNumber;
    }

    function addPerson(string memory _name, uint256 _favNumber) public {
        people.push(Person(_name, _favNumber));
        name2favNumber[_name] = _favNumber;
    }
}

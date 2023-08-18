//Funciones de este fichero
//  Deploy mocks when we are on Anvil
//  Sepolia ETH/USD 0x694AA1769357215DE4FAC081bf1f309aDC325306
//  Mainnet ETH/USD 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
//  Sepolia LINK/USD 0xc59E3633BAAC79493d908e63626716e204A45EdF
//  Mainnet LINK/USD 0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c
//  Mumbai MATIC/USD 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada
//  Keep track of different contract addressesacross different chains

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    //If we are on anvil -> deploy mocks
    //Else -> use real addresses

    NetworkConfig public ActiveNetworkConfig;

    //We declare the variables to make a more readable contract
    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 1500e8;

    struct NetworkConfig {
        address PriceFeed;
    }

    constructor() {
        if (block.chainid == 11155111) {
            ActiveNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 80001) {
            ActiveNetworkConfig = getMumbaiMaticConfig();
        } else {
            ActiveNetworkConfig = getAndCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            //ETH/USD PriceFeed in Sepolia
            PriceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return sepoliaConfig;
    }

    function getSepoliaLinkConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            //LINK/USD PriceFeed in Sepolia
            PriceFeed: 0xc59E3633BAAC79493d908e63626716e204A45EdF
        });
        return sepoliaConfig;
    }

    function getAndCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        //Nos aseguramos de desplegar el mock solo una vez
        if (ActiveNetworkConfig.PriceFeed != address(0)) {
            return ActiveNetworkConfig;
        }
        //Deploy Mocks
        //Return mock´s addresses

        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            //LINK/USD PriceFeed in Sepolia
            PriceFeed: address(mockPriceFeed)
        });
        return anvilConfig;
    }

    function getMumbaiMaticConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            //MATIC/USD PriceFeed in Mumbai
            PriceFeed: 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada
        });
        return sepoliaConfig;
    }
}

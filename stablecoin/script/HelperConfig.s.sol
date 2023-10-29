//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";

contract HelperConfig is Script {
    uint8 public constant DECIMALS = 8;
    int256 public constant ETH_USD_INITIAL_PRICE = 2000e8;
    int256 public constant BTC_USD_INITIAL_PRICE = 30000e8;

    struct NetworkConfig {
        address wethUsdPriceFeedAddress;
        address wbtcUsdPriceFeedAddress;
        address weth;
        address wbtc;
        uint256 deployerKey;
    }

    NetworkConfig public ActiveNetworkConfig;

    constructor() {}

    function getSepoliaEthConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            wethUsdPriceFeedAddress: 0x694AA1769357215DE4FAC081bf1f309aDC325306,
            wbtcUsdPriceFeedAddress: 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43,
            weth: 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9,
            wbtc: 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063,
            deployerKey: vm.envUint("PRIVATE_KEY_MM_FP")
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        //Nos aseguramos de desplegar el mock solo una vez
        if (ActiveNetworkConfig.wethUsdPriceFeedAddress != address(0)) {
            return ActiveNetworkConfig;
        } else if (ActiveNetworkConfig.wbtcUsdPriceFeedAddress != address(0)) {
            return ActiveNetworkConfig;
        }

        vm.startBroadcast();
        MockV3Aggregator ethUsdPriceFeed = new MockV3Aggregator(DECIMALS, ETH_USD_INITIAL_PRICE);
        ERC20Mock weth = new ERC20Mock("Wrapped Ether", "WETH");
        MockV3Aggregator btcUsdPriceFeed = new MockV3Aggregator(DECIMALS, BTC_USD_INITIAL_PRICE);
        ERC20Mock wbtc = new ERC20Mock("Wrapped Bitcoin", "WBTC");
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            wethUsdPriceFeedAddress: address(ethUsdPriceFeed),
            wbtcUsdPriceFeedAddress: address(btcUsdPriceFeed),
            weth: weth.address,
            wbtc: wbtc.address,
            deployerKey: vm.envUint("PRIVATE_KEY_MM_FP")
        });
    }
}

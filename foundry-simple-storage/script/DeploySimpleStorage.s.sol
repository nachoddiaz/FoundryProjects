//Vamos a hacer un scrip para desplegat el contrato SimpleStorage.sol
//Esto no es un smart contract aunque esté en solidity

//SPDX-License-Identifier: UNLICENSED
//Debemos tenrr la misma version de solidity aqui que en el contrato que vamos a desplegar
pragma solidity 0.8.19;

//Importamos el contrato SimpleStorage.sol
import {SimpleStorage} from "../src/SimpleStorage.sol";
//importamos las funcionalidades de Forge
import {Script} from "lib/forge-std/src/Script.sol";

contract DeploySimpleStorage is Script {
    function run() external returns (SimpleStorage) {
        //uint256 deployerPrivKey = vm.envUint("PRIVATE_KEY_ANVIL_N1");

        vm.startBroadcast( /*deployerPrivKey*/ );

        SimpleStorage simpleStorage = new SimpleStorage();
        // simpleStorage.store(666);
        // console.log(simpleStorage.retrieve());

        vm.stopBroadcast();

        return simpleStorage;
    }
}

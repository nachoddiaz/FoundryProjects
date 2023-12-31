// //SPDX-License-Identifier: MIT
// //What are our invariants?

// //Total supply DSC < Total Value Collateral

// //Getter view functions should never revert

// pragma solidity ^0.8.18;

// import {Test, console} from "forge-std/Test.sol";
// import {StdInvariant} from "forge-std/StdInvariant.sol";
// import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
// import {DSCEngine} from "src/DSCEngine.sol";
// import {DeployDSC} from "script/DeployDSC.s.sol";
// import {HelperConfig} from "script/HelperConfig.s.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// contract OpenInvariantsTests is StdInvariant, Test{

//     DSCEngine public dscEngine;
//     DecentralizedStableCoin public dsc;
//     HelperConfig public config;

//     address weth;
//     address wbtc;

//     function setUp() external {
//         DeployDSC deployer = new DeployDSC();
//         (dsc, dscEngine, config) = deployer.run();
//         ( , , weth, wbtc , )= config.ActiveNetworkConfig();
//         targetContract(address(dscEngine));
//     }

//     function invariant_protocolMustHaveMoreValueThanTotalSuplly() public view{
//         //Get the value of all the collateral of the protocol and compare to the debt (minted)
//         uint256 totalSupply = dsc.totalSupply();
//         uint256 totalWethDeposited = IERC20(weth).balanceOf(address(dscEngine));
//         uint256 totalWbtcDeposited = IERC20(wbtc).balanceOf(address(dscEngine));

//         console.log("totalSupply: %s", totalSupply);
//         console.log("totalWethDeposited: %s", totalWethDeposited);
//         console.log("totalWbtcDeposited: %s", totalWbtcDeposited);

//         uint256 totalColateralValueInUsd = dscEngine.getUsdValue(totalWethDeposited, weth) + dscEngine.getUsdValue(totalWbtcDeposited, wbtc);

//         assert(totalColateralValueInUsd >= totalSupply);

//     }

// }

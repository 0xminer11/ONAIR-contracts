// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {AIRToken} from "../src/AIRToken.sol";
import {AIRProtocolCore} from "../src/AIRProtocolCore.sol";
import {AirdropController} from "../src/EpochAirdrop.sol";

contract Deploy is Script {
    function run() external {
        // Start broadcasting transactions. 
        // The signer is determined by the --private-key or --account flag passed to `forge script`.
        vm.startBroadcast();

        address deployer = msg.sender;
        address trustedForwarder = address(0); // Replace with actual forwarder if using meta-txs

        // 1. Deploy AIRToken
        AIRToken token = new AIRToken(deployer, trustedForwarder);
        console.log("AIRToken deployed at:", address(token));

        // 2. Deploy AIRProtocolCore
        AIRProtocolCore core = new AIRProtocolCore(deployer);
        console.log("AIRProtocolCore deployed at:", address(core));

        // 3. Deploy AirdropController
        AirdropController airdrop = new AirdropController(token, deployer);
        console.log("AirdropController deployed at:", address(airdrop));

        vm.stopBroadcast();
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {AIRProtocolForwarder} from "../src/AIRProtocolForwarder.sol";
import {AIRToken} from "../src/AIRToken.sol";
import {Staking} from "../src/Staking.sol";
import {MerkleDistributorEpoch} from "../src/MerkleDistributorEpoch.sol";

contract DeployGaslessStack is Script {
    function run() external {
        vm.startBroadcast();

        address deployer = msg.sender;

        // 1. Deploy the Forwarder (The "Trust Anchor")
        AIRProtocolForwarder forwarder = new AIRProtocolForwarder("AIRProtocolForwarder");
        address forwarderAddr = address(forwarder);
        console.log("Forwarder deployed at:", forwarderAddr);

        // 2. Deploy AIRToken (Trusts Forwarder)
        AIRToken token = new AIRToken(deployer, forwarderAddr);
        console.log("AIRToken deployed at:", address(token));

        // 3. Deploy Staking (Trusts Forwarder)
        Staking staking = new Staking(token, forwarderAddr);
        console.log("Staking deployed at:", address(staking));

        // 4. Deploy MerkleDistributor (Trusts Forwarder)
        MerkleDistributorEpoch distributor = new MerkleDistributorEpoch(token, deployer, forwarderAddr);
        console.log("MerkleDistributor deployed at:", address(distributor));

        vm.stopBroadcast();
    }
}
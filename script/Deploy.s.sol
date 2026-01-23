// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {AIRToken} from "../src/AIRToken.sol";
import {AIRProtocolCore} from "../src/AIRProtocolCore.sol";
import {ReportRegistry} from "../src/ReportRegistry.sol";
import {Staking} from "../src/Staking.sol";
import {TreasuryVault} from "../src/TreasuryVault.sol";
import {EmissionsController} from "../src/EmissionsController.sol";
import {MerkleDistributorEpoch} from "../src/MerkleDistributorEpoch.sol";
import {AIRProtocolForwarder} from "../src/AIRProtocolForwarder.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Deploy is Script {
    function run() external {
        // 1. Setup Environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        console.log("--- STARTING DEPLOYMENT ---");
        console.log("Deployer Address:", deployer);

        // 2. Deploy Trusted Forwarder
        AIRProtocolForwarder forwarder = new AIRProtocolForwarder("AIRProtocolForwarder");
        address fwd = address(forwarder);

        // 3. Deploy AIRToken
        AIRToken token = new AIRToken(deployer, fwd);

        // 4. Deploy Staking
        Staking staking = new Staking(IERC20(address(token)), fwd);

        // 5. Deploy Protocol Core & Report Registry
        AIRProtocolCore core = new AIRProtocolCore(deployer);
        ReportRegistry registry = new ReportRegistry(deployer, fwd);

        // 6. Deploy Treasury & Distribution Infrastructure
        TreasuryVault treasury = new TreasuryVault(IERC20(address(token)), deployer);
        
        MerkleDistributorEpoch distributor = new MerkleDistributorEpoch(
            IERC20(address(token)), 
            deployer, 
            fwd
        );

        uint256 initialWeeklyEmission = 1_000_000e18; 
        EmissionsController emissions = new EmissionsController(
            treasury,
            address(distributor),
            initialWeeklyEmission,
            deployer
        );

        // 7. Post-Deployment Configuration
        treasury.setEmissionsController(address(emissions));
        
        uint256 treasurySeed = 50_000_000e18; 
        token.transfer(address(treasury), treasurySeed);
        
        vm.stopBroadcast();

        // 8. Export to JSON
        string memory obj = "deployment_data";
        vm.serializeAddress(obj, "forwarder", address(forwarder));
        vm.serializeAddress(obj, "token", address(token));
        vm.serializeAddress(obj, "staking", address(staking));
        vm.serializeAddress(obj, "core", address(core));
        vm.serializeAddress(obj, "registry", address(registry));
        vm.serializeAddress(obj, "treasury", address(treasury));
        vm.serializeAddress(obj, "emissions", address(emissions));
        // The final call to serialize returns the full JSON string
        string memory finalJson = vm.serializeAddress(obj, "MerkleDistributor", address(distributor));

        // Write to file
        string memory path = string.concat(vm.projectRoot(), "/deployments.json");
        vm.writeFile(path, finalJson);

        // --- FINAL LOGS FOR FRONTEND/BACKEND ---
        console.log("----------------------------------------------");
        console.log("PROTOCOL DEPLOYMENT COMPLETE");
        console.log("----------------------------------------------");
        console.log("JSON saved to:     ", path);
        console.log("Forwarder:         ", address(forwarder));
        console.log("AIRToken:          ", address(token));
        console.log("Staking:           ", address(staking));
        console.log("ProtocolCore:      ", address(core));
        console.log("ReportRegistry:    ", address(registry));
        console.log("TreasuryVault:     ", address(treasury));
        console.log("EmissionsCtrl:     ", address(emissions));
        console.log("MerkleDistributor: ", address(distributor));
        console.log("----------------------------------------------");
        console.log("Treasury Seeded:   ", treasurySeed / 1e18, "AIR");
        console.log("Weekly Emission:   ", initialWeeklyEmission / 1e18, "AIR");
        console.log("----------------------------------------------");
    }
}
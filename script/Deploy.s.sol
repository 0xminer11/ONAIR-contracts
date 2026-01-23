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

        // 2. Deploy Trusted Forwarder (The "Trust Anchor" for gasless txs)
        AIRProtocolForwarder forwarder = new AIRProtocolForwarder("AIRProtocolForwarder");
        address fwd = address(forwarder);
        console.log("Forwarder deployed at:", fwd);

        // 3. Deploy AIRToken
        // Note: The constructor automatically mints MAX_SUPPLY (100B) to the initialOwner.
        AIRToken token = new AIRToken(deployer, fwd);
        console.log("AIRToken deployed at:", address(token));

        // 4. Deploy Staking (Gasless Enabled)
        // Uses 500 AIR as the MIN_ELIGIBLE_STAKE[cite: 95].
        Staking staking = new Staking(IERC20(address(token)), fwd);
        console.log("Staking deployed at:", address(staking));

        // 5. Deploy Protocol Core & Report Registry
        // AIRProtocolCore sets the deployer as the Genesis Validator[cite: 182, 183].
        AIRProtocolCore core = new AIRProtocolCore(deployer);
        ReportRegistry registry = new ReportRegistry(deployer, fwd);
        console.log("AIRProtocolCore deployed at:", address(core));
        console.log("ReportRegistry deployed at:", address(registry));

        // 6. Deploy Treasury & Distribution Infrastructure
        TreasuryVault treasury = new TreasuryVault(IERC20(address(token)), deployer);
        
        MerkleDistributorEpoch distributor = new MerkleDistributorEpoch(
            IERC20(address(token)), 
            deployer, 
            fwd
        );

        // Initial weekly emission set to 1,000,000 AIR
        uint256 initialWeeklyEmission = 1_000_000e18; 
        EmissionsController emissions = new EmissionsController(
            treasury,
            address(distributor),
            initialWeeklyEmission,
            deployer
        );

        // 7. Post-Deployment Configuration & Minting Logic
        // Authorize the EmissionsController to pull funds from the Treasury[cite: 113, 115].
        treasury.setEmissionsController(address(emissions));
        
        // Setup initial funding for the reward ecosystem
        // Since all tokens were minted to the deployer, we transfer them to the Treasury.
        uint256 treasurySeed = 50_000_000e18; // 50 Million AIR
        token.transfer(address(treasury), treasurySeed);
        
        console.log("TreasuryVault seeded with:", treasurySeed);
        console.log("EmissionsController authorized on Treasury");
        console.log("MerkleDistributor ready for epoch 1");

        vm.stopBroadcast();
    }
}
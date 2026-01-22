// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
// Adjust the import to match your actual contract name and path
import {EpochAirdrop} from "../src/EpochAirdrop.sol";

contract EpochAirdropTest is Test {
    EpochAirdrop public airdrop;
    address public owner;
    address public user;
    address public recipient;

    function setUp() public {
        owner = makeAddr("owner");
        user = makeAddr("user");
        recipient = makeAddr("recipient");

        // Deploy contract as owner
        vm.startPrank(owner);
        airdrop = new EpochAirdrop();
        vm.stopPrank();
    }

    // Fix: Unauthorized() error indicates missing prank(owner)
    function testCreateEpochUpdatesExisting() public {
        vm.startPrank(owner);
        airdrop.createEpoch(1, 1000);
        // Update existing
        airdrop.createEpoch(1, 2000);
        vm.stopPrank();
    }

    function testDistributeEpochRevertsOnAlreadyDistributed() public {
        vm.startPrank(owner);
        airdrop.createEpoch(1, 1000);
        airdrop.distributeEpoch(1, recipient, 1000);

        vm.expectRevert(); // Expect revert on second distribution
        airdrop.distributeEpoch(1, recipient, 1000);
        vm.stopPrank();
    }

    function testDistributeEpochRevertsOnExceedingAllocation() public {
        vm.startPrank(owner);
        airdrop.createEpoch(1, 1000);

        vm.expectRevert(); // Expect revert when exceeding allocation
        airdrop.distributeEpoch(1, recipient, 1001);
        vm.stopPrank();
    }

    function testDistributeEpochRevertsOnZeroAddressRecipient() public {
        vm.startPrank(owner);
        airdrop.createEpoch(1, 1000);

        vm.expectRevert(); // Expect revert for zero address
        airdrop.distributeEpoch(1, address(0), 1000);
        vm.stopPrank();
    }

    // --- Negative Tests (Access Control & Logic) ---

    function test_RevertWhen_CallerNotOwner_CreateEpoch() public {
        vm.startPrank(user);
        vm.expectRevert(); // Should revert with Unauthorized
        airdrop.createEpoch(1, 1000);
        vm.stopPrank();
    }

    function test_RevertWhen_CallerNotOwner_DistributeEpoch() public {
        // Setup as owner
        vm.prank(owner);
        airdrop.createEpoch(1, 1000);

        // Attempt distribute as user
        vm.startPrank(user);
        vm.expectRevert(); // Should revert with Unauthorized
        airdrop.distributeEpoch(1, recipient, 1000);
        vm.stopPrank();
    }

    function test_RevertWhen_InvalidEpochId() public {
        vm.startPrank(owner);
        
        // Try to distribute for an epoch that hasn't been created
        vm.expectRevert();
        airdrop.distributeEpoch(999, recipient, 100);
        
        vm.stopPrank();
    }
}
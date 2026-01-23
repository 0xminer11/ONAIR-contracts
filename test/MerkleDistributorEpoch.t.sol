// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MerkleDistributorEpoch.sol";
import "../src/AIRToken.sol";

contract MerkleDistributorEpochTest is Test {
    MerkleDistributorEpoch distributor;
    AIRToken token;
    address forwarder = address(0x1234); // Simulated Trusted Forwarder
    address user = address(0xABCD);
    address relayer = address(0x9999);

    function setUp() public {
        token = new AIRToken(address(this), address(0));
        distributor = new MerkleDistributorEpoch(token, address(this), forwarder);
        token.transfer(address(distributor), 1000e18);
    }

    function testGaslessClaim() public {
        uint256 epochId = 1;
        uint256 index = 0;
        uint256 amount = 100e18;

        // 1. Generate a mock root for the user
        bytes32 leaf = keccak256(abi.encodePacked(index, user, amount));
        bytes32[] memory proof = new bytes32[](0); // Simple case: 1 leaf
        distributor.setMerkleRoot(epochId, leaf);

        // 2. Simulate a Relayer calling via the Trusted Forwarder
        // EIP-2771 works by appending the 'from' address (20 bytes) to the calldata
        bytes memory baseCall = abi.encodeWithSelector(
            distributor.claim.selector, 
            epochId, index, user, amount, proof
        );
        bytes memory gaslessCall = abi.encodePacked(baseCall, user);

        // 3. Prank as the relayer calling the distributor
        vm.prank(forwarder); 
        (bool success, ) = address(distributor).call(gaslessCall);
        
        assertTrue(success, "Gasless claim failed");
        assertEq(token.balanceOf(user), amount);
        assertTrue(distributor.isClaimed(epochId, index));
    }

    function testFailGaslessClaimUntrustedForwarder() public {
        // If a random address (not the forwarder) tries to use the same trick, 
        // _msgSender() will return the random address, not the appended one.
        vm.prank(relayer);
        distributor.claim(1, 0, user, 100e18, new bytes32[](0));
    }
}
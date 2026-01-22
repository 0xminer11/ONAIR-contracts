// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MerkleDistributorEpoch.sol";
import "../src/AIRToken.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MerkleDistributorEpochTest is Test {
    MerkleDistributorEpoch distributor;
    AIRToken air;

    address owner = address(0xA11CE);
    address user1 = address(0xBEEF);
    address user2 = address(0xCAFE);

    uint256 epoch = 1;

    bytes32 leaf1;
    bytes32 leaf2;
    bytes32 root;

    bytes32[] proof_user1;
    bytes32[] proof_user2;

    function setUp() public {
        air = new AIRToken(owner, address(0));

        vm.prank(owner);
        distributor = new MerkleDistributorEpoch(IERC20(address(air)), owner);

        vm.prank(owner);
        air.transfer(address(distributor), 1_000_000e18);

        // ---------------------------------------------
        // Build Merkle tree manually (2-leaf tree)
        // ---------------------------------------------
        leaf1 = keccak256(abi.encodePacked(uint256(0), user1, uint256(100e18)));
        leaf2 = keccak256(abi.encodePacked(uint256(1), user2, uint256(200e18)));

        if (leaf1 < leaf2) {
            root = keccak256(abi.encodePacked(leaf1, leaf2));

            proof_user1 = new bytes32[](1);
            proof_user1[0] = leaf2;

            proof_user2 = new bytes32[](1);
            proof_user2[0] = leaf1;

        } else {
            root = keccak256(abi.encodePacked(leaf2, leaf1));

            proof_user1 = new bytes32[](1);
            proof_user1[0] = leaf2;

            proof_user2 = new bytes32[](1);
            proof_user2[0] = leaf1;
        }

        vm.prank(owner);
        distributor.setMerkleRoot(epoch, root);
    }

    // ------------------------------------------------------------
    // ROOT TESTS
    // ------------------------------------------------------------

    function testRootCannotBeSetTwice() public {
        vm.prank(owner);
        vm.expectRevert(MerkleDistributorEpoch.RootAlreadySet.selector);
        distributor.setMerkleRoot(epoch, root);
    }

    function testOnlyOwnerCanSetRoot() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(this)));
        distributor.setMerkleRoot(88, root);
    }

    // ------------------------------------------------------------
    // CLAIM TESTS
    // ------------------------------------------------------------

    function testClaimUser1() public {
        vm.prank(user1);

        distributor.claim(
            epoch,
            0,
            user1,
            100e18,
            proof_user1
        );

        assertEq(air.balanceOf(user1), 100e18);
        assertTrue(distributor.isClaimed(epoch, 0));
    }

    function testClaimUser2() public {
        vm.prank(user2);

        distributor.claim(
            epoch,
            1,
            user2,
            200e18,
            proof_user2
        );

        assertEq(air.balanceOf(user2), 200e18);
        assertTrue(distributor.isClaimed(epoch, 1));
    }

    function testCannotClaimTwice() public {
        vm.startPrank(user1);

        distributor.claim(epoch, 0, user1, 100e18, proof_user1);

        vm.expectRevert(MerkleDistributorEpoch.AlreadyClaimed.selector);
        distributor.claim(epoch, 0, user1, 100e18, proof_user1);

        vm.stopPrank();
    }

    function testInvalidProofFails() public {
        bytes32[] memory fakeProof = new bytes32[](1);
        fakeProof[0] = keccak256("wrong");

        vm.prank(user1);
        vm.expectRevert(MerkleDistributorEpoch.InvalidProof.selector);
        distributor.claim(epoch, 0, user1, 100e18, fakeProof);
    }

    function testEpochNotSetFails() public {
        uint256 newEpoch = 999;
        bytes32[] memory empty;

        vm.prank(user1);
        vm.expectRevert(MerkleDistributorEpoch.InvalidProof.selector);
        distributor.claim(newEpoch, 0, user1, 100e18, empty);
    }

    // ------------------------------------------------------------
    // MULTI-EPOCH TESTS
    // ------------------------------------------------------------

    function testMultipleEpochsAreSeparated() public {
        uint256 epoch2 = 2;

        bytes32 leaf = keccak256(abi.encodePacked(uint256(0), user1, uint256(500e18)));

        vm.prank(owner);
        distributor.setMerkleRoot(epoch2, leaf);

        vm.prank(user1);
        distributor.claim(epoch2, 0, user1, 500e18, new bytes32[](0));

        assertEq(air.balanceOf(user1), 500e18);
    }

    // ------------------------------------------------------------
    // EDGE CASES
    // ------------------------------------------------------------

    function testZeroAmountClaimStillWorks() public {
        uint256 epoch3 = 3;
        bytes32 leafZero = keccak256(abi.encodePacked(uint256(0), user1, uint256(0)));

        vm.prank(owner);
        distributor.setMerkleRoot(epoch3, leafZero);

        vm.prank(user1);
        distributor.claim(epoch3, 0, user1, 0, new bytes32[](0));

        assertEq(air.balanceOf(user1), 0);
    }
}

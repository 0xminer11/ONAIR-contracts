// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/AIRProtocolCore.sol";

contract AIRProtocolCoreTest is Test {
    AIRProtocolCore core;
    address validator = address(111);

    function setUp() public {
        core = new AIRProtocolCore(validator);
    }

    function testCommitStory() public {
        bytes32 storyId = keccak256("story1");
        bytes32[] memory claims = new bytes32[](2);
        claims[0] = keccak256("claim1");
        claims[1] = keccak256("claim2");

        vm.prank(validator);
        core.commitStory(
            storyId,
            claims,
            keccak256("prov"),
            9000,
            50,
            20,
            1
        );

        assertTrue(core.exists(storyId));

        (
            AIRProtocolCore.StoryHeader memory header,
            bytes32[] memory claimHashes,
            bytes32 provHash
        ) = core.getStory(storyId);

        assertEq(header.overallTrustScore, 9000);
        assertEq(provHash, keccak256("prov"));
        assertEq(claimHashes.length, 2);
    }

    function testCommitRevertsForNonValidator() public {
        bytes32 storyId = keccak256("story2");
        bytes32 [] memory claims = new bytes32[](1);
        claims[0] = keccak256("claim1");

        vm.expectRevert(AIRProtocolCore.NotValidator.selector);
        core.commitStory(
            storyId,
            claims,
            keccak256("prov"),
            8000,
            30,
            10,
            1
        );
    }

    function testCommitRevertsIfDuplicate() public {
        bytes32 storyId = keccak256("story3");
        bytes32 [] memory claims = new bytes32[](1);
        claims[0] = keccak256("claim1");

        vm.startPrank(validator);
        core.commitStory(storyId, claims, keccak256("prov"), 10000, 100, 100, 1);

        vm.expectRevert(AIRProtocolCore.StoryAlreadyCommitted.selector);
        core.commitStory(storyId, claims, keccak256("prov"), 10000, 100, 100, 1);
    }
}

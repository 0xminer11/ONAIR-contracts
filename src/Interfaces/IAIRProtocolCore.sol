// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IAIRProtocolCore {
    struct StoryHeader {
        uint64 overallTrustScore;
        uint32 confidenceIndex;
        uint32 biasIndex;
        uint8  protocolVersion;
        uint64 blockTimestamp;
        address validator;
    }

    function getStory(bytes32 storyId)
        external
        view
        returns (
            StoryHeader memory header,
            bytes32[] memory claimHashes,
            bytes32 provenanceHash
        );

    function exists(bytes32 storyId) external view returns (bool);

    function commitStory(
        bytes32 storyId,
        bytes32[] calldata claimHashes,
        bytes32 provenanceHash,
        uint64 overallTrustScore,
        uint32 confidenceIndex,
        uint32 biasIndex,
        uint8 protocolVersion
    ) external;
}

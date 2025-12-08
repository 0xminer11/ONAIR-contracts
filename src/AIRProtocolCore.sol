// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title AIRProtocolCore
/// @notice On-chain truth ledger for AIR Protocol Phase 1 (Genesis Validator PoA).
contract AIRProtocolCore {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error NotValidator();
    error StoryAlreadyCommitted();
    error ZeroStoryId();
    error EmptyClaimsArray();

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event StoryCommitted(
        bytes32 indexed storyId,
        uint64 overallTrustScore,
        uint32 confidenceIndex,
        uint32 biasIndex,
        uint8 protocolVersion,
        address indexed validator,
        uint64 blockTimestamp
    );

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Genesis validator address for Phase 1 (PoA).
    address public immutable genesisValidator;

    struct StoryHeader {
        uint64 overallTrustScore; // e.g. 0–10000 (basis points)
        uint32 confidenceIndex;   // optional
        uint32 biasIndex;         // optional
        uint8  protocolVersion;   // version of scoring algorithm
        uint64 blockTimestamp;    // when committed
        address validator;        // who committed
    }

    struct StoryData {
        StoryHeader header;
        bytes32[] claimHashes; // hashes of claims for this story
        bytes32 provenanceHash; // optional combined provenance (sourceURL, metadata hash, etc.)
    }

    // storyId => StoryData
    mapping(bytes32 => StoryData) private _stories;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _genesisValidator) {
        if (_genesisValidator == address(0)) revert NotValidator();
        genesisValidator = _genesisValidator;
    }

    /*//////////////////////////////////////////////////////////////
                                 MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyValidator() {
        if (msg.sender != genesisValidator) revert NotValidator();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                  VIEWS
    //////////////////////////////////////////////////////////////*/

    function getStory(bytes32 storyId)
        external
        view
        returns (
            StoryHeader memory header,
            bytes32[] memory claimHashes,
            bytes32 provenanceHash
        )
    {
        StoryData storage s = _stories[storyId];
        return (s.header, s.claimHashes, s.provenanceHash);
    }

    function exists(bytes32 storyId) external view returns (bool) {
        return _stories[storyId].header.blockTimestamp != 0;
    }

    /*//////////////////////////////////////////////////////////////
                                  LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Commit a story's trust data to chain.
    /// @dev Called only by the Genesis Validator service in Phase 1.
    function commitStory(
        bytes32 storyId,
        bytes32[] calldata claimHashes,
        bytes32 provenanceHash,
        uint64 overallTrustScore,
        uint32 confidenceIndex,
        uint32 biasIndex,
        uint8 protocolVersion
    ) external onlyValidator {
        if (storyId == bytes32(0)) revert ZeroStoryId();
        if (_stories[storyId].header.blockTimestamp != 0) revert StoryAlreadyCommitted();
        if (claimHashes.length == 0) revert EmptyClaimsArray();

        StoryData storage s = _stories[storyId];

        // Store header (packed)
        s.header = StoryHeader({
            overallTrustScore: overallTrustScore,
            confidenceIndex: confidenceIndex,
            biasIndex: biasIndex,
            protocolVersion: protocolVersion,
            blockTimestamp: uint64(block.timestamp),
            validator: msg.sender
        });

        // Copy claim hashes
        uint256 len = claimHashes.length;
        s.claimHashes = new bytes32[](len);
        for (uint256 i; i < len; ) {
            s.claimHashes[i] = claimHashes[i];
            unchecked {
                ++i;
            }
        }

        s.provenanceHash = provenanceHash;

        emit StoryCommitted(
            storyId,
            overallTrustScore,
            confidenceIndex,
            biasIndex,
            protocolVersion,
            msg.sender,
            uint64(block.timestamp)
        );
    }
}

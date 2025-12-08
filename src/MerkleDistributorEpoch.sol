// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @title MerkleDistributorEpoch
/// @notice Epoch-based Merkle distributor for AIR rewards.
contract MerkleDistributorEpoch is Ownable {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error ZeroAddress();
    error RootAlreadySet();
    error InvalidProof();
    error AlreadyClaimed();
    error TransferFailed();

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event MerkleRootSet(uint256 indexed epochId, bytes32 merkleRoot);
    event Claimed(uint256 indexed epochId, uint256 indexed index, address indexed account, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                               STORAGE
    //////////////////////////////////////////////////////////////*/

    IERC20 public immutable AIR;

    // epochId => merkle root
    mapping(uint256 => bytes32) public merkleRoots;

    // epochId => bitmap word => claimed bits
    mapping(uint256 => mapping(uint256 => uint256)) private claimedBitMap;

    constructor(IERC20 air, address owner_) Ownable(owner_) {
        if (address(air) == address(0)) revert ZeroAddress();
        AIR = air;
    }

    /*//////////////////////////////////////////////////////////////
                               BITMAP HELPERS
    //////////////////////////////////////////////////////////////*/

    function _isClaimed(uint256 epochId, uint256 index) internal view returns (bool) {
        uint256 wordIndex = index >> 8; // index / 256
        uint256 bitIndex = index & 255; // index % 256
        uint256 word = claimedBitMap[epochId][wordIndex];
        uint256 mask = 1 << bitIndex;
        return word & mask == mask;
    }

    function _setClaimed(uint256 epochId, uint256 index) internal {
        uint256 wordIndex = index >> 8;
        uint256 bitIndex = index & 255;
        uint256 word = claimedBitMap[epochId][wordIndex];
        uint256 mask = 1 << bitIndex;
        claimedBitMap[epochId][wordIndex] = word | mask;
    }

    function isClaimed(uint256 epochId, uint256 index) external view returns (bool) {
        return _isClaimed(epochId, index);
    }

    /*//////////////////////////////////////////////////////////////
                             ROOT MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @notice Set Merkle root for an epoch; can only be set once.
    function setMerkleRoot(uint256 epochId, bytes32 merkleRoot) external onlyOwner {
        if (merkleRoots[epochId] != bytes32(0)) revert RootAlreadySet();
        merkleRoots[epochId] = merkleRoot;
        emit MerkleRootSet(epochId, merkleRoot);
    }

    /*//////////////////////////////////////////////////////////////
                                 CLAIM
    //////////////////////////////////////////////////////////////*/

    /// @notice Claim airdropped tokens for a given epoch.
    function claim(
        uint256 epochId,
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external {
        if (_isClaimed(epochId, index)) revert AlreadyClaimed();

        bytes32 root = merkleRoots[epochId];
        if (root == bytes32(0)) revert InvalidProof(); // epoch not initialized

        // Compute leaf
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));

        // Verify proof
        if (!MerkleProof.verify(merkleProof, root, node)) {
            revert InvalidProof();
        }

        _setClaimed(epochId, index);

        bool ok = AIR.transfer(account, amount);
        if (!ok) revert TransferFailed();

        emit Claimed(epochId, index, account, amount);
    }
}

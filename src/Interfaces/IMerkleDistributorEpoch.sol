// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IMerkleDistributorEpoch {
    function merkleRoots(uint256 epochId) external view returns (bytes32);
    function isClaimed(uint256 epochId, uint256 index) external view returns (bool);

    function setMerkleRoot(uint256 epochId, bytes32 merkleRoot) external;

    function claim(
        uint256 epochId,
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external;
}

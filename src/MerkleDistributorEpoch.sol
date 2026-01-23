// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
// 1. Import ERC2771Context
import {ERC2771Context, Context} from "@openzeppelin/contracts/metatx/ERC2771Context.sol";

/// @title MerkleDistributorEpoch
/// @notice Now supports gasless claims via EIP-2771
contract MerkleDistributorEpoch is Ownable, ERC2771Context {
    error ZeroAddress();
    error RootAlreadySet();
    error InvalidProof();
    error AlreadyClaimed();
    error TransferFailed();

    event MerkleRootSet(uint256 indexed epochId, bytes32 merkleRoot);
    event Claimed(uint256 indexed epochId, uint256 indexed index, address indexed account, uint256 amount);

    IERC20 public immutable AIR;
    mapping(uint256 => bytes32) public merkleRoots;
    mapping(uint256 => mapping(uint256 => uint256)) private claimedBitMap;

    // 2. Initialize ERC2771Context with the trustedForwarder address
    constructor(IERC20 air, address owner_, address trustedForwarder) 
        Ownable(owner_) 
        ERC2771Context(trustedForwarder) 
    {
        if (address(air) == address(0)) revert ZeroAddress();
        AIR = air;
    }

    function _isClaimed(uint256 epochId, uint256 index) internal view returns (bool) {
        uint256 wordIndex = index >> 8;
        uint256 bitIndex = index & 255;
        uint256 word = claimedBitMap[epochId][wordIndex];
        uint256 mask = 1 << bitIndex;
        return word & mask == mask;
    }

    function _setClaimed(uint256 epochId, uint256 index) internal {
        uint256 wordIndex = index >> 8;
        uint256 bitIndex = index & 255;
        claimedBitMap[epochId][wordIndex] |= (1 << bitIndex);
    }

    function isClaimed(uint256 epochId, uint256 index) external view returns (bool) {
        return _isClaimed(epochId, index);
    }

    function setMerkleRoot(uint256 epochId, bytes32 merkleRoot) external onlyOwner {
        if (merkleRoots[epochId] != bytes32(0)) revert RootAlreadySet();
        merkleRoots[epochId] = merkleRoot;
        emit MerkleRootSet(epochId, merkleRoot);
    }

    /// @notice Claim tokens. Gas can be paid by a relayer if called via Trusted Forwarder.
    function claim(
        uint256 epochId,
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external {
        // 3. SECUIRTY: In a gasless model, ensure 'account' matches the original signer
        // This prevents relayers from claiming on behalf of users they don't have signatures for.
        if (account != _msgSender()) revert InvalidProof(); 

        if (_isClaimed(epochId, index)) revert AlreadyClaimed();
        bytes32 root = merkleRoots[epochId];
        if (root == bytes32(0)) revert InvalidProof();

        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        if (!MerkleProof.verify(merkleProof, root, node)) revert InvalidProof();

        _setClaimed(epochId, index);

        bool ok = AIR.transfer(account, amount);
        if (!ok) revert TransferFailed();

        emit Claimed(epochId, index, account, amount);
    }

    // 4. Overrides required by Solidity when inheriting from both Context and ERC2771Context
    function _msgSender() internal view virtual override(Context, ERC2771Context) returns (address) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }

    function _contextSuffixLength() internal view virtual override(Context, ERC2771Context) returns (uint256) {
        return ERC2771Context._contextSuffixLength();
    }
}
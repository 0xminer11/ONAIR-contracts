// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {TreasuryVault} from "./TreasuryVault.sol";

/// @title EmissionsController
/// @notice Streams AIR from TreasuryVault to MerkleDistributor for each epoch.
contract EmissionsController is Ownable {
    error AlreadyFunded();
    error ZeroAddress();

    event WeeklyEmissionUpdated(uint256 newAmount);
    event EpochFunded(uint256 indexed epochId, uint256 amount);

    TreasuryVault public immutable treasuryVault;
    address public immutable merkleDistributor;
    uint256 public weeklyEmission;

    mapping(uint256 => bool) public epochFunded;

    constructor(
        TreasuryVault _treasuryVault,
        address _merkleDistributor,
        uint256 _initialWeeklyEmission,
        address _owner
    ) Ownable(_owner) {
        if (address(_treasuryVault) == address(0)) revert ZeroAddress();
        if (_merkleDistributor == address(0)) revert ZeroAddress();

        treasuryVault = _treasuryVault;
        merkleDistributor = _merkleDistributor;
        weeklyEmission = _initialWeeklyEmission;
    }

    function setWeeklyEmission(uint256 newAmount) external onlyOwner {
        weeklyEmission = newAmount;
        emit WeeklyEmissionUpdated(newAmount);
    }

    /// @notice Funds epoch once, pulling from TreasuryVault to MerkleDistributor.
    function fundEpoch(uint256 epochId) external onlyOwner {
        if (epochFunded[epochId]) revert AlreadyFunded();
        epochFunded[epochId] = true;

        treasuryVault.pullTo(merkleDistributor, weeklyEmission);

        emit EpochFunded(epochId, weeklyEmission);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IEmissionsController {
    function weeklyEmission() external view returns (uint256);
    function epochFunded(uint256 epochId) external view returns (bool);
    function fundEpoch(uint256 epochId) external;
    function setWeeklyEmission(uint256 newAmount) external;
}

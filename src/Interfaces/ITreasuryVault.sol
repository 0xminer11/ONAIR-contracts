// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITreasuryVault {
    function emissionsController() external view returns (address);
    function pullTo(address to, uint256 amount) external;
}

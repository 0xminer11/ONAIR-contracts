// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IStaking {
    function stake(uint256 amount) external;
    function unstake(uint256 amount) external;
    function stakedBalanceOf(address user) external view returns (uint256);
    function isEligible(address user) external view returns (bool);
    function totalStaked() external view returns (uint256);
}

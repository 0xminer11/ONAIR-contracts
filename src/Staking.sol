// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title SimpleStaking
/// @notice Minimal staking contract used as anti-farm gate for AIR rewards.
contract Staking is ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error ZeroAddress();
    error ZeroAmount();
    error InsufficientStake();
    error TransferFailed();

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    IERC20 public immutable AIR;
    /// @notice Minimum stake to be eligible: 500 AIR
    uint256 public constant MIN_ELIGIBLE_STAKE = 500e18;

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => uint256) private _stakedBalance;
    uint256 public totalStaked;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(IERC20 air) {
        if (address(air) == address(0)) revert ZeroAddress();
        AIR = air;
    }

    /*//////////////////////////////////////////////////////////////
                                 VIEWS
    //////////////////////////////////////////////////////////////*/

    function stakedBalanceOf(address user) external view returns (uint256) {
        return _stakedBalance[user];
    }

    function isEligible(address user) external view returns (bool) {
        return _stakedBalance[user] >= MIN_ELIGIBLE_STAKE;
    }

    /*//////////////////////////////////////////////////////////////
                                 LOGIC
    //////////////////////////////////////////////////////////////*/

    function stake(uint256 amount) external nonReentrant {
        if (amount == 0) revert ZeroAmount();

        // Effects
        _stakedBalance[msg.sender] += amount;
        totalStaked += amount;

        // Interactions
        bool ok = AIR.transferFrom(msg.sender, address(this), amount);
        if (!ok) revert TransferFailed();

        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) external nonReentrant {
        if (amount == 0) revert ZeroAmount();

        uint256 prevBal = _stakedBalance[msg.sender];
        if (prevBal < amount) revert InsufficientStake();

        // Effects
        unchecked {
            _stakedBalance[msg.sender] = prevBal - amount;
            totalStaked -= amount;
        }

        // Interactions
        bool ok = AIR.transfer(msg.sender, amount);
        if (!ok) revert TransferFailed();

        emit Unstaked(msg.sender, amount);
    }
}

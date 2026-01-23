// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
// Ensure both are imported
import {ERC2771Context, Context} from "@openzeppelin/contracts/metatx/ERC2771Context.sol";

// FIX: Add Context to the inheritance list
contract Staking is ReentrancyGuard, Context, ERC2771Context {
    error ZeroAddress();
    error ZeroAmount();
    error InsufficientStake();
    error TransferFailed();

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);

    IERC20 public immutable air;
    uint256 public constant MIN_ELIGIBLE_STAKE = 500e18;
    mapping(address => uint256) private _stakedBalance;
    uint256 public totalStaked;

    constructor(IERC20 _air, address trustedForwarder) 
        ERC2771Context(trustedForwarder) 
    {
        if (address(_air) == address(0)) revert ZeroAddress();
        air = _air;
    }

    function stakedBalanceOf(address user) external view returns (uint256) {
        return _stakedBalance[user];
    }

    function isEligible(address user) external view returns (bool) {
        return _stakedBalance[user] >= MIN_ELIGIBLE_STAKE;
    }

    function stake(uint256 amount) external nonReentrant {
        if (amount == 0) revert ZeroAmount();
        address sender = _msgSender();
        
        _stakedBalance[sender] += amount;
        totalStaked += amount;

        bool ok = air.transferFrom(sender, address(this), amount);
        if (!ok) revert TransferFailed();

        emit Staked(sender, amount);
    }

    function unstake(uint256 amount) external nonReentrant {
        if (amount == 0) revert ZeroAmount();
        address sender = _msgSender();
        
        uint256 prevBal = _stakedBalance[sender];
        if (prevBal < amount) revert InsufficientStake();

        unchecked {
            _stakedBalance[sender] = prevBal - amount;
            totalStaked -= amount;
        }

        bool ok = air.transfer(sender, amount);
        if (!ok) revert TransferFailed();

        emit Unstaked(sender, amount);
    }

    // These overrides will now work because Context is in the 'is' list
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
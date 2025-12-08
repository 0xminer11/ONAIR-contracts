// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title AIR Token
/// @notice Core ERC20 token for staking, rewards, and future governance.
contract AIRToken is ERC20, ERC20Permit, Ownable {
    /// @dev Total supply: 100,000,000,000 * 1e18
    uint256 public constant MAX_SUPPLY = 100_000_000_000e18;

    constructor(address initialOwner)
        ERC20("AIR Protocol", "AIR")
        ERC20Permit("AIR Protocol")
        Ownable(initialOwner)
    {
        _mint(initialOwner, MAX_SUPPLY);
    }
}

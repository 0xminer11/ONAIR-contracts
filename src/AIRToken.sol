// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC2771Context} from "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/// @title AIR Token
/// @notice Core ERC20 token for staking, rewards, and future governance.
contract AIRToken is ERC20Permit, Ownable, ERC2771Context {
    /// @dev Total supply: 100,000,000,000 * 1e18
    uint256 public constant MAX_SUPPLY = 100_000_000_000e18;

    constructor(address initialOwner, address trustedForwarder)
        ERC20("AIR Protocol", "AIR")
        ERC20Permit("AIR Protocol")
        ERC2771Context(trustedForwarder)
        Ownable(initialOwner)
    {
        _mint(initialOwner, MAX_SUPPLY);
    }

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

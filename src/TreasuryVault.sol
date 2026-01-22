// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title TreasuryVault
/// @notice Holds AIR used for emissions and other protocol purposes.
contract TreasuryVault is Ownable {
    error ZeroAddress();
    error NotAuthorized();
    error TransferFailed();

    event EmissionsControllerUpdated(address indexed controller);
    event TokensPulled(address indexed to, uint256 amount);

    IERC20 public immutable air;
    address public emissionsController;

    constructor(IERC20 _air, address initialOwner) Ownable(initialOwner) {
        if (address(_air) == address(0)) revert ZeroAddress();
        air = _air;
    }

    function setEmissionsController(address controller) external onlyOwner {
        if (controller == address(0)) revert ZeroAddress();
        emissionsController = controller;
        emit EmissionsControllerUpdated(controller);
    }

    /// @notice Called by EmissionsController to fund MerkleDistributor.
    function pullTo(address to, uint256 amount) external {
        if (msg.sender != emissionsController) revert NotAuthorized();
        emit TokensPulled(to, amount);
        bool ok = air.transfer(to, amount);
        if (!ok) revert TransferFailed();
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title AirdropController
/// @notice Batch-based push airdrop contract for AIR tokens with admin and co-admins
contract AirdropController is AccessControl {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error ZeroAddress();
    error Unauthorized();
    error LengthMismatch();
    error AlreadyDistributed();
    error InsufficientBalance();
    error TransferFailed();

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event CoAdminAdded(address indexed coAdmin);
    event CoAdminRemoved(address indexed coAdmin);
    event BatchCreated(uint256 indexed batchId, uint256 totalAllocation);
    event RecipientAirdropped(uint256 indexed batchId, address indexed recipient, uint256 amount);
    event BatchDistributed(uint256 indexed batchId, uint256 totalAmount);
    event TokensWithdrawn(address indexed token, address indexed to, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                               STORAGE
    //////////////////////////////////////////////////////////////*/

    IERC20 public immutable AIR;

    bytes32 public constant COADMIN_ROLE = keccak256("COADMIN_ROLE");

    // co-admins
    mapping(address => bool) public coAdmins;

    // batchId => recipient => distributed
    mapping(uint256 => mapping(address => bool)) private isDistributedInBatch;

    // batch data
    struct Batch {
        uint256 totalAllocation; // optional cap for the batch; 0 means unlimited
        uint256 distributedAmount;
        bool exists;
    }

    mapping(uint256 => Batch) public batches;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(IERC20 air, address admin_) {
        if (address(air) == address(0) || admin_ == address(0)) revert ZeroAddress();
        AIR = air;
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _setRoleAdmin(COADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    }

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyAdminOrCoAdmin() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender) && !hasRole(COADMIN_ROLE, msg.sender)) revert Unauthorized();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                             ADMIN MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    function addCoAdmin(address coAdmin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (coAdmin == address(0)) revert ZeroAddress();
        grantRole(COADMIN_ROLE, coAdmin);
        emit CoAdminAdded(coAdmin);
    }

    function removeCoAdmin(address coAdmin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(COADMIN_ROLE, coAdmin);
        emit CoAdminRemoved(coAdmin);
    }

    /*//////////////////////////////////////////////////////////////
                               BATCHES
    //////////////////////////////////////////////////////////////*/

    /// @notice Create a distribution batch with an optional allocation cap (0 = unlimited)
    function createBatch(uint256 batchId, uint256 totalAllocation) external onlyAdminOrCoAdmin {
        Batch storage b = batches[batchId];
        if (!b.exists) {
            b.exists = true;
            b.totalAllocation = totalAllocation;
            emit BatchCreated(batchId, totalAllocation);
        } else {
            b.totalAllocation = totalAllocation; // allow updating cap
        }
    }

    /*//////////////////////////////////////////////////////////////
                               FUNDING
    //////////////////////////////////////////////////////////////*/

    /// @notice Fund contract by transferring AIR from caller (caller must approve first)
    function fund(uint256 amount) external onlyAdminOrCoAdmin {
        if (amount == 0) revert ZeroAddress();
        AIR.safeTransferFrom(msg.sender, address(this), amount);
    }

    /*//////////////////////////////////////////////////////////////
                             DISTRIBUTION
    //////////////////////////////////////////////////////////////*/

    /// @notice Distribute AIR tokens to recipients for a given batch (push transfers)
    function distributeBatch(
        uint256 batchId,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external onlyAdminOrCoAdmin {
        uint256 len = recipients.length;
        if (len != amounts.length) revert LengthMismatch();
        if (len == 0) return;

        // compute total required
        uint256 totalBatch = 0;
        for (uint256 i = 0; i < len; ) {
            totalBatch += amounts[i];
            unchecked { ++i; }
        }

        uint256 bal = AIR.balanceOf(address(this));
        if (bal < totalBatch) revert InsufficientBalance();

        Batch storage b = batches[batchId];
        if (!b.exists) {
            b.exists = true;
            emit BatchCreated(batchId, 0); // Create with 0 allocation if not exists
        }

        // if totalAllocation set, ensure not exceeding
        if (b.totalAllocation != 0) {
            if (b.distributedAmount + totalBatch > b.totalAllocation) revert InsufficientBalance();
        }

        // perform distribution (checks-effects-interactions)
        for (uint256 i = 0; i < len; ) {
            address to = recipients[i];
            uint256 amt = amounts[i];

            if (to == address(0)) revert ZeroAddress();
            if (isDistributedInBatch[batchId][to]) revert AlreadyDistributed();

            // mark distributed before transfer
            isDistributedInBatch[batchId][to] = true;

            // transfer
            AIR.safeTransfer(to, amt);
            emit RecipientAirdropped(batchId, to, amt);

            unchecked {
                ++i;
                b.distributedAmount += amt;
            }
        }

        emit BatchDistributed(batchId, totalBatch);
    }

    /*//////////////////////////////////////////////////////////////
                               ADMIN UTILITIES
    //////////////////////////////////////////////////////////////*/

    /// @notice Withdraw arbitrary token from contract (only owner)
    function withdrawUnallocated(IERC20 token, uint256 amount, address to) external onlyAdminOrCoAdmin {
        if (to == address(0)) revert ZeroAddress();
        token.safeTransfer(to, amount);
        emit TokensWithdrawn(address(token), to, amount);
    }

    /// @notice Emergency withdraw all AIR to `to` (only owner)
    function emergencyWithdraw(address to) external onlyAdminOrCoAdmin {
        if (to == address(0)) revert ZeroAddress();
        uint256 bal = AIR.balanceOf(address(this));
        AIR.safeTransfer(to, bal);
        emit TokensWithdrawn(address(AIR), to, bal);
    }

    /*//////////////////////////////////////////////////////////////
                                 VIEWS
    //////////////////////////////////////////////////////////////*/

    function isDistributed(uint256 batchId, address recipient) external view returns (bool) {
        return isDistributedInBatch[batchId][recipient];
    }

    function batchDistributedAmount(uint256 batchId) external view returns (uint256) {
        return batches[batchId].distributedAmount;
    }

    function contractBalance() external view returns (uint256) {
        return AIR.balanceOf(address(this));
    }
}

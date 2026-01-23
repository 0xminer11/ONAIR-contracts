// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC2771Forwarder} from "@openzeppelin/contracts/metatx/ERC2771Forwarder.sol";

/**
 * @title AIRProtocolForwarder
 * @notice Standard EIP-2771 Forwarder for gasless transactions.
 */
contract AIRProtocolForwarder is ERC2771Forwarder {
    // The "name" is used in the EIP-712 domain separator (e.g., "AIRProtocolForwarder")
    constructor(string memory name) ERC2771Forwarder(name) {}
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

contract ForwarderSimTest is Test {
    address constant FORWARDER = address(0x1234);
    address constant USER = address(0xABCD);

    function testSimulateForwarderCall(address targetContract, bytes memory functionalCall) public {
        // 1. A forwarder takes the user's signed intent
        // 2. It appends the USER address (20 bytes) to the end of the calldata
        bytes memory dataWithUser = abi.encodePacked(functionalCall, USER);

        // 3. The recipient contract must trust FORWARDER
        vm.prank(FORWARDER);
        (bool success, ) = targetContract.call(dataWithUser);
        
        assertTrue(success, "Gasless call simulation failed");
    }
}
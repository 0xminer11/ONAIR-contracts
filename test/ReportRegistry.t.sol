// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {ReportRegistry} from "../src/ReportRegistry.sol";

contract ReportRegistryTest is Test {
    ReportRegistry public registry;
    
    address public owner = makeAddr("owner");
    address public forwarder = makeAddr("forwarder");
    address public relayer = makeAddr("relayer");

    function setUp() public {
        // Deploying with owner and the trusted forwarder address
        registry = new ReportRegistry(owner, forwarder);
    }

    /*//////////////////////////////////////////////////////////////
                               REGISTRATION
    //////////////////////////////////////////////////////////////*/

    function test_StandardRegistration() public {
        vm.prank(owner);
        registry.registerReport("QmStandardCID");
        
        assertEq(registry.getReportCount(), 1); 
        assertEq(registry.getReportById(1).cid, "QmStandardCID"); 
    }

    function test_GaslessRegistration() public {
        string memory cid = "QmGaslessCID";

        // 1. Prepare functional call
        bytes memory functionalCall = abi.encodeWithSelector(
            registry.registerReport.selector, 
            cid
        );

        // 2. Append owner address to calldata to simulate Trusted Forwarder 
        bytes memory dataWithUser = abi.encodePacked(functionalCall, owner);

        // 3. Relayer calls through the trusted forwarder
        vm.prank(forwarder);
        (bool success, ) = address(registry).call(dataWithUser);
        
        assertTrue(success, "Gasless registration failed");
        assertEq(registry.getReportCount(), 1); 
        assertEq(registry.getReportById(1).cid, cid); 
    }

    /*//////////////////////////////////////////////////////////////
                                PAGINATION
    //////////////////////////////////////////////////////////////*/

    function test_GetReportsPagination() public {
        vm.startPrank(owner);
        registry.registerReport("CID1");
        registry.registerReport("CID2");
        registry.registerReport("CID3");
        registry.registerReport("CID4");
        registry.registerReport("CID5");
        vm.stopPrank();

        // Request: Start at index 2, limit 3 (Should return CID2, CID3, CID4)
        ReportRegistry.Report[] memory batch = registry.getReports(2, 3); 
        
        assertEq(batch.length, 3); 
        assertEq(batch[0].cid, "CID2"); 
        assertEq(batch[1].cid, "CID3"); 
        assertEq(batch[2].cid, "CID4"); 
    }

    function test_GetReportsOutOfBounds() public {
        vm.prank(owner);
        registry.registerReport("CID1");

        // Request offset greater than count
        ReportRegistry.Report[] memory batch = registry.getReports(10, 1); 
        assertEq(batch.length, 0); 
    }

    /*//////////////////////////////////////////////////////////////
                                SECURITY
    //////////////////////////////////////////////////////////////*/

    function test_RevertWhen_NonOwnerRegisters() public {
        address nonOwner = makeAddr("nonOwner");
        
        vm.prank(nonOwner);
        // Should revert because of onlyOwner modifier 
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", nonOwner));
        registry.registerReport("QmUnauthorized");
    }

    function test_RevertWhen_DuplicateCID() public {
        vm.startPrank(owner);
        registry.registerReport("QmUnique");
        
        // Registering the same CID again 
        vm.expectRevert("CID already exists"); 
        registry.registerReport("QmUnique");
        vm.stopPrank();
    }
}
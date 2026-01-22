// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/ReportRegistry.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ReportRegistryTest is Test {
    ReportRegistry registry;
    address owner = address(0xA11CE);
    address nonOwner = address(0xBEEF);

    function setUp() public {
        vm.prank(owner);
        registry = new ReportRegistry(owner);
    }

    function testRegisterReport() public {
        string memory cid = "Qm...123";
        vm.prank(owner);
        registry.registerReport(cid);

        assertEq(registry.getReportCount(), 1);
        IReportRegistry.Report memory report = registry.getReportById(1);
        assertEq(report.reportId, 1);
        assertEq(report.cid, cid);
        assertEq(report.timestamp, block.timestamp);
    }

    function testRegisterReportRevertsOnDuplicate() public {
        string memory cid = "Qm...123";
        vm.prank(owner);
        registry.registerReport(cid);

        vm.prank(owner);
        vm.expectRevert("CID already exists");
        registry.registerReport(cid);
    }

    function testRegisterReportOnlyOwner() public {
        string memory cid = "Qm...456";
        vm.prank(nonOwner);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, nonOwner));
        registry.registerReport(cid);
    }

    function testGetReportByIdNonExistent() public {
        IReportRegistry.Report memory report = registry.getReportById(999);
        assertEq(report.reportId, 0);
        assertEq(bytes(report.cid).length, 0);
        assertEq(report.timestamp, 0);
    }

    function testGetReportCount() public {
        assertEq(registry.getReportCount(), 0);
        vm.prank(owner);
        registry.registerReport("cid1");
        assertEq(registry.getReportCount(), 1);
        vm.prank(owner);
        registry.registerReport("cid2");
        assertEq(registry.getReportCount(), 2);
    }

    function testRegisterReportEmitsEvent() public {
        string memory cid = "Qm...789";
        vm.prank(owner);
        vm.expectEmit(true, true, true, true);
        emit IReportRegistry.ReportRegistered(1, cid, block.timestamp);
        registry.registerReport(cid);
    }
}

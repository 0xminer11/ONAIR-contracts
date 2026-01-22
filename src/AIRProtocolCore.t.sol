// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {AIRProtocolCore} from "../src/AIRProtocolCore.sol";

contract AIRProtocolCoreTest is Test {
    AIRProtocolCore public core;
    address public validator;
    address public user;

    bytes32 constant REPORT_ID = keccak256("test-report");
    string constant REPORT_CID = "Qm...test";
    uint64 constant AIR_SCORE = 8500;

    function setUp() public {
        validator = makeAddr("validator");
        user = makeAddr("user");

        core = new AIRProtocolCore(validator);
    }

    function test_Deployment() public view {
        assertEq(core.genesisValidator(), validator);
    }

    function test_CommitReport() public {
        vm.startPrank(validator);

        vm.expectEmit(true, true, false, true);
        emit AIRProtocolCore.ReportCommitted(
            REPORT_ID, REPORT_CID, AIR_SCORE, validator, uint64(block.timestamp)
        );

        core.commitReport(REPORT_ID, REPORT_CID, AIR_SCORE);

        assertTrue(core.exists(REPORT_ID));

        AIRProtocolCore.Report memory r = core.getReport(REPORT_ID);
        assertEq(r.reportCid, REPORT_CID);
        assertEq(r.airScore, AIR_SCORE);
        assertEq(r.validator, validator);
        assertEq(r.blockTimestamp, uint64(block.timestamp));

        vm.stopPrank();
    }

    function test_RevertWhen_NotValidator() public {
        vm.prank(user);
        vm.expectRevert(AIRProtocolCore.NotValidator.selector);
        core.commitReport(REPORT_ID, REPORT_CID, AIR_SCORE);
    }

    function test_RevertWhen_ReportAlreadyCommitted() public {
        vm.startPrank(validator);
        core.commitReport(REPORT_ID, REPORT_CID, AIR_SCORE);

        vm.expectRevert(AIRProtocolCore.ReportAlreadyCommitted.selector);
        core.commitReport(REPORT_ID, REPORT_CID, AIR_SCORE);
        vm.stopPrank();
    }

    function test_RevertWhen_ZeroReportId() public {
        vm.prank(validator);
        vm.expectRevert(AIRProtocolCore.ZeroReportId.selector);
        core.commitReport(bytes32(0), REPORT_CID, AIR_SCORE);
    }

    function test_RevertWhen_EmptyReportCid() public {
        vm.prank(validator);
        vm.expectRevert(AIRProtocolCore.EmptyReportCid.selector);
        core.commitReport(REPORT_ID, "", AIR_SCORE);
    }

    function test_GetNonExistentReport() public view {
        assertFalse(core.exists(REPORT_ID));

        AIRProtocolCore.Report memory r = core.getReport(REPORT_ID);
        assertEq(bytes(r.reportCid).length, 0);
        assertEq(r.airScore, 0);
        assertEq(r.validator, address(0));
        assertEq(r.blockTimestamp, 0);
    }

    function test_ConstructorRevertsOnZeroAddress() public {
        vm.expectRevert(AIRProtocolCore.NotValidator.selector);
        new AIRProtocolCore(address(0));
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/EmissionsController.sol";
import "../src/TreasuryVault.sol";
import "../src/AIRToken.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract EmissionsControllerTest is Test {
    EmissionsController controller;
    TreasuryVault vault;
    AIRToken air;

    address owner = address(0xA11CE);
    address merkle = address(0xBEEF);
    uint256 weeklyEmission = 1_000_000e18;

    function setUp() public {
        // Deploy AIR token
        air = new AIRToken(owner, address(0));

        // Deploy treasury
        vm.prank(owner);
        vault = new TreasuryVault(IERC20(address(air)), owner);

        // Fund treasury with AIR tokens
        vm.prank(owner);
        air.transfer(address(vault), 10_000_000e18);

        // Deploy controller
        controller = new EmissionsController(
            vault,
            merkle,
            weeklyEmission,
            owner
        );

        // Set emissions controller authorized inside vault
        vm.prank(owner);
        vault.setEmissionsController(address(controller));
    }

    /*//////////////////////////////////////////////////////////////
                        FUND EPOCH TESTS
    //////////////////////////////////////////////////////////////*/

    function testFundEpochSuccess() public {
        uint256 epochId = 1;

        vm.prank(owner);
        controller.fundEpoch(epochId);

        assertTrue(controller.epochFunded(epochId));
        assertEq(air.balanceOf(merkle), weeklyEmission);
        assertEq(air.balanceOf(address(vault)), 10_000_000e18 - weeklyEmission);
    }

    function testCannotFundEpochTwice() public {
        uint256 epochId = 2;

        vm.startPrank(owner);
        controller.fundEpoch(epochId);

        vm.expectRevert(EmissionsController.AlreadyFunded.selector);
        controller.fundEpoch(epochId); // second time
        vm.stopPrank();
    }

    function testOnlyOwnerCanFundEpoch() public {
        uint256 epochId = 3;

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(this)));
        controller.fundEpoch(epochId);
    }

    /*//////////////////////////////////////////////////////////////
                        WEEKLY EMISSION TESTS
    //////////////////////////////////////////////////////////////*/

    function testSetWeeklyEmission() public {
        vm.prank(owner);
        controller.setWeeklyEmission(2_000_000e18);

        assertEq(controller.weeklyEmission(), 2_000_000e18);
    }

    function testSetWeeklyEmissionOnlyOwner() public {
        address nonOwner = address(999);
        vm.prank(nonOwner);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, nonOwner));
        controller.setWeeklyEmission(123);
    }

    function testConstructorRevertsOnZeroAddress() public {
        vm.expectRevert(EmissionsController.ZeroAddress.selector);
        new EmissionsController(
            TreasuryVault(address(0)),
            merkle,
            weeklyEmission,
            owner
        );

        vm.expectRevert(EmissionsController.ZeroAddress.selector);
        new EmissionsController(
            vault,
            address(0),
            weeklyEmission,
            owner
        );
    }


    /*//////////////////////////////////////////////////////////////
                        EVENT TESTS
    //////////////////////////////////////////////////////////////*/

    function testFundEpochEmitsEvent() public {
        uint256 epochId = 4;

        vm.expectEmit(true, true, true, true);
        emit EmissionsController.EpochFunded(epochId, weeklyEmission);

        vm.prank(owner);
        controller.fundEpoch(epochId);
    }

    function testWeeklyEmissionEvent() public {
        uint256 newEmission = 3_000_000e18;

        vm.expectEmit(true, false, false, true);
        emit EmissionsController.WeeklyEmissionUpdated(newEmission);

        vm.prank(owner);
        controller.setWeeklyEmission(newEmission);
    }

    /*//////////////////////////////////////////////////////////////
                        TREASURY INTERACTION TESTS
    //////////////////////////////////////////////////////////////*/

    function testTreasuryPullIsCorrect() public {
        uint256 epochId = 5;

        uint256 treasuryBefore = air.balanceOf(address(vault));

        vm.prank(owner);
        controller.fundEpoch(epochId);

        uint256 treasuryAfter = air.balanceOf(address(vault));

        assertEq(treasuryBefore - treasuryAfter, weeklyEmission);
    }

    function testFundingEpochIncreasesMerkleBalance() public {
        uint256 epochId = 6;

        uint256 before = air.balanceOf(merkle);

        vm.prank(owner);
        controller.fundEpoch(epochId);

        uint256 afterBalance = air.balanceOf(merkle);

        assertEq(afterBalance - before, weeklyEmission);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import "../src/EpochAirdrop.sol";
import "../src/AIRToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AirdropControllerTest is Test {
    AirdropController airdrop;
    AIRToken token;
    address admin = address(0xA11CE);
    address coAdmin = address(0xCAFE);
    address user1 = address(0x1);
    address user2 = address(0x2);
    address user3 = address(0x3);

    function setUp() public {
        vm.startPrank(admin);
        token = new AIRToken(admin, address(0));
        airdrop = new AirdropController(IERC20(address(token)), admin);
        // Fund the admin to be able to fund the airdrop contract
        token.transfer(admin, 1_000_000e18);
        vm.stopPrank();
    }

    function testDeployment() public view {
        assertTrue(airdrop.hasRole(airdrop.DEFAULT_ADMIN_ROLE(), admin));
        assertEq(address(airdrop.AIR()), address(token));
    }

    function testAdminManagement() public {
        // Add co-admin
        vm.prank(admin);
        airdrop.addCoAdmin(coAdmin);
        assertTrue(airdrop.hasRole(airdrop.COADMIN_ROLE(), coAdmin));

        // Remove co-admin
        vm.prank(admin);
        airdrop.removeCoAdmin(coAdmin);
        assertFalse(airdrop.hasRole(airdrop.COADMIN_ROLE(), coAdmin));
    }

    function testCreateBatch() public {
        vm.prank(admin);
        airdrop.createBatch(1, 1000e18);
        (uint256 totalAllocation, , bool exists) = airdrop.batches(1);
        assertTrue(exists);
        assertEq(totalAllocation, 1000e18);
    }

    function testFund() public {
        uint256 amount = 100e18;
        vm.prank(admin);
        token.approve(address(airdrop), amount);
        vm.prank(admin);
        airdrop.fund(amount);
        assertEq(token.balanceOf(address(airdrop)), amount);
    }

    function testDistributeBatch() public {
        // 1. Setup batch and fund contract
        uint256 batchId = 1;
        uint256 totalAllocation = 300e18;
        vm.prank(admin);
        airdrop.createBatch(batchId, totalAllocation);

        uint256 fundAmount = 500e18;
        vm.prank(admin);
        token.approve(address(airdrop), fundAmount);
        vm.prank(admin);
        airdrop.fund(fundAmount);

        // 2. Prepare distribution data
        address[] memory recipients = new address[](2);
        recipients[0] = user1;
        recipients[1] = user2;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100e18;
        amounts[1] = 150e18;

        // 3. Distribute
        vm.prank(admin);
        airdrop.distributeBatch(batchId, recipients, amounts);

        // 4. Check balances and state
        assertEq(token.balanceOf(user1), 100e18);
        assertEq(token.balanceOf(user2), 150e18);
        assertEq(airdrop.batchDistributedAmount(batchId), 250e18);
        assertTrue(airdrop.isDistributed(batchId, user1));
        assertTrue(airdrop.isDistributed(batchId, user2));
        assertEq(token.balanceOf(address(airdrop)), fundAmount - 250e18);
    }

    function testEmergencyWithdraw() public {
        uint256 fundAmount = 500e18;
        vm.startPrank(admin);
        token.approve(address(airdrop), fundAmount);
        airdrop.fund(fundAmount);

        uint256 initialAdminBalance = token.balanceOf(admin);

        airdrop.emergencyWithdraw(admin);
        vm.stopPrank();

        assertEq(token.balanceOf(address(airdrop)), 0);
        assertEq(token.balanceOf(admin), initialAdminBalance + fundAmount);
    }

    function testWithdrawUnallocated() public {
        uint256 fundAmount = 500e18;
        vm.startPrank(admin);
        token.approve(address(airdrop), fundAmount);
        airdrop.fund(fundAmount);

        uint256 initialAdminBalance = token.balanceOf(admin);

        airdrop.withdrawUnallocated(IERC20(address(token)), fundAmount, admin);
        vm.stopPrank();

        assertEq(token.balanceOf(address(airdrop)), 0);
        assertEq(token.balanceOf(admin), initialAdminBalance + fundAmount);
    }

    // Additional tests for branch coverage

    function testConstructorRevertsOnZeroAddress() public {
        vm.expectRevert(AirdropController.ZeroAddress.selector);
        new AirdropController(IERC20(address(0)), admin);
        vm.expectRevert(AirdropController.ZeroAddress.selector);
        new AirdropController(IERC20(address(token)), address(0));
    }

    function testOnlyAdminOrCoAdminReverts() public {
        vm.prank(user1);
        vm.expectRevert(AirdropController.Unauthorized.selector);
        airdrop.createBatch(1, 100);
    }

    function testAddCoAdminRevertsOnZeroAddress() public {
        vm.prank(admin);
        vm.expectRevert(AirdropController.ZeroAddress.selector);
        airdrop.addCoAdmin(address(0));
    }

    function testCreateBatchUpdatesExisting() public {
        vm.startPrank(admin);
        airdrop.createBatch(1, 1000e18);
        airdrop.createBatch(1, 2000e18);
        vm.stopPrank();
        (uint256 totalAllocation, , ) = airdrop.batches(1);
        assertEq(totalAllocation, 2000e18);
    }

    function testFundRevertsOnZeroAmount() public {
        vm.prank(admin);
        vm.expectRevert(AirdropController.ZeroAddress.selector);
        airdrop.fund(0);
    }

    function testDistributeBatchRevertsOnLengthMismatch() public {
        address[] memory recipients = new address[](1);
        recipients[0] = user1;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100;
        amounts[1] = 200;

        vm.prank(admin);
        vm.expectRevert(AirdropController.LengthMismatch.selector);
        airdrop.distributeBatch(1, recipients, amounts);
    }

    function testDistributeBatchWithEmptyArrays() public {
        address[] memory recipients = new address[](0);
        uint256[] memory amounts = new uint256[](0);

        vm.prank(admin);
        airdrop.distributeBatch(1, recipients, amounts);
        // should not revert
    }

    function testDistributeBatchRevertsOnInsufficientBalance() public {
        address[] memory recipients = new address[](1);
        recipients[0] = user1;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 100e18;

        vm.prank(admin);
        vm.expectRevert(AirdropController.InsufficientBalance.selector);
        airdrop.distributeBatch(1, recipients, amounts);
    }

    function testDistributeBatchRevertsOnExceedingAllocation() public {
        vm.startPrank(admin);
        airdrop.createBatch(1, 50e18);
        token.approve(address(airdrop), 100e18);
        airdrop.fund(100e18);

        address[] memory recipients = new address[](1);
        recipients[0] = user1;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 100e18;

        vm.expectRevert(AirdropController.InsufficientBalance.selector);
        airdrop.distributeBatch(1, recipients, amounts);
        vm.stopPrank();
    }

    function testDistributeBatchRevertsOnZeroAddressRecipient() public {
        vm.startPrank(admin);
        airdrop.createBatch(1, 100e18);
        token.approve(address(airdrop), 100e18);
        airdrop.fund(100e18);

        address[] memory recipients = new address[](1);
        recipients[0] = address(0);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 100e18;

        vm.expectRevert(AirdropController.ZeroAddress.selector);
        airdrop.distributeBatch(1, recipients, amounts);
        vm.stopPrank();
    }

    function testDistributeBatchRevertsOnAlreadyDistributed() public {
        vm.startPrank(admin);
        airdrop.createBatch(1, 200e18);
        token.approve(address(airdrop), 200e18);
        airdrop.fund(200e18);

        address[] memory recipients = new address[](1);
        recipients[0] = user1;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 100e18;

        airdrop.distributeBatch(1, recipients, amounts);

        vm.expectRevert(AirdropController.AlreadyDistributed.selector);
        airdrop.distributeBatch(1, recipients, amounts);
        vm.stopPrank();
    }

    function testWithdrawUnallocatedRevertsOnZeroAddress() public {
        vm.prank(admin);
        vm.expectRevert(AirdropController.ZeroAddress.selector);
        airdrop.withdrawUnallocated(IERC20(address(token)), 100, address(0));
    }

    function testEmergencyWithdrawRevertsOnZeroAddress() public {
        vm.prank(admin);
        vm.expectRevert(AirdropController.ZeroAddress.selector);
        airdrop.emergencyWithdraw(address(0));
    }

    function testCoAdminCanCreateBatch() public {
        vm.prank(admin);
        airdrop.addCoAdmin(coAdmin);

        vm.prank(coAdmin);
        airdrop.createBatch(1, 1000e18);
        (uint256 totalAllocation, , bool exists) = airdrop.batches(1);
        assertTrue(exists);
        assertEq(totalAllocation, 1000e18);
    }

    function testStressDistributeBatch() public {
        uint256 count = 200; // Number of recipients for stress test
        address[] memory recipients = new address[](count);
        uint256[] memory amounts = new uint256[](count);
        uint256 totalAmount = 0;

        for (uint256 i = 0; i < count; i++) {
            recipients[i] = address(uint160(i + 10000)); // Ensure unique addresses
            amounts[i] = 1e18;
            totalAmount += amounts[i];
        }

        vm.startPrank(admin);
        airdrop.createBatch(99, totalAmount);
        token.approve(address(airdrop), totalAmount);
        airdrop.fund(totalAmount);

        uint256 startGas = gasleft();
        airdrop.distributeBatch(99, recipients, amounts);
        uint256 gasUsed = startGas - gasleft();

        console2.log("Gas used for %s recipients: %s", count, gasUsed);
        vm.stopPrank();

        assertEq(airdrop.batchDistributedAmount(99), totalAmount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/TreasuryVault.sol";
import "../src/AIRToken.sol";

contract TreasuryVaultTest is Test {
    TreasuryVault vault;
    AIRToken air;

    address owner = address(100);
    address controller = address(200);
    address receiver = address(300);

    function setUp() public {
        air = new AIRToken(owner);

        vm.prank(owner);
        vault = new TreasuryVault(IERC20(address(air)), owner);

        vm.prank(owner);
        air.transfer(address(vault), 1_000_000e18);

        vm.prank(owner);
        vault.setEmissionsController(controller);
    }

    function testPullToSuccess() public {
        vm.prank(controller);
        vault.pullTo(receiver, 100e18);

        assertEq(air.balanceOf(receiver), 100e18);
    }

    function testPullToRevertsIfNotController() public {
        vm.expectRevert(TreasuryVault.NotAuthorized.selector);
        vault.pullTo(receiver, 100e18);
    }
}

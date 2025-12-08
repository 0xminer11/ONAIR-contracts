// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/AIRToken.sol";

contract AIRTokenTest is Test {
    AIRToken token;
    address owner = address(0xA11CE);
    address user = address(0xBEEF);

    function setUp() public {
        token = new AIRToken(owner);
        vm.prank(owner);
        token.transfer(user, 1e18);
    }

    function testInitialSupply() public {
        assertEq(token.totalSupply(), 100_000_000_000e18);
        assertEq(token.balanceOf(owner), 100_000_000_000e18 - 1e18);
    }

    function testTransfer() public {
        vm.prank(user);
        token.transfer(owner, 1e18);
        assertEq(token.balanceOf(owner), 100_000_000_000e18);
        assertEq(token.balanceOf(user), 0);
    }

    function testApproveAndTransferFrom() public {
        vm.prank(user);
        token.approve(owner, 1e18);

        vm.prank(owner);
        token.transferFrom(user, owner, 1e18);

        assertEq(token.balanceOf(owner), 100_000_000_000e18);
        assertEq(token.balanceOf(user), 0);
    }

    function testTransferFromRevertsWithoutApproval() public {
        vm.prank(owner);
        vm.expectRevert();
        token.transferFrom(user, owner, 1e18);
    }
}

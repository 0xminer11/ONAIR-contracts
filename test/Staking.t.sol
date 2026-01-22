// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Staking.sol";
import "../src/AIRToken.sol";

contract StakingTest is Test {
    Staking staking;
    AIRToken air;

    address user = address(1);

    function setUp() public {
        air = new AIRToken(address(this), address(0));
        staking = new Staking(IERC20(address(air)));

        air.transfer(user, 1000e18);
    }

    function testStake() public {
        vm.prank(user);
        air.approve(address(staking), 500e18);

        vm.prank(user);
        staking.stake(500e18);

        assertEq(staking.stakedBalanceOf(user), 500e18);
        assertTrue(staking.isEligible(user));
    }

    function testUnstake() public {
        vm.startPrank(user);
        air.approve(address(staking), 500e18);
        staking.stake(500e18);
        staking.unstake(200e18);
        vm.stopPrank();

        assertEq(staking.stakedBalanceOf(user), 300e18);
    }

    function testUnstakeRevertsIfInsufficient() public {
        vm.startPrank(user);
        air.approve(address(staking), 500e18);
        staking.stake(300e18);

        vm.expectRevert(Staking.InsufficientStake.selector);
        staking.unstake(500e18);
    }

    function testZeroAmountStakeReverts() public {
        vm.expectRevert(Staking.ZeroAmount.selector);
        staking.stake(0);
    }
}

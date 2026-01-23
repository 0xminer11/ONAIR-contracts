// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {Staking} from "../src/Staking.sol";
import {AIRToken} from "../src/AIRToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StakingTest is Test {
    Staking public staking;
    AIRToken public token;

    address public owner = address(0x1);
    address public forwarder = address(0x2);
    address public user = address(0x3);

    function setUp() public {
        vm.startPrank(owner);
        token = new AIRToken(owner, address(0));
        // Deploy updated Staking with forwarder
        staking = new Staking(IERC20(address(token)), forwarder);
        token.transfer(user, 1000e18);
        vm.stopPrank();
    }

    function test_GaslessStake() public {
        uint256 amount = 500e18;

        vm.prank(user);
        token.approve(address(staking), amount);

        // Simulate Forwarder appending user address
        bytes memory data = abi.encodePacked(
            abi.encodeWithSelector(staking.stake.selector, amount),
            user
        );

        vm.prank(forwarder);
        (bool success, ) = address(staking).call(data);
        assertTrue(success, "Forwarded stake failed");

        assertEq(staking.stakedBalanceOf(user), amount);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
// Adjust the import path to point to your actual contracts
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Example Mock Contract to demonstrate testing structure
// Replace this with your actual contract imports
contract MockERC20 is ERC20 {
    constructor() ERC20("Mock Token", "MCK") {
        _mint(msg.sender, 1000 * 10**18);
    }
}

contract TemplateTest is Test {
    MockERC20 public token;
    address public owner;
    address public user;

    function setUp() public {
        // Create labeled addresses for clearer traces
        owner = makeAddr("owner");
        user = makeAddr("user");

        // Deploy the contract as the owner
        vm.startPrank(owner);
        token = new MockERC20();
        vm.stopPrank();
    }

    function test_InitialState() public view {
        assertEq(token.totalSupply(), 1000 * 10**18);
        assertEq(token.balanceOf(owner), 1000 * 10**18);
        assertEq(token.balanceOf(user), 0);
    }

    function test_Transfer() public {
        uint256 amount = 100 * 10**18;

        vm.prank(owner);
        token.transfer(user, amount);

        assertEq(token.balanceOf(user), amount);
        assertEq(token.balanceOf(owner), 900 * 10**18);
    }

    // Fuzz testing allows Foundry to supply random values for 'amount'
    function testFuzz_Transfer(uint256 amount) public {
        // Bound the fuzz input to a valid range (0 to owner's balance)
        amount = bound(amount, 0, token.balanceOf(owner));

        vm.prank(owner);
        token.transfer(user, amount);

        assertEq(token.balanceOf(user), amount);
    }

    function test_RevertWhen_InsufficientBalance() public {
        uint256 amount = token.balanceOf(owner) + 1;

        // Expect the next call to revert
        vm.expectRevert(); 
        vm.prank(owner);
        token.transfer(user, amount);
    }
}
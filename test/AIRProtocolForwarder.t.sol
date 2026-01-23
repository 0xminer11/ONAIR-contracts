// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {AIRToken} from "../src/AIRToken.sol";
import {Staking} from "../src/Staking.sol";
import {MerkleDistributorEpoch} from "../src/MerkleDistributorEpoch.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ForwarderSimTest is Test {
    AIRToken public token;
    Staking public staking;
    MerkleDistributorEpoch public distributor;

    address public owner = makeAddr("owner");
    address public forwarder = makeAddr("forwarder");
    address public user = makeAddr("user");
    address public relayer = makeAddr("relayer");

    function setUp() public {
        vm.startPrank(owner);
        
        // 1. Deploy Core Components 
        token = new AIRToken(owner, address(0));
        
        // 2. Deploy Gasless-enabled contracts with the trusted forwarder 
        staking = new Staking(IERC20(address(token)), forwarder);
        distributor = new MerkleDistributorEpoch(token, owner, forwarder);

        // 3. Setup initial state: fund user and distributor 
        token.transfer(user, 1000e18);
        token.transfer(address(distributor), 1000e18);
        
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                        STAKING GASLESS TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests the gasless 'stake' function using the forwarder simulation.
     */
    function test_GaslessStake_Fuzzed(uint256 amount) public {
        // Limit amount to user balance and valid range 
        amount = bound(amount, 1e18, 1000e18);

        // User must approve first (usually via gasless Permit) 
        vm.prank(user);
        token.approve(address(staking), amount);

        // Construct functional call for 'stake' 
        bytes memory functionalCall = abi.encodeWithSelector(staking.stake.selector, amount);
        
        // Append user address to calldata to simulate Trusted Forwarder 
        bytes memory dataWithUser = abi.encodePacked(functionalCall, user);

        // Relayer calls through the forwarder
        vm.prank(forwarder);
        (bool success, ) = address(staking).call(dataWithUser);
        
        assertTrue(success, "Gasless stake failed");
        assertEq(staking.stakedBalanceOf(user), amount); 
    }

    /*//////////////////////////////////////////////////////////////
                      DISTRIBUTOR GASLESS TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests the gasless 'claim' function for rewards.
     */
    function test_GaslessClaim() public {
        uint256 epochId = 1;
        uint256 index = 0;
        uint256 amount = 100e18;

        // 1. Set up Merkle Root (Simplified 1-leaf tree) 
        bytes32 leaf = keccak256(abi.encodePacked(index, user, amount)); 
        vm.prank(owner);
        distributor.setMerkleRoot(epochId, leaf); 

        // 2. Prepare gasless call for 'claim' [cite: 71]
        bytes32[] memory proof = new bytes32[](0);
        bytes memory functionalCall = abi.encodeWithSelector(
            distributor.claim.selector,
            epochId,
            index,
            user,
            amount,
            proof
        );

        // 3. Append user address and call as forwarder [cite: 211, 213]
        bytes memory dataWithUser = abi.encodePacked(functionalCall, user);

        vm.prank(forwarder);
        (bool success, ) = address(distributor).call(dataWithUser);

        assertTrue(success, "Gasless claim failed");
        assertEq(token.balanceOf(user), 1100e18); // Original 1000 + 100 reward [cite: 75]
        assertTrue(distributor.isClaimed(epochId, index)); 
    }

    /*//////////////////////////////////////////////////////////////
                        SECURITY / REVERT TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Ensures that an untrusted address cannot spoof a user identity.
     */
    function test_RevertWhen_UntrustedForwarderAttemptsSpoof() public {
        uint256 amount = 500e18;

        // Construct fake forwarder data
        bytes memory functionalCall = abi.encodeWithSelector(staking.stake.selector, amount);
        bytes memory spoofedData = abi.encodePacked(functionalCall, user);

        // Call from a random relayer, NOT the trusted forwarder 
        vm.prank(relayer);
        (bool success, ) = address(staking).call(spoofedData);

        // Should fail because _msgSender() will be the relayer, not the user,
        // and the relayer doesn't have token approval from the user. 
        assertFalse(success, "Spoofing should fail");
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/AIRToken.sol";
import {ERC2771Forwarder} from "@openzeppelin/contracts/metatx/ERC2771Forwarder.sol";

contract AIRTokenAdvancedTest is Test {
    AIRToken token;
    ERC2771Forwarder forwarder;
    address owner = address(0xA11CE);
    uint256 userPrivateKey = 0x123;
    address user = vm.addr(userPrivateKey);
    address relayer = address(0xCAFE);

    function setUp() public {
        forwarder = new ERC2771Forwarder("Forwarder");
        token = new AIRToken(owner, address(forwarder));
        
        vm.startPrank(owner);
        token.transfer(user, 1000e18);
        vm.stopPrank();
    }

    function testPermit() public {
        uint256 amount = 100e18;
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = token.nonces(user);

        // 1. Create hash
        bytes32 structHash = keccak256(abi.encode(
            keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
            user,
            relayer,
            amount,
            nonce,
            deadline
        ));
        
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", token.DOMAIN_SEPARATOR(), structHash));

        // 2. Sign hash
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);

        // 3. Call permit
        vm.prank(relayer);
        token.permit(user, relayer, amount, deadline, v, r, s);

        // 4. Check allowance
        assertEq(token.allowance(user, relayer), amount);

        // 5. Transfer from
        vm.prank(relayer);
        token.transferFrom(user, relayer, amount);

        assertEq(token.balanceOf(user), 900e18);
        assertEq(token.balanceOf(relayer), amount);
    }

    function testMetaTxTransfer() public {
        uint256 amount = 50e18;
        
        // 1. Create calldata for the token transfer
        bytes memory data = abi.encodeWithSelector(
            token.transfer.selector,
            relayer,
            amount
        );

        // 2. Manually construct the domain separator for the forwarder
        bytes32 typeHash = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
        bytes32 hashedName = keccak256(bytes("Forwarder"));
        bytes32 hashedVersion = keccak256(bytes("1"));
        bytes32 domainSeparator = keccak256(abi.encode(
            typeHash,
            hashedName,
            hashedVersion,
            block.chainid,
            address(forwarder)
        ));

        // 3. Create the struct hash for the forward request
        uint48 deadline = uint48(block.timestamp + 1 hours);
        bytes32 structHash = keccak256(abi.encode(
            keccak256("ForwardRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,uint48 deadline,bytes data)"),
            user,
            address(token),
            0, // value
            100000, // gas
            forwarder.nonces(user),
            deadline,
            keccak256(data)
        ));

        // 4. Create the final digest to sign
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        // 5. Sign the digest
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        // 6. Create the forward request data and execute
        ERC2771Forwarder.ForwardRequestData memory req = ERC2771Forwarder.ForwardRequestData({
            from: user,
            to: address(token),
            value: 0,
            gas: 100000,
            deadline: deadline,
            data: data,
            signature: signature
        });

        vm.prank(relayer);
        forwarder.execute(req);

        // 7. Check balances
        assertEq(token.balanceOf(user), 950e18);
        assertEq(token.balanceOf(relayer), amount);
    }
}

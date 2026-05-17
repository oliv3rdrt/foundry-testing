// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {Token} from "../src/Token.sol";

contract TokenTest is Test {
    Token public token;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    uint256 constant INITIAL = 1_000_000 ether;

    function setUp() public {
        token = new Token("Test", "TST", INITIAL);
        // Move the entire supply to alice so tests start from a known state
        token.transfer(alice, INITIAL);
    }

    function test_Metadata() public view {
        assertEq(token.name(), "Test");
        assertEq(token.symbol(), "TST");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), INITIAL);
    }

    function test_Transfer() public {
        vm.prank(alice);
        token.transfer(bob, 100 ether);

        assertEq(token.balanceOf(alice), INITIAL - 100 ether);
        assertEq(token.balanceOf(bob), 100 ether);
    }

    function test_Transfer_RevertOnInsufficientBalance() public {
        vm.expectRevert("Token: insufficient balance");
        vm.prank(bob);
        token.transfer(alice, 1);
    }

    function test_Transfer_RevertOnZeroAddress() public {
        vm.expectRevert("Token: transfer to zero");
        vm.prank(alice);
        token.transfer(address(0), 1);
    }

    function test_Approve_AndTransferFrom() public {
        vm.prank(alice);
        token.approve(bob, 50 ether);
        assertEq(token.allowance(alice, bob), 50 ether);

        vm.prank(bob);
        token.transferFrom(alice, bob, 30 ether);

        assertEq(token.balanceOf(bob), 30 ether);
        assertEq(token.allowance(alice, bob), 20 ether);
    }

    function test_TransferFrom_RevertOnInsufficientAllowance() public {
        vm.prank(alice);
        token.approve(bob, 10 ether);

        vm.expectRevert("Token: insufficient allowance");
        vm.prank(bob);
        token.transferFrom(alice, bob, 11 ether);
    }

    function test_InfiniteAllowance_NotDecremented() public {
        vm.prank(alice);
        token.approve(bob, type(uint256).max);

        vm.prank(bob);
        token.transferFrom(alice, bob, 100 ether);

        // Infinite allowance should be preserved across transfers
        assertEq(token.allowance(alice, bob), type(uint256).max);
    }

    function testFuzz_Transfer_PreservesTotalSupply(uint256 amount) public {
        amount = bound(amount, 0, INITIAL);
        vm.prank(alice);
        token.transfer(bob, amount);

        assertEq(token.balanceOf(alice) + token.balanceOf(bob), INITIAL);
        assertEq(token.totalSupply(), INITIAL);
    }

    function testFuzz_Approve(address spender, uint256 amount) public {
        vm.assume(spender != address(0));
        vm.prank(alice);
        token.approve(spender, amount);
        assertEq(token.allowance(alice, spender), amount);
    }
}

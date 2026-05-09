// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";

contract VaultTest is Test {
    Vault public vault;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        vault = new Vault();
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
    }

    function test_Deposit() public {
        vm.prank(alice);
        vault.deposit{value: 1 ether}();
        assertEq(vault.balances(alice), 1 ether);
        assertEq(vault.totalAssets(), 1 ether);
    }

    function test_Withdraw() public {
        vm.prank(alice);
        vault.deposit{value: 2 ether}();

        vm.prank(alice);
        vault.withdraw(1 ether);

        assertEq(vault.balances(alice), 1 ether);
        assertEq(alice.balance, 9 ether);
    }

    function test_Withdraw_RevertOnInsufficientBalance() public {
        vm.prank(alice);
        vault.deposit{value: 1 ether}();

        vm.expectRevert("Vault: insufficient balance");
        vm.prank(alice);
        vault.withdraw(2 ether);
    }

    /// Invariant: contract balance always >= sum of all user balances
    function testFuzz_DepositWithdrawInvariant(uint96 depositAmt, uint96 withdrawAmt) public {
        depositAmt = uint96(bound(depositAmt, 1, 5 ether));

        vm.prank(alice);
        vault.deposit{value: depositAmt}();

        uint256 aliceBal = vault.balances(alice);
        withdrawAmt = uint96(bound(withdrawAmt, 0, aliceBal));

        vm.prank(alice);
        vault.withdraw(withdrawAmt);

        assertGe(vault.totalAssets(), vault.balances(alice));
    }
}

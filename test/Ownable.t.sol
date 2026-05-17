// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {Ownable} from "../src/Ownable.sol";

/// Concrete impl so we can deploy the abstract Ownable in tests
contract OwnableHarness is Ownable {
    uint256 public protectedValue;

    function setProtectedValue(uint256 v) external onlyOwner {
        protectedValue = v;
    }
}

contract OwnableTest is Test {
    OwnableHarness public h;
    address deployer;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        deployer = address(this);
        h = new OwnableHarness();
    }

    function test_InitialOwnerIsDeployer() public view {
        assertEq(h.owner(), deployer);
        assertEq(h.pendingOwner(), address(0));
    }

    function test_OnlyOwner_CanCallProtected() public {
        h.setProtectedValue(1);
        assertEq(h.protectedValue(), 1);

        vm.expectRevert(Ownable.NotOwner.selector);
        vm.prank(alice);
        h.setProtectedValue(2);
    }

    function test_TwoStepTransfer() public {
        h.transferOwnership(alice);
        // Owner unchanged until accepted
        assertEq(h.owner(), deployer);
        assertEq(h.pendingOwner(), alice);

        vm.prank(alice);
        h.acceptOwnership();
        assertEq(h.owner(), alice);
        assertEq(h.pendingOwner(), address(0));
    }

    function test_Accept_RevertWhenNotPending() public {
        h.transferOwnership(alice);
        vm.expectRevert(Ownable.NotPendingOwner.selector);
        vm.prank(bob);
        h.acceptOwnership();
    }

    function test_Transfer_RevertWhenNotOwner() public {
        vm.expectRevert(Ownable.NotOwner.selector);
        vm.prank(alice);
        h.transferOwnership(bob);
    }

    function test_Renounce_ZerosOwner() public {
        h.renounceOwnership();
        assertEq(h.owner(), address(0));

        // Nobody can call protected anymore
        vm.expectRevert(Ownable.NotOwner.selector);
        h.setProtectedValue(1);
    }

    function test_Transfer_OverwritesPendingOwner() public {
        h.transferOwnership(alice);
        h.transferOwnership(bob);
        assertEq(h.pendingOwner(), bob);

        // Alice (no longer pending) cannot accept
        vm.expectRevert(Ownable.NotPendingOwner.selector);
        vm.prank(alice);
        h.acceptOwnership();
    }
}

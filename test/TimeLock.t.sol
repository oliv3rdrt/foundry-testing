// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {TimeLock} from "../src/TimeLock.sol";
import {Counter} from "../src/Counter.sol";
import {Ownable} from "../src/Ownable.sol";

contract TimeLockTest is Test {
    TimeLock public timelock;
    Counter public counter;
    address admin = makeAddr("admin");
    address attacker = makeAddr("attacker");
    uint256 constant DELAY = 2 days;
    uint256 constant GRACE_PERIOD = 14 days;

    function setUp() public {
        // Deploy as the admin so Ownable makes it the owner.
        vm.prank(admin);
        timelock = new TimeLock(DELAY, GRACE_PERIOD);
        counter = new Counter();
    }

    function _setNumberCalldata(uint256 n) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(Counter.setNumber.selector, n);
    }

    function test_QueueThenExecute() public {
        bytes memory data = _setNumberCalldata(42);
        bytes32 salt = bytes32(uint256(1));

        vm.prank(admin);
        timelock.queue(address(counter), 0, data, salt);

        vm.warp(block.timestamp + DELAY);

        vm.prank(admin);
        timelock.execute(address(counter), 0, data, salt);

        assertEq(counter.number(), 42);
    }

    function test_Execute_RevertWhenTooEarly() public {
        bytes memory data = _setNumberCalldata(1);
        bytes32 salt = bytes32(uint256(1));

        vm.prank(admin);
        timelock.queue(address(counter), 0, data, salt);

        // 1 second before eta
        vm.warp(block.timestamp + DELAY - 1);

        vm.expectRevert(); // TooEarly
        vm.prank(admin);
        timelock.execute(address(counter), 0, data, salt);
    }

    function test_Execute_RevertWhenStale() public {
        bytes memory data = _setNumberCalldata(1);
        bytes32 salt = bytes32(uint256(1));

        vm.prank(admin);
        timelock.queue(address(counter), 0, data, salt);

        // Past eta plus the grace period the operation is stale.
        vm.warp(block.timestamp + DELAY + GRACE_PERIOD + 1);

        vm.expectRevert(); // TooLate
        vm.prank(admin);
        timelock.execute(address(counter), 0, data, salt);
    }

    function test_Execute_RevertWhenNotQueued() public {
        vm.expectRevert(TimeLock.NotQueued.selector);
        vm.prank(admin);
        timelock.execute(address(counter), 0, _setNumberCalldata(1), bytes32(0));
    }

    function test_Queue_RevertOnDuplicate() public {
        bytes memory data = _setNumberCalldata(1);
        bytes32 salt = bytes32(uint256(7));

        vm.startPrank(admin);
        timelock.queue(address(counter), 0, data, salt);
        vm.expectRevert(TimeLock.AlreadyQueued.selector);
        timelock.queue(address(counter), 0, data, salt);
        vm.stopPrank();
    }

    function test_Cancel_ClearsQueue() public {
        bytes memory data = _setNumberCalldata(1);
        bytes32 salt = bytes32(uint256(1));

        vm.prank(admin);
        bytes32 id = timelock.queue(address(counter), 0, data, salt);

        vm.prank(admin);
        timelock.cancel(id);

        assertEq(timelock.queuedAt(id), 0);

        vm.warp(block.timestamp + DELAY);
        vm.expectRevert(TimeLock.NotQueued.selector);
        vm.prank(admin);
        timelock.execute(address(counter), 0, data, salt);
    }

    function test_OnlyAdmin_CanQueue() public {
        vm.expectRevert(Ownable.NotOwner.selector);
        vm.prank(attacker);
        timelock.queue(address(counter), 0, _setNumberCalldata(1), bytes32(0));
    }

    function test_OnlyAdmin_CanExecute() public {
        bytes memory data = _setNumberCalldata(1);
        bytes32 salt = bytes32(uint256(1));

        vm.prank(admin);
        timelock.queue(address(counter), 0, data, salt);

        vm.warp(block.timestamp + DELAY);

        vm.expectRevert(Ownable.NotOwner.selector);
        vm.prank(attacker);
        timelock.execute(address(counter), 0, data, salt);
    }

    function testFuzz_ExecuteAnytimeWithinGracePeriod(uint256 wait) public {
        wait = bound(wait, DELAY, DELAY + GRACE_PERIOD);
        bytes memory data = _setNumberCalldata(99);
        bytes32 salt = bytes32(uint256(1));

        vm.prank(admin);
        timelock.queue(address(counter), 0, data, salt);

        vm.warp(block.timestamp + wait);

        vm.prank(admin);
        timelock.execute(address(counter), 0, data, salt);
        assertEq(counter.number(), 99);
    }

    function test_TransferAdmin_TwoStep() public {
        address newAdmin = makeAddr("newAdmin");

        vm.prank(admin);
        timelock.transferOwnership(newAdmin);
        // Nothing changes until the new admin accepts.
        assertEq(timelock.owner(), admin);
        assertEq(timelock.pendingOwner(), newAdmin);

        vm.prank(newAdmin);
        timelock.acceptOwnership();
        assertEq(timelock.owner(), newAdmin);

        // The new admin can queue now, the old one no longer can.
        vm.prank(newAdmin);
        timelock.queue(address(counter), 0, _setNumberCalldata(1), bytes32(0));

        vm.expectRevert(Ownable.NotOwner.selector);
        vm.prank(admin);
        timelock.queue(address(counter), 0, _setNumberCalldata(2), bytes32(uint256(2)));
    }

    function test_TransferAdmin_OnlyOwnerCanStart() public {
        vm.expectRevert(Ownable.NotOwner.selector);
        vm.prank(attacker);
        timelock.transferOwnership(attacker);
    }

    function test_TransferAdmin_OnlyPendingOwnerCanAccept() public {
        address newAdmin = makeAddr("newAdmin");
        vm.prank(admin);
        timelock.transferOwnership(newAdmin);

        vm.expectRevert(Ownable.NotPendingOwner.selector);
        vm.prank(attacker);
        timelock.acceptOwnership();
    }
}

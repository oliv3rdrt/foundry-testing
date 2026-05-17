// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {TimeLock} from "../src/TimeLock.sol";
import {Counter} from "../src/Counter.sol";

contract TimeLockTest is Test {
    TimeLock public timelock;
    Counter public counter;
    address admin = makeAddr("admin");
    address attacker = makeAddr("attacker");
    uint256 constant DELAY = 2 days;

    function setUp() public {
        timelock = new TimeLock(admin, DELAY);
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
        vm.expectRevert(TimeLock.NotAdmin.selector);
        vm.prank(attacker);
        timelock.queue(address(counter), 0, _setNumberCalldata(1), bytes32(0));
    }

    function test_OnlyAdmin_CanExecute() public {
        bytes memory data = _setNumberCalldata(1);
        bytes32 salt = bytes32(uint256(1));

        vm.prank(admin);
        timelock.queue(address(counter), 0, data, salt);

        vm.warp(block.timestamp + DELAY);

        vm.expectRevert(TimeLock.NotAdmin.selector);
        vm.prank(attacker);
        timelock.execute(address(counter), 0, data, salt);
    }

    function testFuzz_ExecuteAtAnyTimeAfterEta(uint256 wait) public {
        wait = bound(wait, DELAY, DELAY + 365 days);
        bytes memory data = _setNumberCalldata(99);
        bytes32 salt = bytes32(uint256(1));

        vm.prank(admin);
        timelock.queue(address(counter), 0, data, salt);

        vm.warp(block.timestamp + wait);

        vm.prank(admin);
        timelock.execute(address(counter), 0, data, salt);
        assertEq(counter.number(), 99);
    }
}

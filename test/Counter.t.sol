// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {Counter} from "../src/Counter.sol";

contract CounterTest is Test {
    Counter public counter;

    function setUp() public {
        counter = new Counter();
        counter.setNumber(0);
    }

    function test_Increment() public {
        counter.increment();
        assertEq(counter.number(), 1);
    }

    function test_Decrement_RevertOnZero() public {
        vm.expectRevert("Counter: underflow");
        counter.decrement();
    }

    function testFuzz_SetNumber(uint256 x) public {
        counter.setNumber(x);
        assertEq(counter.number(), x);
    }

    function testFuzz_IncrementNeverOverflows(uint256 start) public {
        // bound to avoid actual overflow
        start = bound(start, 0, type(uint256).max - 1);
        counter.setNumber(start);
        counter.increment();
        assertEq(counter.number(), start + 1);
    }
}

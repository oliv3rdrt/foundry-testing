// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {Staking} from "../src/Staking.sol";

contract StakingTest is Test {
    Staking public staking;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        staking = new Staking();
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
    }

    function test_Stake() public {
        vm.prank(alice);
        staking.stake{value: 1 ether}();
        assertEq(staking.stakes(alice), 1 ether);
        assertEq(staking.totalStaked(), 1 ether);
    }

    function test_Unstake() public {
        vm.prank(alice);
        staking.stake{value: 3 ether}();

        vm.prank(alice);
        staking.unstake(1 ether);

        assertEq(staking.stakes(alice), 2 ether);
        assertEq(staking.totalStaked(), 2 ether);
    }

    function test_Unstake_RevertInsufficientStake() public {
        vm.prank(alice);
        staking.stake{value: 1 ether}();

        vm.expectRevert("Staking: insufficient stake");
        vm.prank(alice);
        staking.unstake(2 ether);
    }

    function testFuzz_StakeUnstake_TotalAlwaysConsistent(uint96 a, uint96 b) public {
        uint256 aliceAmt = bound(a, 1, 5 ether);
        uint256 bobAmt = bound(b, 1, 5 ether);

        vm.prank(alice);
        staking.stake{value: aliceAmt}();

        vm.prank(bob);
        staking.stake{value: bobAmt}();

        // Invariant check: totalStaked == sum of all stakes
        assertEq(staking.totalStaked(), staking.stakes(alice) + staking.stakes(bob));

        vm.prank(alice);
        staking.unstake(aliceAmt / 2 + 1);

        assertEq(staking.totalStaked(), staking.stakes(alice) + staking.stakes(bob));
    }
}

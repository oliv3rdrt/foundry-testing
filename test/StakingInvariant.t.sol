// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {Staking} from "../src/Staking.sol";

/// Stateful invariant handler - foundry picks random sequences of these calls
/// and runs the invariants after each. Mirrors test/VaultInvariant.t.sol.
contract StakingInvariantHandler is Test {
    Staking public staking;
    address[] public actors;

    // Tracked alongside the contract so the invariants can compare against an
    // independently-maintained sum.
    uint256 public ghostTotalStaked;
    uint256 public ghostTotalUnstaked;

    constructor(Staking _staking) {
        staking = _staking;
        actors.push(makeAddr("s_actor1"));
        actors.push(makeAddr("s_actor2"));
        actors.push(makeAddr("s_actor3"));
        for (uint256 i; i < actors.length; i++) {
            vm.deal(actors[i], 100 ether);
        }
    }

    function stake(uint256 actorSeed, uint256 amount) external {
        address actor = actors[actorSeed % actors.length];
        amount = bound(amount, 1, 5 ether);
        vm.prank(actor);
        staking.stake{value: amount}();
        ghostTotalStaked += amount;
    }

    function unstake(uint256 actorSeed, uint256 amount) external {
        address actor = actors[actorSeed % actors.length];
        uint256 current = staking.stakes(actor);
        if (current == 0) return;
        amount = bound(amount, 1, current);
        vm.prank(actor);
        staking.unstake(amount);
        ghostTotalUnstaked += amount;
    }

    function sumActorStakes() external view returns (uint256 sum) {
        for (uint256 i; i < actors.length; i++) {
            sum += staking.stakes(actors[i]);
        }
    }
}

contract StakingInvariantTest is Test {
    Staking public staking;
    StakingInvariantHandler public handler;

    function setUp() public {
        staking = new Staking();
        handler = new StakingInvariantHandler(staking);
        targetContract(address(handler));
    }

    /// totalStaked must always equal the sum of the recorded per-actor stakes.
    function invariant_totalStakedEqualsActorSum() public view {
        assertEq(staking.totalStaked(), handler.sumActorStakes());
    }

    /// Ghost accounting: net flow (staked minus unstaked) must equal totalStaked.
    function invariant_netFlowEqualsTotalStaked() public view {
        assertEq(staking.totalStaked(), handler.ghostTotalStaked() - handler.ghostTotalUnstaked());
    }

    /// The contract's ETH balance must match its own accounting at all times.
    function invariant_contractBalanceEqualsTotalStaked() public view {
        assertEq(address(staking).balance, staking.totalStaked());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";

/// Stateful invariant handler - foundry picks random sequences of these calls
/// and runs the invariant after each.
contract VaultInvariantHandler is Test {
    Vault public vault;
    address[] public actors;

    // Tracked alongside the contract so the invariant can compare against
    // an independently-maintained sum.
    uint256 public ghostTotalDeposits;
    uint256 public ghostTotalWithdrawals;

    constructor(Vault _vault) {
        vault = _vault;
        actors.push(makeAddr("v_actor1"));
        actors.push(makeAddr("v_actor2"));
        actors.push(makeAddr("v_actor3"));
        for (uint256 i; i < actors.length; i++) {
            vm.deal(actors[i], 100 ether);
        }
    }

    function deposit(uint256 actorSeed, uint256 amount) external {
        address actor = actors[actorSeed % actors.length];
        amount = bound(amount, 1, 5 ether);
        vm.prank(actor);
        vault.deposit{value: amount}();
        ghostTotalDeposits += amount;
    }

    function withdraw(uint256 actorSeed, uint256 amount) external {
        address actor = actors[actorSeed % actors.length];
        uint256 current = vault.balances(actor);
        if (current == 0) return;
        amount = bound(amount, 1, current);
        vm.prank(actor);
        vault.withdraw(amount);
        ghostTotalWithdrawals += amount;
    }

    function sumActorBalances() external view returns (uint256 sum) {
        for (uint256 i; i < actors.length; i++) {
            sum += vault.balances(actors[i]);
        }
    }
}

contract VaultInvariantTest is Test {
    Vault public vault;
    VaultInvariantHandler public handler;

    function setUp() public {
        vault = new Vault();
        handler = new VaultInvariantHandler(vault);
        targetContract(address(handler));
    }

    /// Contract ETH balance must equal the sum of recorded user balances at all times
    function invariant_contractBalanceEqualsUserSum() public view {
        assertEq(address(vault).balance, handler.sumActorBalances());
    }

    /// Ghost accounting: net flow (deposits - withdrawals) must equal contract balance
    function invariant_netFlowEqualsBalance() public view {
        assertEq(
            address(vault).balance,
            handler.ghostTotalDeposits() - handler.ghostTotalWithdrawals()
        );
    }

    /// totalAssets() is a thin view but should never lie
    function invariant_totalAssetsMatchesBalance() public view {
        assertEq(vault.totalAssets(), address(vault).balance);
    }
}

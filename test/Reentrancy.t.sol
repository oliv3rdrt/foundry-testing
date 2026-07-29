// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";
import {Staking} from "../src/Staking.sol";

// A receiver that tries to re-enter Vault.withdraw from inside its receive().
contract VaultReentrant {
    Vault public vault;
    bool public reentered;

    constructor(Vault vault_) {
        vault = vault_;
    }

    function attack(uint256 amount) external {
        vault.deposit{value: amount}();
        vault.withdraw(amount);
    }

    receive() external payable {
        // Re-enter once. Vault zeroes our balance before it sends the ETH, so
        // this second withdraw reverts and takes the whole attack down with it.
        if (!reentered) {
            reentered = true;
            vault.withdraw(msg.value);
        }
    }
}

// The same idea aimed at Staking.unstake.
contract StakingReentrant {
    Staking public staking;
    bool public reentered;

    constructor(Staking staking_) {
        staking = staking_;
    }

    function attack(uint256 amount) external {
        staking.stake{value: amount}();
        staking.unstake(amount);
    }

    receive() external payable {
        if (!reentered) {
            reentered = true;
            staking.unstake(msg.value);
        }
    }
}

contract ReentrancyTest is Test {
    Vault vault;
    Staking staking;
    address honest = makeAddr("honest");

    function setUp() public {
        vault = new Vault();
        staking = new Staking();

        // A legitimate user whose funds an attacker might try to reach.
        vm.deal(honest, 20 ether);
        vm.startPrank(honest);
        vault.deposit{value: 10 ether}();
        staking.stake{value: 10 ether}();
        vm.stopPrank();
    }

    function test_Vault_ReentrancyIsBlocked() public {
        VaultReentrant attacker = new VaultReentrant(vault);
        vm.deal(address(attacker), 1 ether);

        // The re-entrant withdraw reverts, which unwinds the whole attack.
        vm.expectRevert();
        attacker.attack(1 ether);

        // Nothing was stolen: the honest deposit and the vault total are intact.
        assertEq(vault.balances(honest), 10 ether);
        assertEq(vault.balances(address(attacker)), 0);
        assertEq(address(vault).balance, 10 ether);
    }

    function test_Staking_ReentrancyIsBlocked() public {
        StakingReentrant attacker = new StakingReentrant(staking);
        vm.deal(address(attacker), 1 ether);

        vm.expectRevert();
        attacker.attack(1 ether);

        assertEq(staking.stakes(honest), 10 ether);
        assertEq(staking.stakes(address(attacker)), 0);
        assertEq(staking.totalStaked(), 10 ether);
        assertEq(address(staking).balance, 10 ether);
    }
}

# foundry-testing

Foundry workspace built around three small contracts. The interesting part is the test suite: unit tests, fuzz tests, and a stateful invariant suite with a handler. Full suite runs in ~130ms across 13 tests, including 256 invariant runs and 3,840 random calls.

## Stack

- Foundry (forge, cast, anvil)
- Solidity 0.8.24
- forge-std + native cheatcodes

## Prerequisites

| Tool | Install |
|------|---------|
| Foundry | `curl -L https://foundry.paradigm.xyz \| bash` then `foundryup` |

## Quick start

```bash
forge install
forge build
forge test -vv
```

For gas snapshots and reports:

```bash
forge snapshot
forge test --gas-report
```

## What's in here

| Contract | Test types |
|---|---|
| `src/Counter.sol` | unit, fuzz |
| `src/Vault.sol` | unit, fuzz, invariant (with `VaultHandler.sol`) |
| `src/Staking.sol` | unit, fuzz |

Tests live in `test/`. The invariant handler in `test/VaultHandler.sol` constrains the random call surface so invariants converge instead of bouncing off reverts.

## Why Foundry over Hardhat

| Concern | Hardhat | Foundry |
|---|---|---|
| Test language | JS / TS | Solidity |
| Test runtime | Node + ethers | Native Rust EVM |
| Fuzzing | plugin | built in, 256 runs default |
| Invariants | plugin | built in (`invariant_*`) |
| Cheatcodes | none | `vm.prank`, `vm.warp`, `vm.expectRevert` |
| Cold mainnet fork | seconds | hundreds of ms |

For Solidity-heavy work, the native test language alone is worth it. No context-switching between two languages on every assertion.

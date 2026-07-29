# foundry-testing

Foundry workspace built around seven small contracts. The interesting part is the test suite: unit tests, fuzz tests, and stateful invariant suites with handlers. The full suite runs in under 200ms across 51 tests, including invariant runs that exercise thousands of random call sequences.

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

Formatting and the gas baseline are enforced in CI:

```bash
forge fmt --check
forge snapshot --check
```

## What's in here

| Contract | Description | Test types |
|---|---|---|
| `src/Counter.sol` | Trivial counter | unit, fuzz |
| `src/Token.sol` | Minimal ERC20-style token | unit, fuzz |
| `src/NFT.sol` | Minimal ERC721-style NFT | unit, fuzz |
| `src/Vault.sol` | ETH vault | unit, fuzz, invariant, reentrancy |
| `src/Staking.sol` | ETH staking | unit, fuzz, invariant, reentrancy |
| `src/TimeLock.sol` | Queue/execute/cancel timelock | unit, fuzz |
| `src/Ownable.sol` | Two-step ownership mixin | unit |

Tests live in `test/`. The invariant handlers in `test/VaultInvariant.t.sol` and `test/StakingInvariant.t.sol` constrain the random call surface (bounded amounts, a fixed actor set) so invariants converge instead of bouncing off reverts, and they track ghost variables to cross-check each contract's own accounting.

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

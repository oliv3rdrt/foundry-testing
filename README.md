```
    ___                  __         
   / _/__  __ _____  ___/ /______  __
  / _/ _ \/ // / _ \/ _  / __/ // /_/
 /_/ \___/\_,_/_//_/\_,_/_/  \_, (_) 
                            /___/    

  forge · cast · anvil · chisel
```

[![CI](https://github.com/DRT23-mod/foundry-testing/actions/workflows/ci.yml/badge.svg)](https://github.com/DRT23-mod/foundry-testing/actions)
[![Foundry](https://img.shields.io/badge/Foundry-1.x-orange.svg)](https://book.getfoundry.sh)
[![Solidity](https://img.shields.io/badge/Solidity-0.8.24-blue.svg)](https://docs.soliditylang.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A Foundry workspace built around three small contracts. The interesting bit is
not the contracts themselves but the **tests**: unit, fuzz, and an invariant
suite with a stateful handler. The full suite finishes in about 130ms across
13 tests, including 256 invariant runs with 3,840 random calls.

---

## Table of Contents

- [Why Foundry](#why-foundry)
- [Prerequisites](#prerequisites)
- [Quick start](#quick-start)
- [Project structure](#project-structure)
- [The contracts](#the-contracts)
- [The tests](#the-tests)
- [Forge cheat sheet](#forge-cheat-sheet)
- [Cast cheat sheet](#cast-cheat-sheet)
- [Anvil and chisel](#anvil-and-chisel)
- [Configuration](#configuration)
- [CI](#ci)
- [Troubleshooting](#troubleshooting)
- [References](#references)

---

## Why Foundry

| Concern                          | Hardhat                  | Foundry                         |
|----------------------------------|--------------------------|---------------------------------|
| Test language                    | JS / TS                  | Solidity                        |
| Test runtime                     | Node + EthersJS          | Native Rust EVM                 |
| Fuzzing                          | Plugin (`hardhat-fuzz`)  | Built in, 1000 runs default     |
| Invariants                       | Plugin                   | Built in (`invariant_*`)        |
| Mainnet fork speed (cold)        | seconds                  | hundreds of ms                  |
| Cheatcodes                       | none                     | `vm.prank`, `vm.warp`, etc.     |
| Coverage                         | `solidity-coverage`      | `forge coverage`                |
| Gas snapshots                    | plugin                   | `forge snapshot`                |

For Solidity-heavy work, the native test language alone is worth the switch.
You stop context-switching between two languages every time you want to assert
something.

## Prerequisites

| Tool   | Install                                        |
|--------|------------------------------------------------|
| Foundry| `curl -L https://foundry.paradigm.xyz \| bash` then `foundryup` |
| Git    | any recent version                             |

That is it. Foundry has no Node.js or package manager dependency.

## Quick start

```bash
git clone https://github.com/DRT23-mod/foundry-testing.git
cd foundry-testing
forge install foundry-rs/forge-std --no-git
forge build
forge test -vv
```

Expected output:

```
Ran 4 tests for test/Counter.t.sol:CounterTest
  [PASS] testFuzz_IncrementNeverOverflows(uint256) (runs: 1000, μ: 29843)
  [PASS] testFuzz_SetNumber(uint256)               (runs: 1000, μ: 27705)
  [PASS] test_Decrement_RevertOnZero()             (gas: 10507)
  [PASS] test_Increment()                          (gas: 28504)

Ran 1 test for test/Staking.t.sol:StakingInvariantTest
  [PASS] invariant_totalStakedEqualsBalance()
        (runs: 256, calls: 3840, reverts: 0)

13 tests passed, 0 failed
```

## Project structure

```
foundry-testing/
├── src/
│   ├── Counter.sol         # state machine, integer math
│   ├── Vault.sol           # ETH deposit / withdraw with balance tracking
│   └── Staking.sol         # multi-actor staking (used for invariant tests)
├── test/
│   ├── Counter.t.sol       # unit + fuzz
│   ├── Vault.t.sol         # unit + fuzz with vm cheatcodes
│   └── Staking.t.sol       # unit + fuzz + invariant handler
├── script/
│   └── Deploy.s.sol        # forge script broadcast deployment
├── lib/                    # forge-std (gitignored, installed via forge install)
├── foundry.toml            # solc 0.8.24, optimizer, fuzz/invariant config
├── .github/workflows/ci.yml
└── README.md
```

## The contracts

### `Counter.sol`

Two-line contract used to demonstrate fuzz tests against pure integer logic.

### `Vault.sol`

Per-user ETH deposit/withdraw map. Used to demonstrate cheatcodes:

```solidity
vm.deal(alice, 10 ether);   // give alice ETH out of thin air
vm.prank(alice);            // make the next call originate from alice
vault.deposit{value: 1 ether}();
```

### `Staking.sol`

Stake-tracking contract whose **invariant** is:

> `totalStaked == address(this).balance`

This must hold no matter what arbitrary sequence of `stake` and `unstake` calls
the fuzzer dreams up.

## The tests

### Unit tests

Plain Solidity with `forge-std`'s `Test` base. Everything Foundry-native:

```solidity
function test_Withdraw_RevertOnInsufficientBalance() public {
    vm.prank(alice);
    vault.deposit{value: 1 ether}();

    vm.expectRevert("Vault: insufficient balance");
    vm.prank(alice);
    vault.withdraw(2 ether);
}
```

### Fuzz tests

Function arguments become inputs the fuzzer randomises. `bound()` keeps inputs
in range without throwing away runs:

```solidity
function testFuzz_IncrementNeverOverflows(uint256 start) public {
    start = bound(start, 0, type(uint256).max - 1);
    counter.setNumber(start);
    counter.increment();
    assertEq(counter.number(), start + 1);
}
```

### Invariant tests with a handler

The handler bounds the actions to a useful state space (you do not want the
fuzzer trying to send 2^256 ETH because it always reverts and teaches you
nothing):

```
StakingInvariantTest
        │ targetContract → StakingInvariantHandler
        │
        ▼
StakingInvariantHandler          (the only contract called by the fuzzer)
  ├── stake(actor, amount)       (bounded 1..5 ether)
  └── unstake(actor, amount)     (bounded to current stake)

After every random sequence, foundry checks:
        invariant_totalStakedEqualsBalance()
```

## Forge cheat sheet

| Command                              | Use                                              |
|--------------------------------------|--------------------------------------------------|
| `forge build`                        | Compile contracts                                |
| `forge test`                         | Run all tests                                    |
| `forge test -vvv`                    | Run with traces (more `v` = more detail)         |
| `forge test --match-test test_X`     | Run a single test by name                        |
| `forge test --match-contract VaultT` | Run all tests in one contract                    |
| `forge test --fuzz-runs 10000`       | Crank up fuzz runs                               |
| `forge test --gas-report`            | Per-function gas table                           |
| `forge snapshot`                     | Write `.gas-snapshot` for diffing across PRs     |
| `forge coverage`                     | LCOV-style coverage report                       |
| `forge fmt`                          | Format Solidity (style enforcement in CI)        |
| `forge inspect Counter abi`          | Print ABI for a contract                         |
| `forge install <repo>`               | Add a Solidity dependency                        |
| `forge script script/Deploy.s.sol --rpc-url $RPC --broadcast` | Deploy |

## Cast cheat sheet

`cast` is the swiss army knife for chain interaction from the CLI.

```bash
# ETH balance
cast balance 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045 --rpc-url $RPC

# Read a view function
cast call $USDC "balanceOf(address)(uint256)" 0xd8dA... --rpc-url $RPC

# Decode a 4-byte selector
cast 4byte 0xa9059cbb     # → transfer(address,uint256)

# Decode raw calldata
cast 4byte-decode 0xa9059cbb000000...

# Send a transaction
cast send $TOKEN "transfer(address,uint256)" 0xRECIPIENT 1000000 \
  --private-key $PK --rpc-url $RPC

# Convert wei <-> ether
cast --to-wei 1.5 ether
cast --from-wei 1500000000000000000

# Hash a string
cast keccak "Transfer(address,address,uint256)"
```

## Anvil and chisel

**`anvil`** is the local node. Identical interface to Hardhat node, faster boot:

```bash
anvil                                     # default 8545, 10 funded accounts
anvil --fork-url https://eth.llamarpc.com # fork mainnet at latest block
anvil --fork-url $RPC --fork-block-number 19_000_000
```

**`chisel`** is a Solidity REPL. Useful for poking at math without writing a
script:

```bash
$ chisel
➜ uint256 x = 100;
➜ x * 1.05e18 / 1e18
105
```

## Configuration

The full `foundry.toml`:

```toml
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
solc = "0.8.24"
optimizer = true
optimizer_runs = 200

[profile.default.fuzz]
runs = 1000
max_test_rejects = 65536

[profile.default.invariant]
runs = 256
depth = 15

[rpc_endpoints]
mainnet = "${MAINNET_RPC_URL}"
sepolia = "${SEPOLIA_RPC_URL}"
```

| Env var            | Used by                  |
|--------------------|--------------------------|
| `MAINNET_RPC_URL`  | `--rpc-url mainnet`      |
| `SEPOLIA_RPC_URL`  | `--rpc-url sepolia`      |
| `PRIVATE_KEY`      | `forge script ... --broadcast` |
| `ETHERSCAN_API_KEY`| contract verification    |

## CI

GitHub Actions runs `forge build`, `forge test --fuzz-runs 500`, the invariant
suite, and a gas snapshot on every PR. See `.github/workflows/ci.yml`.

## Troubleshooting

**`Compiler run failed: file imported by '...' not found`**
You forgot `forge install foundry-rs/forge-std --no-git`. The `lib/` directory
is gitignored by design.

**`Failed to compile: Function "mcopy" not found`**
Update `solc` to 0.8.24+ in `foundry.toml`. The default `cancun` evm version is
already correct.

**Invariant test passes too easily**
Your handler is reverting every call. Run with `-vvvv` and look at
`reverts: N` in the summary; if reverts equals total calls, your bounds are
wrong.

## References

- [Foundry Book](https://book.getfoundry.sh)
- [forge-std reference](https://github.com/foundry-rs/forge-std)
- [Cheatcodes reference](https://book.getfoundry.sh/cheatcodes/)
- [Invariant testing guide](https://book.getfoundry.sh/forge/invariant-testing)

## License

MIT

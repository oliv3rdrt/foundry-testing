# Foundry - Personal Testing

Hands-on with [Foundry](https://getfoundry.sh) - the Rust-based Ethereum toolkit. After years of Hardhat, Foundry's speed and Solidity-native tests are genuinely a step change.

## What I explored

- **forge** - compiled and tested contracts in pure Solidity
- **anvil** - spun up a local chain for manual interaction
- **cast** - queried mainnet state and decoded calldata from the CLI
- **chisel** - used the REPL to prototype Solidity snippets interactively
- **Fuzzing** - wrote fuzz tests with `forge test --fuzz-runs 10000`
- **Cheatcodes** - `vm.prank`, `vm.deal`, `vm.expectRevert`, `vm.warp`

## Setup

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
forge install
forge build
forge test -vvv
```

## Useful cast snippets I kept

```bash
# Check ETH balance
cast balance 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045 --rpc-url mainnet

# Decode calldata
cast 4byte-decode 0xa9059cbb...

# Call a view function
cast call 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 "balanceOf(address)(uint256)" 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045 --rpc-url mainnet
```

## Key takeaways

- Writing tests in Solidity (not JS) removes the constant mental context switch
- `forge snapshot` for gas benchmarking is a killer feature - caught a 40% regression in one diff
- `anvil --fork-url` for mainnet forking is effortless and much faster than Hardhat's equivalent
- `forge fmt` enforces style automatically - good for teams

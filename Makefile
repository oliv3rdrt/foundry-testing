# Common workflows. Forge has good defaults; this just shortens what I type 50x a day.

.PHONY: help build test test-watch fuzz invariant snapshot snapshot-check gas coverage fmt clean deploy

help:
	@echo "build           - forge build"
	@echo "test            - forge test (full suite, summary output)"
	@echo "test-watch      - rerun tests on file change"
	@echo "fuzz            - run fuzz tests only, with more runs"
	@echo "invariant       - run invariant tests only, with more depth"
	@echo "snapshot        - write .gas-snapshot baseline"
	@echo "snapshot-check  - fail if gas usage moved vs baseline"
	@echo "gas             - per-test gas report"
	@echo "coverage        - line coverage summary"
	@echo "fmt             - forge fmt"
	@echo "clean           - remove build artifacts"
	@echo "deploy          - run script/Deploy.s.sol (needs PRIVATE_KEY, RPC_URL)"

build:
	forge build

test:
	forge test --summary

test-watch:
	forge test --watch

fuzz:
	forge test --match-test "Fuzz" --fuzz-runs 5000

invariant:
	forge test --match-test "invariant" --invariant-runs 1000 --invariant-depth 50

snapshot:
	forge snapshot

snapshot-check:
	forge snapshot --check

gas:
	forge test --gas-report

coverage:
	forge coverage --report summary

fmt:
	forge fmt

clean:
	forge clean

deploy:
	forge script script/Deploy.s.sol:DeployScript --rpc-url $$RPC_URL --broadcast -vvv

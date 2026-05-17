// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {Counter} from "../src/Counter.sol";
import {Vault} from "../src/Vault.sol";
import {Token} from "../src/Token.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);

        Counter counter = new Counter();
        Vault vault = new Vault();
        Token token = new Token("Test Token", "TST", 1_000_000 ether);

        console.log("Counter deployed at:", address(counter));
        console.log("Vault deployed at:  ", address(vault));
        console.log("Token deployed at:  ", address(token));

        vm.stopBroadcast();
    }
}

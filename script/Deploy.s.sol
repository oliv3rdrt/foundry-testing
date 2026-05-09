// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {Counter} from "../src/Counter.sol";
import {Vault} from "../src/Vault.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);

        Counter counter = new Counter();
        Vault vault = new Vault();

        console.log("Counter deployed at:", address(counter));
        console.log("Vault deployed at:  ", address(vault));

        vm.stopBroadcast();
    }
}

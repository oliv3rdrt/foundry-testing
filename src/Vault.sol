// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// Simple ETH vault - used to practice fuzzing deposit/withdraw invariants
contract Vault {
    mapping(address => uint256) public balances;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    function deposit() external payable {
        require(msg.value > 0, "Vault: zero deposit");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Vault: insufficient balance");
        balances[msg.sender] -= amount;
        (bool ok,) = msg.sender.call{value: amount}("");
        require(ok, "Vault: transfer failed");
        emit Withdrawn(msg.sender, amount);
    }

    function totalAssets() external view returns (uint256) {
        return address(this).balance;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// Minimal staking contract — used to practice invariant testing
/// Invariant: totalStaked == sum of all user stakes
contract Staking {
    mapping(address => uint256) public stakes;
    uint256 public totalStaked;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);

    function stake() external payable {
        require(msg.value > 0, "Staking: zero amount");
        stakes[msg.sender] += msg.value;
        totalStaked += msg.value;
        emit Staked(msg.sender, msg.value);
    }

    function unstake(uint256 amount) external {
        require(stakes[msg.sender] >= amount, "Staking: insufficient stake");
        stakes[msg.sender] -= amount;
        totalStaked -= amount;
        (bool ok,) = msg.sender.call{value: amount}("");
        require(ok, "Staking: transfer failed");
        emit Unstaked(msg.sender, amount);
    }

    function getStake(address user) external view returns (uint256) {
        return stakes[user];
    }
}

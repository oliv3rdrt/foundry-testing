// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "./Ownable.sol";

/// Minimal timelock: queue a call, wait `delay`, then execute. Admin rights come
/// from the two-step Ownable mixin, so the admin can be handed over safely.
/// Used to practice testing block.timestamp manipulation with vm.warp.
contract TimeLock is Ownable {
    uint256 public immutable delay;
    // Once eta passes there is a window of gracePeriod to execute in. After that
    // the queued operation is stale and has to be queued again.
    uint256 public immutable gracePeriod;

    mapping(bytes32 => uint256) public queuedAt; // 0 means not queued

    event Queued(bytes32 indexed id, address target, uint256 value, bytes data, uint256 eta);
    event Executed(bytes32 indexed id, address target, uint256 value, bytes data);
    event Cancelled(bytes32 indexed id);

    error AlreadyQueued();
    error NotQueued();
    error TooEarly(uint256 eta, uint256 now_);
    error TooLate(uint256 deadline, uint256 now_);
    error CallFailed(bytes returndata);

    // Ownable's constructor sets the deployer as the owner (the admin here).
    constructor(uint256 delay_, uint256 gracePeriod_) {
        delay = delay_;
        gracePeriod = gracePeriod_;
    }

    function hashOp(address target, uint256 value, bytes calldata data, bytes32 salt) public pure returns (bytes32) {
        return keccak256(abi.encode(target, value, data, salt));
    }

    function queue(address target, uint256 value, bytes calldata data, bytes32 salt)
        external
        onlyOwner
        returns (bytes32 id)
    {
        id = hashOp(target, value, data, salt);
        if (queuedAt[id] != 0) revert AlreadyQueued();
        uint256 eta = block.timestamp + delay;
        queuedAt[id] = eta;
        emit Queued(id, target, value, data, eta);
    }

    function cancel(bytes32 id) external onlyOwner {
        if (queuedAt[id] == 0) revert NotQueued();
        delete queuedAt[id];
        emit Cancelled(id);
    }

    function execute(address target, uint256 value, bytes calldata data, bytes32 salt)
        external
        payable
        onlyOwner
        returns (bytes memory)
    {
        bytes32 id = hashOp(target, value, data, salt);
        uint256 eta = queuedAt[id];
        if (eta == 0) revert NotQueued();
        if (block.timestamp < eta) revert TooEarly(eta, block.timestamp);
        uint256 deadline = eta + gracePeriod;
        if (block.timestamp > deadline) revert TooLate(deadline, block.timestamp);

        delete queuedAt[id];
        (bool ok, bytes memory ret) = target.call{value: value}(data);
        if (!ok) revert CallFailed(ret);
        emit Executed(id, target, value, data);
        return ret;
    }

    receive() external payable {}
}

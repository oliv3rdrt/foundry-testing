// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// Minimal timelock: queue a call, wait `delay`, then execute. Single admin.
/// Used to practice testing block.timestamp manipulation with vm.warp.
contract TimeLock {
    address public admin;
    uint256 public immutable delay;

    mapping(bytes32 => uint256) public queuedAt; // 0 means not queued

    event Queued(bytes32 indexed id, address target, uint256 value, bytes data, uint256 eta);
    event Executed(bytes32 indexed id, address target, uint256 value, bytes data);
    event Cancelled(bytes32 indexed id);

    error NotAdmin();
    error AlreadyQueued();
    error NotQueued();
    error TooEarly(uint256 eta, uint256 now_);
    error CallFailed(bytes returndata);

    modifier onlyAdmin() {
        if (msg.sender != admin) revert NotAdmin();
        _;
    }

    constructor(address admin_, uint256 delay_) {
        admin = admin_;
        delay = delay_;
    }

    function hashOp(address target, uint256 value, bytes calldata data, bytes32 salt) public pure returns (bytes32) {
        return keccak256(abi.encode(target, value, data, salt));
    }

    function queue(address target, uint256 value, bytes calldata data, bytes32 salt) external onlyAdmin returns (bytes32 id) {
        id = hashOp(target, value, data, salt);
        if (queuedAt[id] != 0) revert AlreadyQueued();
        uint256 eta = block.timestamp + delay;
        queuedAt[id] = eta;
        emit Queued(id, target, value, data, eta);
    }

    function cancel(bytes32 id) external onlyAdmin {
        if (queuedAt[id] == 0) revert NotQueued();
        delete queuedAt[id];
        emit Cancelled(id);
    }

    function execute(address target, uint256 value, bytes calldata data, bytes32 salt) external payable onlyAdmin returns (bytes memory) {
        bytes32 id = hashOp(target, value, data, salt);
        uint256 eta = queuedAt[id];
        if (eta == 0) revert NotQueued();
        if (block.timestamp < eta) revert TooEarly(eta, block.timestamp);

        delete queuedAt[id];
        (bool ok, bytes memory ret) = target.call{value: value}(data);
        if (!ok) revert CallFailed(ret);
        emit Executed(id, target, value, data);
        return ret;
    }

    receive() external payable {}
}

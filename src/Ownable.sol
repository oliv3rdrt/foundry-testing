// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// Minimal two-step Ownable. Pending owner must accept - no foot-gun transfers
/// to an address that can't sign for itself.
abstract contract Ownable {
    address public owner;
    address public pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    error NotOwner();
    error NotPendingOwner();

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner, newOwner);
    }

    function acceptOwnership() external {
        if (msg.sender != pendingOwner) revert NotPendingOwner();
        address previous = owner;
        owner = pendingOwner;
        delete pendingOwner;
        emit OwnershipTransferred(previous, owner);
    }

    /// Owner can renounce immediately - no two-step. Use carefully.
    function renounceOwnership() external onlyOwner {
        address previous = owner;
        delete owner;
        delete pendingOwner;
        emit OwnershipTransferred(previous, address(0));
    }
}

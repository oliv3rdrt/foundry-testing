// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// Minimal ERC721-style NFT - no metadata, no enumerable, no safeTransfer hooks.
/// Mint is open so tests don't have to deal with roles.
contract NFT {
    string public name;
    string public symbol;

    mapping(uint256 => address) internal _owners;
    mapping(address => uint256) internal _balances;
    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }

    function ownerOf(uint256 tokenId) public view returns (address owner) {
        owner = _owners[tokenId];
        require(owner != address(0), "NFT: nonexistent token");
    }

    function balanceOf(address owner) external view returns (uint256) {
        require(owner != address(0), "NFT: zero address");
        return _balances[owner];
    }

    function mint(address to, uint256 tokenId) external {
        require(to != address(0), "NFT: mint to zero");
        require(_owners[tokenId] == address(0), "NFT: already minted");
        _owners[tokenId] = to;
        unchecked { _balances[to] += 1; }
        emit Transfer(address(0), to, tokenId);
    }

    function approve(address to, uint256 tokenId) external {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NFT: not authorized");
        getApproved[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId) external {
        require(to != address(0), "NFT: transfer to zero");
        address owner = ownerOf(tokenId);
        require(owner == from, "NFT: from is not owner");
        require(
            msg.sender == owner ||
                isApprovedForAll[owner][msg.sender] ||
                getApproved[tokenId] == msg.sender,
            "NFT: not authorized"
        );

        // Clear per-token approval on transfer (matches ERC721 spec)
        delete getApproved[tokenId];
        unchecked {
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }
}

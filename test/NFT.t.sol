// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {NFT} from "../src/NFT.sol";

contract NFTTest is Test {
    NFT public nft;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address carol = makeAddr("carol");

    function setUp() public {
        nft = new NFT("TestNFT", "TNFT");
    }

    function test_MintAndOwnership() public {
        nft.mint(alice, 1);
        assertEq(nft.ownerOf(1), alice);
        assertEq(nft.balanceOf(alice), 1);
    }

    function test_Mint_RevertOnDoubleMint() public {
        nft.mint(alice, 1);
        vm.expectRevert("NFT: already minted");
        nft.mint(bob, 1);
    }

    function test_Mint_RevertOnZeroAddress() public {
        vm.expectRevert("NFT: mint to zero");
        nft.mint(address(0), 1);
    }

    function test_TransferFrom_ByOwner() public {
        nft.mint(alice, 1);
        vm.prank(alice);
        nft.transferFrom(alice, bob, 1);
        assertEq(nft.ownerOf(1), bob);
        assertEq(nft.balanceOf(alice), 0);
        assertEq(nft.balanceOf(bob), 1);
    }

    function test_Transfer_ClearsApproval() public {
        nft.mint(alice, 1);
        vm.prank(alice);
        nft.approve(carol, 1);
        assertEq(nft.getApproved(1), carol);

        vm.prank(alice);
        nft.transferFrom(alice, bob, 1);
        assertEq(nft.getApproved(1), address(0));
    }

    function test_ApprovedSpenderCanTransfer() public {
        nft.mint(alice, 1);
        vm.prank(alice);
        nft.approve(carol, 1);

        vm.prank(carol);
        nft.transferFrom(alice, bob, 1);
        assertEq(nft.ownerOf(1), bob);
    }

    function test_OperatorCanTransfer() public {
        nft.mint(alice, 1);
        vm.prank(alice);
        nft.setApprovalForAll(carol, true);

        vm.prank(carol);
        nft.transferFrom(alice, bob, 1);
        assertEq(nft.ownerOf(1), bob);
    }

    function test_TransferFrom_RevertWhenUnauthorized() public {
        nft.mint(alice, 1);
        vm.expectRevert("NFT: not authorized");
        vm.prank(bob);
        nft.transferFrom(alice, bob, 1);
    }

    function test_TransferFrom_RevertOnZeroAddress() public {
        nft.mint(alice, 1);
        vm.expectRevert("NFT: transfer to zero");
        vm.prank(alice);
        nft.transferFrom(alice, address(0), 1);
    }

    function test_OwnerOf_RevertOnNonexistent() public {
        vm.expectRevert("NFT: nonexistent token");
        nft.ownerOf(999);
    }

    function testFuzz_Mint_AnyOwnerAndTokenId(address to, uint256 tokenId) public {
        vm.assume(to != address(0));
        nft.mint(to, tokenId);
        assertEq(nft.ownerOf(tokenId), to);
        assertEq(nft.balanceOf(to), 1);
    }
}

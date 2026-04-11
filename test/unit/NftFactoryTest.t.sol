// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;
import {Test} from "forge-std/Test.sol";
import {DeployNft} from "../../script/DeployNft.s.sol";
import {NftFactory} from "../../src/NftFactory.sol";

contract NftFactoryTest is Test {
    NftFactory nftFactory;

    uint256 constant STARTING_BALANCE = 10 ether;
    string constant NFT_NAME = "NEXT NFT";
    string constant NFT_SYMBOL = "NXT";

    address CREATOR = makeAddr("CREATOR");

    function setUp() external {
        DeployNft depoyNft = new DeployNft();

        nftFactory = depoyNft.run();

        vm.deal(CREATOR, STARTING_BALANCE);
    }

    modifier isCreator() {
        vm.startPrank(CREATOR);
        _;
        vm.stopPrank();
    }

    function test_createNftCollection_RevertsEmptyName() public isCreator {
        vm.expectRevert(NftFactory.NftFactory__EmptyNFTName.selector);

        nftFactory.createNftCollection("", NFT_SYMBOL);
    }

    function test_createNftCollection_RevertsNameWhiteSpace() public isCreator {
        vm.expectRevert(NftFactory.NftFactory__EmptyNFTName.selector);

        nftFactory.createNftCollection("  ", NFT_SYMBOL);
    }

    function test_createNftCollection_RevertsEmptySymbol() public isCreator {
        vm.expectRevert(NftFactory.NftFactory__EmptyNFTSymbol.selector);

        nftFactory.createNftCollection(NFT_NAME, "");
    }

    function test_createNftCollection_RevertsWhiteSpaceSymbol()
        public
        isCreator
    {
        vm.expectRevert(NftFactory.NftFactory__EmptyNFTSymbol.selector);

        nftFactory.createNftCollection(NFT_NAME, "  ");
    }

    function test_createNftCollection_RevertsZeroAddressCreator() public {
        address zero = address(0);
        vm.prank(zero);

        vm.expectRevert(NftFactory.NftFactory__ZeroAddressCreator.selector);

        nftFactory.createNftCollection(NFT_NAME, NFT_SYMBOL);
    }

    function test_createNftCollection_EmitSuccessfully() public isCreator {
        vm.expectEmit(false, false, false, true);

        emit NftFactory.CollectionCreated(NFT_NAME, NFT_SYMBOL);

        nftFactory.createNftCollection(NFT_NAME, NFT_SYMBOL);
    }

    function test_NftCollection_isValidCollection() public isCreator {
        address collection = nftFactory.createNftCollection(
            NFT_NAME,
            NFT_SYMBOL
        );

        assertTrue(nftFactory.isNftValidCollection(collection));
    }

    function test_createNftCollection_createMutilplellection()
        public
        isCreator
    {
        uint256 count = 5;
        for (uint256 i = 0; i < count; i++) {
            nftFactory.createNftCollection(NFT_NAME, NFT_SYMBOL);
        }
        assertEq(count, nftFactory.getCollectionCounter());
    }

    /******************************************************************************
     *                                 fuzz test                                  *
     ******************************************************************************/

    function testFuzz_createNftCollection_RevertsEmptyName(
        string memory name,
        string memory symbol
    ) public isCreator {
        vm.assume(bytes(name).length == 0);
        vm.expectRevert(NftFactory.NftFactory__EmptyNFTName.selector);

        nftFactory.createNftCollection("", symbol);
    }

    // function testFuzz_createNftCollection(
    //     string memory name,
    //     string memory symbol,
    //     address user
    // ) public {
    //     vm.assume(user != address(0));
    //     vm.assume(bytes(name).length > 0 && bytes(name).length < 32);
    //     vm.assume(bytes(symbol).length > 0 && bytes(symbol).length < 10);

    //     vm.prank(user);
    //     nftFactory.createNftCollection(name, symbol);

    //     assertEq(nftFactory.getCollectionCounter(), 1);
    // }

    // function testFuzz_createNftCollection_MultipleUsersCreateCollection(
    //     string[] memory name,
    //     string[] memory symbol,
    //     address[] memory users
    // ) public {
    //     vm.assume(users.length == name.length);
    //     vm.assume(name.length == symbol.length);
    //     vm.assume(users.length > 0 && users.length < 5);

    //     for (uint256 i = 0; i < users.length; i++) {
    //         if (
    //             users[i] == address(0) ||
    //             bytes(name[i]).length == 0 ||
    //             bytes(symbol[i]).length == 0
    //         ) {
    //             return;
    //         }
    //         vm.prank(users[i]);
    //         nftFactory.createNftCollection(name[i], symbol[i]);
    //     }
    //     assertEq(nftFactory.getCollectionCounter(), users.length);
    // }
}

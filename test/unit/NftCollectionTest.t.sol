// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;
import {Test} from "forge-std/Test.sol";
import {DeployNft} from "../../script/DeployNft.s.sol";
import {NftFactory} from "../../src/NftFactory.sol";
import {NftCollection} from "../../src/NftCollection.sol";
import {MockInvalidFactory} from "../../test/mocks/MockInvalidFactory.sol";

contract NftCollectionTest is Test {
    NftFactory nftFactory;
    NftCollection nftCollection;

    uint256 constant STARTING_BALANCE = 10 ether;
    string constant NFT_NAME = "NEXT NFT";
    string constant NFT_SYMBOL = "NXT";
    string constant BASE_URI = "ipfs://";

    address CREATOR = makeAddr("CREATOR");
    address USER1 = makeAddr("USER1");

    function setUp() external {
        vm.deal(CREATOR, STARTING_BALANCE);
        vm.deal(USER1, STARTING_BALANCE);
        DeployNft depoyNft = new DeployNft();

        (nftFactory,) = depoyNft.run();

        vm.startPrank(CREATOR);

        address _nft = nftFactory.createNftCollection(NFT_NAME, NFT_SYMBOL);

        vm.stopPrank();

        nftCollection = NftCollection(_nft);
    }

    modifier isCreator() {
        vm.startPrank(CREATOR);
        _;
        vm.stopPrank();
    }

    //https://ipfs.io/ipfs/QmRJpcesWxpvQnsRo8u4Fi7YRns3YV2VDdQEV2LBZVkjTu?filename=483.jpg

    /******************************************************************************
     *                                    test                                    *
     ******************************************************************************/

    function test_NftCollection_NameIsCorrect() public view {
        string memory expectedName = nftCollection.name();
        string memory name = nftCollection.getNftName();

        assert(keccak256(abi.encodePacked(expectedName)) == keccak256(abi.encodePacked(name)));
    }

    function test_NftCollection_SymbolIsCorect() public view {
        string memory expectedSymbol = nftCollection.symbol();
        string memory symbol = nftCollection.getNftSymbol();

        assert(keccak256(abi.encodePacked(expectedSymbol)) == keccak256(abi.encodePacked(symbol)));
    }

    function test_NftCollection_RevertsAddressZeroFactory() public {
        address fakeFactory = address(0);

        vm.expectRevert(NftCollection.NftCollection__ZeroAddressFactory.selector);

        new NftCollection(BASE_URI, NFT_NAME, NFT_SYMBOL, CREATOR, fakeFactory);
    }

    function test_NftCollection_RevertsEmptyNftName() public {
        vm.expectRevert(NftCollection.NftCollection__EmptyNFTName.selector);

        new NftCollection(BASE_URI, "", NFT_SYMBOL, CREATOR, address(nftFactory));
    }

    function test_NftCollection_RevertsNftSymbol() public {
        vm.expectRevert(NftCollection.NftCollection__EmptyNFTSymbol.selector);

        new NftCollection(BASE_URI, NFT_NAME, "", CREATOR, address(nftFactory));
    }

    function test_mintNft_RevertsIfNotCollectionCreator() public {
        vm.startPrank(USER1);
        vm.expectRevert();

        nftCollection.mintNft();

        vm.stopPrank();
    }

    function test_mintNft_RevertsIfNotFromFactory() public isCreator {
        MockInvalidFactory rogueFactory = new MockInvalidFactory();

        NftCollection rogueCollection =
            new NftCollection(BASE_URI, NFT_NAME, NFT_SYMBOL, CREATOR, address(rogueFactory));

        vm.expectRevert(NftCollection.NftCollection__InValidCollection.selector);

        rogueCollection.mintNft();
    }

    function test_mintNft_TokenIdIncrement() public isCreator {
        uint256 _id;
        nftCollection.mintNft();
        _id++;

        assertEq(nftCollection.getTokenIDCounter(), _id);
    }

    function test_tokenURI_RevertsIfInValidTokenID() public isCreator {
        nftCollection.mintNft();
        vm.expectRevert(NftCollection.NftCollection__InValidTokenId.selector);
        nftCollection.tokenURI(4);
    }

    function test_tokenURI_ReturnTokenURI() public isCreator {
        string memory expectedURI = "ipfs://bafybeif4d4ajetwhmy4cn44j4hfliwgkx422qq5q56ljlzxbl53t67crmy/0.json";
        nftCollection.mintNft();

        string memory uri = nftCollection.tokenURI(0);

        // assertEq(uri, expectedURI);
        assert(keccak256(abi.encodePacked(expectedURI)) == keccak256(abi.encodePacked(uri)));
    }
}

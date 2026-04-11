// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;
import {Test} from "forge-std/Test.sol";
import {DeployNft} from "../../script/DeployNft.s.sol";
import {NftFactory} from "../../src/NftFactory.sol";
import {NftCollection} from "../../src/NftCollection.sol";

contract NftCollectionTest is Test {
    NftFactory nftFactory;
    NftCollection nftCollection;

    uint256 constant STARTING_BALANCE = 10 ether;
    string constant NFT_NAME = "NEXT NFT";
    string constant NFT_SYMBOL = "NXT";
    string constant BASE_URI = "ipfs://";

    address CREATOR = makeAddr("CREATOR");

    function setUp() external {
        vm.deal(CREATOR, STARTING_BALANCE);
        DeployNft depoyNft = new DeployNft();

        nftFactory = depoyNft.run();

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

    function test_NftCollection_RevertsAddressZeroFactory() public {
        address fakeFactory = address(0);

        vm.expectRevert(
            NftCollection.NftCollection__ZeroAddressFactory.selector
        );

        new NftCollection(BASE_URI, NFT_NAME, NFT_SYMBOL, CREATOR, fakeFactory);
    }

    function test_NftCollection_RevertsEmptyNftName() public {
        vm.expectRevert(NftCollection.NftCollection__EmptyNFTName.selector);

        new NftCollection(
            BASE_URI,
            "",
            NFT_SYMBOL,
            CREATOR,
            address(nftFactory)
        );
    }

    function test_NftCollection_RevertsNftSymbol() public {
        vm.expectRevert(NftCollection.NftCollection__EmptyNFTSymbol.selector);

        new NftCollection(BASE_URI, NFT_NAME, "", CREATOR, address(nftFactory));
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;
import {Test} from "forge-std/Test.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {DeployNft} from "../../script/DeployNft.s.sol";
import {DeployNft} from "../../script/DeployNft.s.sol";
import {NftFactory} from "../../src/NftFactory.sol";
import {NftCollection} from "../../src/NftCollection.sol";
import {MarketPlace} from "../../src/MarketPlace.sol";

contract MarketPlaceTest is Test {
    NftFactory nftFactory;
    NftCollection nftCollection;
    MarketPlace marketPlace;

    uint256 constant STARTING_BALANCE = 10 ether;
    uint constant INTIAL_TOKENID = 0;
    uint constant NFT_PRICE = 1 ether;
    string constant NFT_NAME = "NEXT NFT";
    string constant NFT_SYMBOL = "NXT";
    string constant BASE_URI = "ipfs://";

    address CREATOR = makeAddr("CREATOR");
    address USER1 = makeAddr("USER1");

    function setUp() external {
        vm.deal(CREATOR, STARTING_BALANCE);
        vm.deal(USER1, STARTING_BALANCE);

        DeployNft depoyNft = new DeployNft();

        (nftFactory, marketPlace) = depoyNft.run();

        vm.startPrank(CREATOR);

        address _nft = nftFactory.createNftCollection(NFT_NAME, NFT_SYMBOL);

        nftCollection = NftCollection(_nft);

        nftCollection.mintNft();
        nftCollection.mintNft();

        vm.stopPrank();
    }

    modifier isCreator() {
        vm.startPrank(CREATOR);
        _;
        vm.stopPrank();
    }

    modifier aproveSingleNFT(uint256 tokenID) {
        // vm.prank(CREATOR);

        IERC721(address(nftCollection)).approve(address(marketPlace), tokenID);
        _;
    }
    modifier approveAllNFT() {
        IERC721(address(nftCollection)).setApprovalForAll(
            address(marketPlace),
            true
        );
        _;
    }

    function test_listNFT_revertZeroNFTContractAddress() public isCreator {
        vm.expectRevert(
            MarketPlace.MarketPlace__ZeroAddressNFTContract.selector
        );
        marketPlace.list_nft(address(0), INTIAL_TOKENID, NFT_PRICE);
    }

    function test_listNFT_revertPriceisInvalid() public isCreator {
        vm.expectRevert(MarketPlace.MarketPlace__InValidPrice.selector);
        marketPlace.list_nft(address(nftCollection), INTIAL_TOKENID, 0);
    }

    function test_listNFT_revertIfNotOwner() public {
        vm.startPrank(USER1);

        vm.expectRevert(MarketPlace.MarketPlace__NotNFTOwner.selector);

        marketPlace.list_nft(address(nftCollection), INTIAL_TOKENID, NFT_PRICE);
        vm.stopPrank();
    }

    function test_listNFT_revertifNoApproval() public isCreator {
        vm.expectRevert(MarketPlace.MarketPlace__NFTNotApproved.selector);
        marketPlace.list_nft(address(nftCollection), INTIAL_TOKENID, NFT_PRICE);
    }

    function test_listNFT_setLstingProperlyWithApproveAll()
        public
        isCreator
        approveAllNFT
    {
        marketPlace.list_nft(address(nftCollection), INTIAL_TOKENID, NFT_PRICE);

        MarketPlace.Listing memory _listing = marketPlace
            .getListedTokenPriceFromTokenID(
                address(nftCollection),
                INTIAL_TOKENID
            );

        assertTrue(_listing.seller == CREATOR);
        assertEq(_listing.price, NFT_PRICE);
    }

    function test_listNFT_setLstingProperlyWithApprove()
        public
        isCreator
        aproveSingleNFT(INTIAL_TOKENID)
    {
        marketPlace.list_nft(address(nftCollection), INTIAL_TOKENID, NFT_PRICE);

        MarketPlace.Listing memory _listing = marketPlace
            .getListedTokenPriceFromTokenID(
                address(nftCollection),
                INTIAL_TOKENID
            );

        assertTrue(_listing.seller == CREATOR);
        assertEq(_listing.price, NFT_PRICE);
    }

    function test_listNFT_EventEmitSuccessfully()
        public
        isCreator
        approveAllNFT
    {
        vm.expectEmit(true, true, false, true);

        emit MarketPlace.NFTListed(
            CREATOR,
            address(nftCollection),
            INTIAL_TOKENID,
            NFT_PRICE
        );

        marketPlace.list_nft(address(nftCollection), INTIAL_TOKENID, NFT_PRICE);
    }
}

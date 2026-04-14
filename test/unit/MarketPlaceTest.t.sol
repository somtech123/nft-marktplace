// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;
import {Test} from "forge-std/Test.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {DeployNft} from "../../script/DeployNft.s.sol";
import {DeployNft} from "../../script/DeployNft.s.sol";
import {NftFactory} from "../../src/NftFactory.sol";
import {NftCollection} from "../../src/NftCollection.sol";
import {MarketPlace} from "../../src/MarketPlace.sol";
import {MockMarketPlace} from "../mocks/MockMarketPlace.sol";

contract MarketPlaceTest is Test {
    NftFactory nftFactory;
    NftCollection nftCollection;
    MarketPlace marketPlace;
    MockMarketPlace mockMarketPlace;

    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant INTIAL_TOKENID = 0;
    uint256 constant NFT_PRICE = 2 ether;
    uint256 constant LISTED_PRICE = 1 ether;
    string constant NFT_NAME = "NEXT NFT";
    string constant NFT_SYMBOL = "NXT";
    string constant BASE_URI = "ipfs://";
    uint256 constant FIXED_SALES_DURATION = 0;
    uint256 constant AUCTION_SALES_DURATION = 7;

    address CREATOR = makeAddr("CREATOR");
    address USER1 = makeAddr("USER1");
    address USER2 = makeAddr("USER2");
    address USER3 = makeAddr("USER3");

    function setUp() external {
        vm.deal(CREATOR, STARTING_BALANCE);
        vm.deal(USER1, STARTING_BALANCE + 1 ether);
        vm.deal(USER2, STARTING_BALANCE + 1 ether);
        vm.deal(USER3, STARTING_BALANCE + 1 ether);

        DeployNft depoyNft = new DeployNft();

        (nftFactory, marketPlace) = depoyNft.run();
        mockMarketPlace = new MockMarketPlace();

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

    modifier listNft() {
        vm.startPrank(CREATOR);

        IERC721(address(nftCollection)).setApprovalForAll(
            address(marketPlace),
            true
        );
        marketPlace.list_nft(
            address(nftCollection),
            INTIAL_TOKENID,
            NFT_PRICE,
            FIXED_SALES_DURATION
        );
        _;
        vm.stopPrank();
    }
    modifier listAuctionNft() {
        vm.startPrank(CREATOR);

        IERC721(address(nftCollection)).setApprovalForAll(
            address(marketPlace),
            true
        );
        marketPlace.list_nft(
            address(nftCollection),
            INTIAL_TOKENID,
            LISTED_PRICE,
            AUCTION_SALES_DURATION
        );
        _;
        vm.stopPrank();
    }

    function test_listNFT_revertZeroNFTContractAddress() public isCreator {
        vm.expectRevert(
            MarketPlace.MarketPlace__ZeroAddressNFTContract.selector
        );
        marketPlace.list_nft(
            address(0),
            INTIAL_TOKENID,
            NFT_PRICE,
            FIXED_SALES_DURATION
        );
    }

    function test_listNFT_revertPriceisInvalid() public isCreator {
        vm.expectRevert(MarketPlace.MarketPlace__InValidPrice.selector);
        marketPlace.list_nft(
            address(nftCollection),
            INTIAL_TOKENID,
            0,
            FIXED_SALES_DURATION
        );
    }

    function test_listNFT_revertIfNotOwner() public {
        vm.startPrank(USER1);

        vm.expectRevert(MarketPlace.MarketPlace__NotNFTOwner.selector);

        marketPlace.list_nft(
            address(nftCollection),
            INTIAL_TOKENID,
            NFT_PRICE,
            FIXED_SALES_DURATION
        );
        vm.stopPrank();
    }

    function test_listNFT_revertifNoApproval() public isCreator {
        vm.expectRevert(MarketPlace.MarketPlace__NFTNotApproved.selector);
        marketPlace.list_nft(
            address(nftCollection),
            INTIAL_TOKENID,
            NFT_PRICE,
            FIXED_SALES_DURATION
        );
    }

    function test_listNFT_setLstingProperlyWithApproveAll()
        public
        isCreator
        approveAllNFT
    {
        marketPlace.list_nft(
            address(nftCollection),
            INTIAL_TOKENID,
            NFT_PRICE,
            AUCTION_SALES_DURATION
        );

        MarketPlace.Listing memory _listing = marketPlace
            .getListedTokenPriceFromTokenID(
                address(nftCollection),
                INTIAL_TOKENID
            );
        uint256 deadline = block.timestamp + (AUCTION_SALES_DURATION * 1 days);
        vm.warp(deadline);

        assertTrue(_listing.seller == CREATOR);
        assertEq(_listing.price, NFT_PRICE);
        assertTrue(_listing.saleType == MarketPlace.SaleType.AUCTION);
        assertEq(_listing.endTime, deadline);
    }

    function test_listNFT_setLstingProperlyWithApprove()
        public
        isCreator
        aproveSingleNFT(INTIAL_TOKENID)
    {
        marketPlace.list_nft(
            address(nftCollection),
            INTIAL_TOKENID,
            NFT_PRICE,
            FIXED_SALES_DURATION
        );

        MarketPlace.Listing memory _listing = marketPlace
            .getListedTokenPriceFromTokenID(
                address(nftCollection),
                INTIAL_TOKENID
            );

        assertTrue(_listing.seller == CREATOR);
        assertEq(_listing.price, NFT_PRICE);
        assertTrue(_listing.saleType == MarketPlace.SaleType.FIXED);
        assertEq(_listing.endTime, 0);
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

        marketPlace.list_nft(
            address(nftCollection),
            INTIAL_TOKENID,
            NFT_PRICE,
            FIXED_SALES_DURATION
        );
    }

    /******************************************************************************
     *                              test update nft                               *
     ******************************************************************************/

    function test_updateListedNftPrice_RevertForInvalidListing()
        public
        isCreator
    {
        vm.expectRevert(MarketPlace.MarketPlace__ListingNotFound.selector);
        marketPlace.updateListedNftPrice(address(nftCollection), 28, NFT_PRICE);
    }

    function test_updateListedNftPrice_RevertIfNotOwner() public listNft {
        vm.startPrank(USER1);
        vm.expectRevert(MarketPlace.MarketPlace__NotNFTOwner.selector);
        marketPlace.updateListedNftPrice(
            address(nftCollection),
            INTIAL_TOKENID,
            NFT_PRICE
        );
        vm.stopPrank();
    }

    function test_updateListedNftPrice_RevertForInvalidPrice() public listNft {
        vm.expectRevert(MarketPlace.MarketPlace__InValidPrice.selector);
        marketPlace.updateListedNftPrice(
            address(nftCollection),
            INTIAL_TOKENID,
            0
        );
    }

    function test_updateListedNftPrice_priceUpdatedSuccessfully()
        public
        listNft
    {
        MarketPlace.Listing memory _listing = marketPlace
            .getListedTokenPriceFromTokenID(
                address(nftCollection),
                INTIAL_TOKENID
            );
        uint256 oldPrice = _listing.price;
        uint256 newPrice = NFT_PRICE + 5 ether;

        marketPlace.updateListedNftPrice(
            address(nftCollection),
            INTIAL_TOKENID,
            newPrice
        );

        assertEq(oldPrice + 5 ether, newPrice);
    }

    function test_updateListedNftPrice_emitEventsSuccessfully() public listNft {
        uint256 newPrice = NFT_PRICE + 5 ether;
        vm.expectEmit(true, false, false, true);

        emit MarketPlace.NFTPriceUpdated(
            address(nftCollection),
            INTIAL_TOKENID,
            newPrice
        );

        marketPlace.updateListedNftPrice(
            address(nftCollection),
            INTIAL_TOKENID,
            newPrice
        );
    }

    /******************************************************************************
     *                              test cancel nft                               *
     ******************************************************************************/

    function test_cancelListedNFT_RevertsIfListingNotFound() public listNft {
        vm.expectRevert(MarketPlace.MarketPlace__ListingNotFound.selector);
        marketPlace.cancelListedNFT(address(nftCollection), 2);
    }

    function test_cancelListedNFT_CancelSuccessfully() public listNft {
        marketPlace.cancelListedNFT(address(nftCollection), INTIAL_TOKENID);

        MarketPlace.Listing memory _listing = marketPlace
            .getListedTokenPriceFromTokenID(
                address(nftCollection),
                INTIAL_TOKENID
            );

        assertTrue(_listing.seller == address(0));
        assertEq(_listing.price, 0);
    }

    function test_cancelListedNFT_EmitEventSuccessfully() public listNft {
        vm.expectEmit(true, true, false, true);
        emit MarketPlace.CancelListedNFT(
            CREATOR,
            address(nftCollection),
            INTIAL_TOKENID
        );

        marketPlace.cancelListedNFT(address(nftCollection), INTIAL_TOKENID);
    }

    /******************************************************************************
     *                              test buy nft                               *
     ******************************************************************************/
    function test_buyNft_RevertsIfAuction() public listAuctionNft {
        vm.startPrank(USER1);

        vm.expectRevert(MarketPlace.MarketPlace__NotFixedNFT.selector);
        marketPlace.buyNFT{value: NFT_PRICE}(
            address(nftCollection),
            INTIAL_TOKENID
        );

        vm.stopPrank();
    }

    function test_buyNft_RevertsIfNFTNotFound() public listNft {
        vm.startPrank(USER1);
        vm.expectRevert(MarketPlace.MarketPlace__ListingNotFound.selector);
        marketPlace.buyNFT{value: STARTING_BALANCE}(address(nftCollection), 1);

        vm.stopPrank();
    }

    function test_buyNft_RevertsForInsufficientAmount() public listNft {
        uint256 amount = 0.5 ether;
        vm.startPrank(USER1);

        vm.expectRevert(MarketPlace.MarketPlace__InsufficientPayment.selector);

        marketPlace.buyNFT{value: amount}(
            address(nftCollection),
            INTIAL_TOKENID
        );

        vm.stopPrank();
    }

    function test_BuyNft_ListingisCleared() public listNft {
        vm.startPrank(USER1);

        marketPlace.buyNFT{value: NFT_PRICE}(
            address(nftCollection),
            INTIAL_TOKENID
        );
        MarketPlace.Listing memory _listing = marketPlace
            .getListedTokenPriceFromTokenID(
                address(nftCollection),
                INTIAL_TOKENID
            );

        assertTrue(_listing.seller == address(0));
        assertEq(_listing.price, 0);
        vm.stopPrank();
    }

    function test_BuyNft_RoyaltyReceiverIsCreator() public listNft {
        (address receiver, uint256 amount) = ERC2981(address(nftCollection))
            .royaltyInfo(INTIAL_TOKENID, NFT_PRICE);

        assertEq(receiver, CREATOR);
        assertEq(amount, 0.05 ether);
    }

    function test_BuyNft_NFTTransfedToBuyer() public listNft {
        assertEq(nftCollection.ownerOf(INTIAL_TOKENID), CREATOR);
        vm.startPrank(USER1);

        marketPlace.buyNFT{value: NFT_PRICE}(
            address(nftCollection),
            INTIAL_TOKENID
        );
        assertEq(nftCollection.ownerOf(INTIAL_TOKENID), USER1);
        vm.stopPrank();
    }

    function test_BuyNft_EmitEventsSuccessfully() public listNft {
        vm.startPrank(USER1);
        vm.expectEmit(true, true, true, true);

        emit MarketPlace.BoughtNFT(
            address(nftCollection),
            CREATOR,
            USER1,
            INTIAL_TOKENID,
            NFT_PRICE
        );

        marketPlace.buyNFT{value: NFT_PRICE}(
            address(nftCollection),
            INTIAL_TOKENID
        );
        vm.stopPrank();
    }

    function test_withdrawProceed_revertsIfNotSeller() public listNft {
        vm.startPrank(USER1);
        marketPlace.buyNFT{value: NFT_PRICE}(
            address(nftCollection),
            INTIAL_TOKENID
        );

        vm.expectRevert(MarketPlace.MarketPlace__NoPendingWithdrawal.selector);
        marketPlace.withdrawProceed();

        vm.stopPrank();
    }

    function test_withdrawProceed_emitEventSucessfully() public listNft {
        vm.startPrank(USER1);
        marketPlace.buyNFT{value: NFT_PRICE}(
            address(nftCollection),
            INTIAL_TOKENID
        );
        vm.stopPrank();

        vm.startPrank(CREATOR);
        uint256 proceed = marketPlace.getProceed();

        vm.expectEmit(true, false, false, true);

        emit MarketPlace.ProceedWithdrawal(CREATOR, proceed);

        marketPlace.withdrawProceed();

        vm.stopPrank();
    }

    function test_withdrawProceed_revertsIfNotCreator() public listNft {
        vm.startPrank(USER1);
        marketPlace.buyNFT{value: NFT_PRICE}(
            address(nftCollection),
            INTIAL_TOKENID
        );

        vm.expectRevert(MarketPlace.MarketPlace__NoPendingWithdrawal.selector);
        marketPlace.withdrawRoyalties();

        vm.stopPrank();
    }

    function test_withdRoyalties_emitEventSucessfully() public listNft {
        vm.startPrank(USER1);
        marketPlace.buyNFT{value: NFT_PRICE}(
            address(nftCollection),
            INTIAL_TOKENID
        );
        vm.stopPrank();

        vm.startPrank(CREATOR);
        (, uint256 amount) = ERC2981(address(nftCollection)).royaltyInfo(
            INTIAL_TOKENID,
            NFT_PRICE
        );

        vm.expectEmit(true, false, false, true);

        emit MarketPlace.RoyaltiesWithdrawal(CREATOR, amount);

        marketPlace.withdrawRoyalties();

        vm.stopPrank();
    }

    function test_bidNft_RevertsIfAlreadySold() public listAuctionNft {
        vm.startPrank(USER1);
        mockMarketPlace.forceSold(address(nftCollection), INTIAL_TOKENID);

        vm.expectRevert(MarketPlace.MarketPlace__AlreadySold.selector);

        mockMarketPlace.bidNft{value: NFT_PRICE}(
            address(nftCollection),
            INTIAL_TOKENID
        );

        vm.stopPrank();
    }

    function test_bidNft_RevertsIfFixedSalesType() public listNft {
        vm.startPrank(USER1);
        vm.expectRevert(MarketPlace.MarketPlace__NotAuctionNFT.selector);
        marketPlace.bidNft{value: NFT_PRICE}(
            address(nftCollection),
            INTIAL_TOKENID
        );

        vm.stopPrank();
    }

    function test_bidNft_RevertsIfTimePassed() public listAuctionNft {
        vm.startPrank(USER1);

        skip((AUCTION_SALES_DURATION * 1 days) + 1);

        vm.expectRevert(MarketPlace.MarketPlace__AuctionAlreadyEnded.selector);
        marketPlace.bidNft{value: NFT_PRICE}(
            address(nftCollection),
            INTIAL_TOKENID
        );

        vm.stopPrank();
    }

    function test_bidNft_RevertsIfBidisLow() public listAuctionNft {
        vm.startPrank(USER1);

        vm.expectRevert(MarketPlace.MarketPlace__BidTooLow.selector);
        marketPlace.bidNft{value: LISTED_PRICE}(
            address(nftCollection),
            INTIAL_TOKENID
        );

        vm.stopPrank();
    }

    function test_bidNft_higgestBidder() public listAuctionNft {
        vm.startPrank(USER1);
        marketPlace.bidNft{value: NFT_PRICE}(
            address(nftCollection),
            INTIAL_TOKENID
        );
        vm.stopPrank();

        vm.startPrank(USER2);
        marketPlace.bidNft{value: 8 ether}(
            address(nftCollection),
            INTIAL_TOKENID
        );
        vm.stopPrank();

        vm.startPrank(USER3);
        marketPlace.bidNft{value: 10 ether}(
            address(nftCollection),
            INTIAL_TOKENID
        );
        vm.stopPrank();

        MarketPlace.Listing memory _listing = marketPlace
            .getListedTokenPriceFromTokenID(
                address(nftCollection),
                INTIAL_TOKENID
            );
        assertTrue(_listing.highestBidder == USER3);
        assertEq(_listing.highestBid, 10 ether);
    }
}

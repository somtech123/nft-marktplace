// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract MarketPlace is ReentrancyGuard {
    enum SaleType {
        FIXED,
        AUCTION
    }

    struct Listing {
        address seller;
        uint256 price;
        SaleType saleType;
        uint256 endTime;
        uint256 highestBid;
        address highestBidder;
        bool sold;
    }

    error MarketPlace__ZeroAddressNFTContract();
    error MarketPlace__NotNFTOwner();
    error MarketPlace__NFTNotApproved();
    error MarketPlace__InValidTokenId();
    error MarketPlace__InValidPrice();
    error MarketPlace__InValidListing();
    error MarketPlace__InsufficientPayment();
    error MarketPlace__ListingNotFound();
    error MarketPlace__NoPendingWithdrawal();
    error MarketPlace__TransferFailed();
    error MarketPlace__NotFixedNFT();
    error MarketPlace__NotAuctionNFT();
    error MarketPlace__AlreadySold();
    error MarketPlace__AuctionAlreadyEnded();
    error MarketPlace__BidTooLow();

    event NFTListed(
        address indexed seller,
        address indexed nftContractAddress,
        uint256 tokenID,
        uint256 price
    );

    event NFTPriceUpdated(
        address indexed nftContractAddress,
        uint256 tokenID,
        uint256 price
    );

    event CancelListedNFT(
        address indexed seller,
        address indexed nftContractAddress,
        uint256 tokenID
    );
    event BoughtNFT(
        address indexed nftContractAddress,
        address indexed seller,
        address indexed buyer,
        uint256 tokenID,
        uint256 price
    );
    event ProceedWithdrawal(address indexed seller, uint256 price);
    event RoyaltiesWithdrawal(address indexed seller, uint256 price);

    event BidPlaced(
        address indexed bidder,
        address indexed nftContractAddress,
        uint256 tokenID,
        uint price
    );

    mapping(address => mapping(uint256 => Listing)) listing;
    mapping(address => uint256) pendingBidReturns;
    uint256 public marketPlaceFee = 250; //basic point 2.5%

    mapping(address => uint256) royaltiesPendingWithdrawal;
    mapping(address => uint256) sellersPendingWithdrawal;

    // mapping(address => uint256) feesPeningWithdrawal;

    function isNftApproved(
        address nftContractAddress,
        uint256 tokenId
    ) internal view returns (bool) {
        return
            IERC721(nftContractAddress).getApproved(tokenId) == address(this);
    }

    function isApproveAllCollection(
        address nftContractAddress
    ) internal view returns (bool) {
        return
            IERC721(nftContractAddress).isApprovedForAll(
                msg.sender,
                address(this)
            );
    }

    function list_nft(
        address nftContractAddress,
        uint256 tokenID,
        uint256 priceInWei,
        // SaleType _saleType,
        uint256 _duration
    ) external {
        uint256 releaseTime;

        if (nftContractAddress == address(0)) {
            revert MarketPlace__ZeroAddressNFTContract();
        }

        if (priceInWei == 0) revert MarketPlace__InValidPrice();

        if (IERC721(nftContractAddress).ownerOf(tokenID) != msg.sender) {
            revert MarketPlace__NotNFTOwner();
        }
        if (_duration != 0) {
            releaseTime = _duration * 1 days;
        }

        // if (IERC721(nftContractAddress).ownerOf(tokenID) == address(0))
        //     revert MarketPlace__InValidTokenId();

        bool approval = isNftApproved(nftContractAddress, tokenID);
        bool approvedAll = isApproveAllCollection(nftContractAddress);

        if (!approval && !approvedAll) revert MarketPlace__NFTNotApproved();

        listing[nftContractAddress][tokenID] = Listing({
            seller: msg.sender,
            price: priceInWei,
            saleType: _duration == 0 ? SaleType.FIXED : SaleType.AUCTION,
            endTime: _duration == 0 ? 0 : block.timestamp + releaseTime,
            highestBid: 0,
            highestBidder: address(0),
            sold: false
        });

        emit NFTListed(msg.sender, nftContractAddress, tokenID, priceInWei);
    }

    function updateListedNftPrice(
        address nftContractAddress,
        uint256 tokenID,
        uint256 newPriceInWei
    ) external {
        Listing memory _listing = listing[nftContractAddress][tokenID];
        if (_listing.sold == true) revert MarketPlace__AlreadySold();
        if (_listing.seller == address(0))
            revert MarketPlace__ListingNotFound();

        if (_listing.seller != msg.sender) revert MarketPlace__NotNFTOwner();
        if (newPriceInWei == 0) revert MarketPlace__InValidPrice();

        listing[nftContractAddress][tokenID].price = newPriceInWei;

        emit NFTPriceUpdated(nftContractAddress, tokenID, newPriceInWei);
    }

    function cancelListedNFT(
        address nftContractAddress,
        uint256 tokenID
    ) external {
        Listing memory _listing = listing[nftContractAddress][tokenID];
        if (_listing.sold == true) revert MarketPlace__AlreadySold();
        if (_listing.seller == address(0))
            revert MarketPlace__ListingNotFound();

        if (_listing.seller != msg.sender) revert MarketPlace__NotNFTOwner();

        delete listing[nftContractAddress][tokenID];

        emit CancelListedNFT(msg.sender, nftContractAddress, tokenID);
    }

    function buyNFT(
        address nftContractAddress,
        uint256 tokenID
    ) external payable nonReentrant {
        Listing memory _listing = listing[nftContractAddress][tokenID];
        if (_listing.sold == true) revert MarketPlace__AlreadySold();
        if (_listing.saleType == SaleType.AUCTION)
            revert MarketPlace__NotFixedNFT();

        if (_listing.seller == address(0))
            revert MarketPlace__ListingNotFound();

        if (msg.value < _listing.price)
            revert MarketPlace__InsufficientPayment();

        uint256 salesPrice = _listing.price;
        _listing.sold = true;

        delete listing[nftContractAddress][tokenID];

        //calculate royalties
        (address receiver, uint256 royaltyAmount) = ERC2981(nftContractAddress)
            .royaltyInfo(tokenID, salesPrice);

        uint256 fee = (salesPrice * marketPlaceFee) / 10000;

        uint256 sellerAmount = salesPrice - royaltyAmount - fee;

        royaltiesPendingWithdrawal[receiver] += royaltyAmount;
        sellersPendingWithdrawal[_listing.seller] += sellerAmount;

        IERC721(nftContractAddress).safeTransferFrom(
            _listing.seller,
            msg.sender,
            tokenID
        );

        emit BoughtNFT(
            nftContractAddress,
            _listing.seller,
            msg.sender,
            tokenID,
            msg.value
        );

        if (fee > 0) {
            (bool _success, ) = payable(address(this)).call{value: fee}("");
            require(_success, "Fee Transfer Failed");
        }
    }

    function withdrawProceed() external nonReentrant {
        uint256 amount = sellersPendingWithdrawal[msg.sender];
        if (amount == 0) revert MarketPlace__NoPendingWithdrawal();
        sellersPendingWithdrawal[msg.sender] = 0;

        emit ProceedWithdrawal(msg.sender, amount);

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert MarketPlace__TransferFailed();
    }

    function withdrawRoyalties() external nonReentrant {
        uint256 amount = royaltiesPendingWithdrawal[msg.sender];
        if (amount == 0) revert MarketPlace__NoPendingWithdrawal();

        royaltiesPendingWithdrawal[msg.sender] = 0;
        emit RoyaltiesWithdrawal(msg.sender, amount);

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert MarketPlace__TransferFailed();
    }

    function bidNft(
        address nftContractAddress,
        uint256 tokenID
    ) external payable nonReentrant {
        Listing memory _listing = listing[nftContractAddress][tokenID];

        if (_listing.sold == true) revert MarketPlace__AlreadySold();
        if (_listing.saleType == SaleType.FIXED)
            revert MarketPlace__NotAuctionNFT();
        if (block.timestamp > _listing.endTime)
            revert MarketPlace__AuctionAlreadyEnded();
        if (msg.value <= _listing.highestBid + _listing.price)
            revert MarketPlace__BidTooLow();

        if (_listing.highestBidder != address(0)) {
            pendingBidReturns[_listing.highestBidder] += _listing.highestBid;
        }

        listing[nftContractAddress][tokenID].highestBidder = msg.sender;
        listing[nftContractAddress][tokenID].highestBid = msg.value;

        emit BidPlaced(msg.sender, nftContractAddress, tokenID, msg.value);
    }

    function getProceed() external view returns (uint256) {
        return sellersPendingWithdrawal[msg.sender];
    }

    function getListedTokenPriceFromTokenID(
        address nftContractAddress,
        uint256 tokenID
    ) public view returns (Listing memory) {
        return listing[nftContractAddress][tokenID];
    }

    receive() external payable {}
}

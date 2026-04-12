// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract MarketPlace {
    error MarketPlace__ZeroAddressNFTContract();
    error MarketPlace__NotNFTOwner();
    error MarketPlace__NFTNotApproved();
    error MarketPlace__InValidTokenId();
    error MarketPlace__InValidPrice();

    event NFTListed(
        address indexed seller,
        address indexed nftContractAddress,
        uint256 tokenID,
        uint256 price
    );

    struct Listing {
        address seller;
        uint256 price;
    }

    mapping(address => mapping(uint256 => Listing)) listing;

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
        uint256 priceInWei
    ) external {
        if (nftContractAddress == address(0))
            revert MarketPlace__ZeroAddressNFTContract();

        if (priceInWei == 0) revert MarketPlace__InValidPrice();

        if (IERC721(nftContractAddress).ownerOf(tokenID) != msg.sender)
            revert MarketPlace__NotNFTOwner();

        // if (IERC721(nftContractAddress).ownerOf(tokenID) == address(0))
        //     revert MarketPlace__InValidTokenId();

        bool approval = isNftApproved(nftContractAddress, tokenID);
        bool approvedAll = isApproveAllCollection(nftContractAddress);

        if (!approval && !approvedAll) revert MarketPlace__NFTNotApproved();

        listing[nftContractAddress][tokenID] = Listing({
            seller: msg.sender,
            price: priceInWei
        });

        emit NFTListed(msg.sender, nftContractAddress, tokenID, priceInWei);
    }

    function getListedTokenPriceFromTokenID(
        address nftContractAddress,
        uint256 tokenID
    ) public view returns (Listing memory) {
        return listing[nftContractAddress][tokenID];
    }
}

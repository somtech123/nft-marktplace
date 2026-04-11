// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;
import {NftCollection} from "./NftCollection.sol";

contract NftFactory {
    /******************************************************************************
     *                              Errors                                        *
     ******************************************************************************/
    error NftFactory__ZeroAddressCreator();
    error NftFactory__EmptyNFTName();
    error NftFactory__EmptyNFTSymbol();

    /******************************************************************************
     *                                   events                                   *
     ******************************************************************************/
    event CollectionCreated(string name, string nftSymbol);

    uint256 private collectionCounter;
    string public baseURI;
    mapping(address => bool) private isValidCollection;

    constructor(string memory _baseURI) {
        baseURI = _baseURI;
    }

    /******************************************************************************
     *                             external functions                             *
     ******************************************************************************/

    function createNftCollection(
        string memory nftName,
        string memory nftSymbol
    ) external returns (address) {
        if (msg.sender == address(0)) revert NftFactory__ZeroAddressCreator();
        if (bytes(nftName).length == 0 || _isBlankSpace(nftName))
            revert NftFactory__EmptyNFTName();
        if (bytes(nftSymbol).length == 0 || _isBlankSpace(nftSymbol))
            revert NftFactory__EmptyNFTSymbol();

        collectionCounter++;

        NftCollection nft = new NftCollection(
            baseURI,
            nftName,
            nftSymbol,
            msg.sender,
            address(this)
        );
        isValidCollection[address(nft)] = true;

        emit CollectionCreated(nftName, nftSymbol);

        return address(nft);
    }

    /******************************************************************************
     *                               view functions                               *
     ******************************************************************************/

    function isNftValidCollection(
        address nftCollection
    ) public view returns (bool) {
        return isValidCollection[nftCollection];
    }

    function getCollectionCounter() public view returns (uint256) {
        return collectionCounter;
    }

    function _isBlankSpace(string memory str) internal pure returns (bool) {
        bytes memory b = bytes(str);
        for (uint256 i = 0; i < b.length; i++) {
            if (b[i] != 0x20) return false; // 0x20 = space character
        }
        return true;
    }
}

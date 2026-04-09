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
    mapping(address => bool) private isValidCollection;

    /******************************************************************************
     *                             external functions                             *
     ******************************************************************************/

    function createNftCollection(
        string memory nftName,
        string memory nftSymbol
    ) external returns (address) {
        if (msg.sender == address(0)) revert NftFactory__ZeroAddressCreator();
        if (bytes(nftName).length < 0) revert NftFactory__EmptyNFTName();
        if (bytes(nftSymbol).length < 0) revert NftFactory__EmptyNFTSymbol();

        collectionCounter++;

        NftCollection nft = new NftCollection(
            nftName,
            nftSymbol,
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
}

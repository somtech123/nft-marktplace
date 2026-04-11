// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {NftFactory} from "./NftFactory.sol";

using Strings for uint256;

contract NftCollection is ERC721, Ownable {
    error NftCollection__ZeroAddressFactory();
    error NftCollection__EmptyNFTName();
    error NftCollection__EmptyNFTSymbol();
    error NftCollection__InValidCollection();
    error NftCollection__InValidTokenId();

    string private baseURI;
    string private i_nftName;
    string private i_nftSymbol;
    address private immutable factory_address;
    uint256 private _nextTokenId;

    constructor(
        string memory _baseURI,
        string memory _nftName,
        string memory _nftSymbol,
        address _creator,
        address _factoryAddress
    ) ERC721(_nftName, _nftSymbol) Ownable(_creator) {
        if (_factoryAddress == address(0))
            revert NftCollection__ZeroAddressFactory();
        if (bytes(_nftName).length == 0) revert NftCollection__EmptyNFTName();
        if (bytes(_nftSymbol).length == 0)
            revert NftCollection__EmptyNFTSymbol();
        baseURI = _baseURI;

        i_nftName = _nftName;
        i_nftSymbol = _nftSymbol;
        factory_address = _factoryAddress;
    }

    modifier isValidCollection() {
        if (!NftFactory(factory_address).isNftValidCollection(address(this)))
            revert NftCollection__InValidCollection();
        _;
    }

    /******************************************************************************
     *                             external function                              *
     ******************************************************************************/

    function mintNft() external onlyOwner isValidCollection {
        uint256 tokenId = _nextTokenId;
        _safeMint(msg.sender, tokenId);
        _nextTokenId++;
    }

    function tokenURI(
        uint256 tokenID
    ) public view override returns (string memory) {
        if (_ownerOf(tokenID) == address(0))
            revert NftCollection__InValidTokenId();

        return string(abi.encodePacked(baseURI, tokenID.toString(), ".json"));
    }

    /******************************************************************************
     *                               view functions                               *
     ******************************************************************************/

    function getNftName() public view returns (string memory) {
        return i_nftName;
    }

    function getNftSymbol() public view returns (string memory) {
        return i_nftSymbol;
    }

    function getTokenIDCounter() public view returns (uint256) {
        return _nextTokenId;
    }
}

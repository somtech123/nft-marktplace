// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;
import {NftFactory} from "./NftFactory.sol";

contract NftCollection {
    string private i_nftName;
    string private i_nftSymbol;
    address private immutable factory_address;

    constructor(
        string memory _nftName,
        string memory _nftSymbol,
        address _factoryAddress
    ) {
        i_nftName = _nftName;
        i_nftSymbol = _nftSymbol;
        factory_address = _factoryAddress;
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
}

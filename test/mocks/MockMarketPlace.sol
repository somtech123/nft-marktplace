// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;
import {MarketPlace} from "../../src/MarketPlace.sol";

contract MockMarketPlace is MarketPlace {
    function forceSold(address nftContractAddress, uint256 tokenID) external {
        listing[nftContractAddress][tokenID].sold = true;
    }
}

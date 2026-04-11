// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {NftFactory} from "../src/NftFactory.sol";

contract DeployNft is Script {
    function run() external returns (NftFactory) {
        vm.startBroadcast();
        string memory baseURI = "ipfs://";
        NftFactory nftFactory = new NftFactory(baseURI);

        vm.stopBroadcast();

        return nftFactory;
    }
}

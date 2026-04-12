// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {NftFactory} from "../src/NftFactory.sol";

//0x1C5D8111d75ee3A30d27b2adbA605E3A010Fa1BC
contract DeployNft is Script {
    function run() external returns (NftFactory) {
        vm.startBroadcast();
        string
            memory baseURI = "ipfs://bafybeif4d4ajetwhmy4cn44j4hfliwgkx422qq5q56ljlzxbl53t67crmy/";
        NftFactory nftFactory = new NftFactory(baseURI);

        vm.stopBroadcast();

        return nftFactory;
    }
}

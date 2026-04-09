// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;
import {Test} from "forge-std/Test.sol";
import {DeployNft} from "../../script/DeployNft.s.sol";
import {NftFactory} from "../../src/NftFactory.sol";

contract NftFactoryTest is Test {
    NftFactory nftFactory;

    uint256 constant STARTING_BALANCE = 10 ether;

    address CREATOR = makeAddr("CREATOR");

    function setUp() external {
        DeployNft depoyNft = new DeployNft();

        nftFactory = depoyNft.run();

        vm.deal(CREATOR, STARTING_BALANCE);
    }

    modifier isCreator() {
        vm.startPrank(CREATOR);
        _;
        vm.stopPrank();
    }
}

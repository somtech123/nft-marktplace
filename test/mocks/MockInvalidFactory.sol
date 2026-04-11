// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.24;

// Mock factory that always returns false
contract MockInvalidFactory {
    function isNftValidCollection(address) external pure returns (bool) {
        return false;
    }
}

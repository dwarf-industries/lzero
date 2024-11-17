// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

struct Oracle {
    address name;
    string ip;
    string port;
    uint256 reputation; 
}
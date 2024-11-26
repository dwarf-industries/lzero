// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;


contract FeeSetter {
    address private Owner;
    uint256 private costPerKilobyte;
    
    constructor(uint256 _fee) {
        costPerKilobyte = _fee;
        Owner = msg.sender;
    }   

    function changeFee(uint256 fee) public payable onlyDao returns (bool) {
        costPerKilobyte = fee;
        return true;
    }

    function getCostPerKylobyte() external view  returns (uint256) {
        return costPerKilobyte;
    }

    modifier onlyDao() {
        require(msg.sender == Owner, "Not authorized");
        _;
    }

}
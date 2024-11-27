// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;


contract FeeSetter {
    address private Owner;
    uint256 private costPerKilobyte;
    uint256 private networkFee;
    address private networkFeeCollector;

    constructor(uint256 _fee, address _networkFeeCollector, uint256 _networkFee) {
        costPerKilobyte = _fee;
        networkFeeCollector = _networkFeeCollector; 
        networkFee = _networkFee;
        Owner = msg.sender;
    }   

    function changeNetworkFee(uint256 fee) public payable onlyDao returns (bool) {
        networkFee = fee;
        return true;
    }

    function changeFee(uint256 fee) public payable onlyDao returns (bool) {
        costPerKilobyte = fee;
        return true;
    }

    function getCostPerKylobyte() external view  returns (uint256) {
        return costPerKilobyte;
    }

    function getNetworkFee() external view returns (uint256) {
        return networkFee;
    }

    modifier onlyDao() {
        require(msg.sender == Owner, "Not authorized");
        _;
    }

}
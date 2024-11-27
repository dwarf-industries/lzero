// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

interface IFeeSetter {
    function changeFee(uint256 fee) external payable returns (bool);
    function getCostPerKilobyte() external view returns (uint256);
    function getNetworkFee() external view returns (uint256);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;
import "../interfaces/IFeeSetter.sol";

contract PaymentLedger {
    IFeeSetter feeSetter;    
    mapping(bytes32 => bool) public processedPayments;
    event PaymentReceived(address indexed payer, bytes32 paymentID, uint256 amount);

    constructor(address _feeSetter) {
        feeSetter = IFeeSetter(_feeSetter);
    }

    function paymentProcessed(bytes32 paymentId) external view returns (bool) {
        return processedPayments[paymentId];
    }

    function recordPayment(bytes32 paymentID, uint256 dataSize) external payable {
        require(msg.value > 0, "Payment must be greater than zero");

        uint256 costPerKilobyte = feeSetter.getCostPerKilobyte();
        uint256 expectedValue = (dataSize + 1023) / 1024 * costPerKilobyte;  

        require(msg.value == expectedValue, "Incorrect payment amount for the given data size");
        require(!processedPayments[paymentID], "Payment already processed");

        processedPayments[paymentID] = true;
        emit PaymentReceived(msg.sender, paymentID, msg.value, dataSize);
    }
}

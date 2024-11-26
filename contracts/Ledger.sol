// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

contract PaymentLedger {
    mapping(bytes32 => bool) public processedPayments;

    event PaymentReceived(address indexed payer, bytes32 paymentID, uint256 amount);

    function paymentProcessed(bytes32 paymentId) external view returns (bool) {
        return processedPayments[paymentId];
    }

    function recordPayment(bytes32 paymentID) external payable {
        require(msg.value > 0, "Payment must be greater than zero");
        require(!processedPayments[paymentID], "Payment already processed");

        processedPayments[paymentID] = true;

        emit PaymentReceived(msg.sender, paymentID, msg.value);
    }
}

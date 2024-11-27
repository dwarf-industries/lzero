// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;
import "../interfaces/IFeeSetter.sol";

contract PaymentLedger {
    IFeeSetter feeSetter;

    // Struct to hold the outstanding payment for a specific node and paymentId
    struct Payment {
        uint256 amount; // Amount owed for a given payment ID
        bool claimed;   // Whether the payment has been claimed
    }

    // Mapping of paymentId to the outstanding payment
    mapping(bytes32 => Payment) private outstandingPayments;

    // Array to track all the payment IDs
    bytes32[] private paymentIDs;

    // Event to notify when a payment is processed
    event PaymentReceived(bytes32[] paymentIDs, uint256 totalAmount);
 

    constructor(address _feeSetter) {
        feeSetter = IFeeSetter(_feeSetter);
    }

    // A function that calculates the correct cost per kilobyte, including the 5% network fee
    function calculatePayment(uint256 dataSize) public view returns (uint256 totalAmount, uint256 networkFee) {
        uint256 costPerKilobyte = feeSetter.getCostPerKilobyte();
        uint256 expectedValue = (dataSize + 1023) / 1024 * costPerKilobyte;  

        // Calculate the network fee (% of the total amount)
        networkFee = (expectedValue * feeSetter.getNetworkFee()) / 100;
        totalAmount = expectedValue + networkFee;
    }

    /**
     * @dev Record multiple payments. The user sends a list of payment IDs, and a single transaction value.
     * The total value is split evenly across the payments.
     * The contract also collects a 5% fee for the network.
     */
    function recordPayment(bytes32[] calldata paymentIDsList) external payable {
        require(paymentIDsList.length > 0, "At least one payment ID required");
        require(msg.value > 0, "Payment must be greater than zero");

        uint256 totalAmount = msg.value;
        uint256 networkFee;
        uint256 amountPerPayment;

        // Calculate the total payment and network fee
        (totalAmount, networkFee) = calculatePayment(totalAmount);

        // Ensure the network fee is deducted
        uint256 amountForNodes = totalAmount - networkFee;
        amountPerPayment = amountForNodes / paymentIDsList.length;

        // Ensure the amount per payment is correctly distributed
        require(amountPerPayment * paymentIDsList.length == amountForNodes, "Incorrect amount distribution");

        // Record the payment for each payment ID
        for (uint256 i = 0; i < paymentIDsList.length; i++) {
            bytes32 paymentID = paymentIDsList[i];
            require(!outstandingPayments[paymentID].claimed, "Payment ID already processed");

            // Store the payment amount for each payment ID
            outstandingPayments[paymentID] = Payment(amountPerPayment, false);

            // Add the payment ID to the array for iteration later
            paymentIDs.push(paymentID);
        }

        // Emit the event for payment processing
        emit PaymentReceived(paymentIDsList, totalAmount);
    }

   
    // Claim function, iterating over the array of payment IDs
    function claim() external {
        uint256 totalClaimed = 0;

        // Iterate over the paymentIDs array to find eligible payments
        for (uint256 i = 0; i < paymentIDs.length; i++) {
            bytes32 paymentID = paymentIDs[i];
            Payment storage payment = outstandingPayments[paymentID];

            // Check if the paymentID is eligible for this node (based on the address)
            if (isNodeEligibleForPayment(paymentID, msg.sender)) {
                require(payment.amount > 0, "No payment available for this payment ID");
                require(!payment.claimed, "Payment already claimed");

                // Mark the payment as claimed
                payment.claimed = true;

                // Add the payment amount to the total claimed
                totalClaimed += payment.amount;
            }
        }

        // Ensure that there is something to claim
        require(totalClaimed > 0, "No payments available for claiming");

        // Transfer the total claimed amount to the node
        payable(msg.sender).transfer(totalClaimed);
 
    }

    /**
     * @dev Helper function to determine if the paymentID is linked to the node's address.
     * Modify this logic based on how payment IDs are constructed.
     */
    function isNodeEligibleForPayment(bytes32 paymentID, address nodeAddress) internal pure returns (bool) {
        bytes32 expectedPaymentID = keccak256(abi.encodePacked(nodeAddress));

        // Compare the calculated hash with the provided paymentID
        return paymentID == expectedPaymentID;
    }

    // Check oustnading reward balance
    function balance() external view returns (uint256) {
        uint256 totalToClaim = 0;

        for (uint256 i = 0; i < paymentIDs.length; i++) {
            bytes32 paymentID = paymentIDs[i];
            Payment storage payment = outstandingPayments[paymentID];

            // Check if the paymentID is eligible for this node (based on the address)
            if (isNodeEligibleForPayment(paymentID, msg.sender)) {
                require(payment.amount > 0, "No payment available for this payment ID");
                require(!payment.claimed, "Payment already claimed");

                totalToClaim += payment.amount;
            }
        }

        return totalToClaim;
    }
 
}

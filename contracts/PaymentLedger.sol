// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;
import "../interfaces/IFeeSetter.sol";
import "../structures/Payment.sol";

contract PaymentLedger {
    IFeeSetter feeSetter;

 
    mapping(string => Payment) private outstandingPayments;
    string[] private paymentIDs;
    event PaymentReceived(string[] paymentIDs, uint256 totalAmount);
 

    constructor(address _feeSetter) {
        feeSetter = IFeeSetter(_feeSetter);
    }

    function calculatePayment(uint256 dataSize) public view returns (uint256 totalAmount, uint256 networkFee) {
        uint256 costPerKilobyte = feeSetter.getCostPerKilobyte();
        uint256 expectedValue = (dataSize + 1023) / 1024 * costPerKilobyte;  

        networkFee = (expectedValue * feeSetter.getNetworkFee()) / 100;
        totalAmount = expectedValue + networkFee;
    }
 
    function recordPayment(string[] memory paymentIDsList) external payable {
        require(paymentIDsList.length > 0, "At least one payment ID required");
        require(msg.value > 0, "Payment must be greater than zero");

        uint256 totalAmount = msg.value;
        uint256 networkFee;
        uint256 amountPerPayment;

        (totalAmount, networkFee) = calculatePayment(totalAmount);

        uint256 amountForNodes = totalAmount - networkFee;
        amountPerPayment = amountForNodes / paymentIDsList.length;

        require(amountPerPayment * paymentIDsList.length == amountForNodes, "Incorrect amount distribution");

        for (uint256 i = 0; i < paymentIDsList.length; i++) {
            string memory paymentID = paymentIDsList[i];
            require(!outstandingPayments[paymentID].claimed, "Payment ID already processed");

            outstandingPayments[paymentID] = Payment(amountPerPayment, false);
            paymentIDs.push(paymentID);
        }

        emit PaymentReceived(paymentIDsList, totalAmount);
    }

   
    function claim() external {
        uint256 totalClaimed = 0;

        for (uint256 i = 0; i < paymentIDs.length; i++) {
            string memory paymentID = paymentIDs[i];
            Payment storage payment = outstandingPayments[paymentID];

            if (isNodeEligibleForPayment(paymentID, msg.sender)) {
                require(payment.amount > 0, "No payment available for this payment ID");
                require(!payment.claimed, "Payment already claimed");

                payment.claimed = true;

                totalClaimed += payment.amount;
            }
        }

        require(totalClaimed > 0, "No payments available for claiming");

        payable(msg.sender).transfer(totalClaimed);
 
    }
 
    
    function paymentProcessed(string memory paymentId) external view returns (bool) {
        Payment memory p = outstandingPayments[paymentId];
        return p.amount > 0;
    }
    
    function isNodeEligibleForPayment(string memory paymentID, address nodeAddress) internal pure returns (bool) {
        string memory node = addressToString(nodeAddress);
        bool eligible = contains(paymentID, node);
        return eligible;
    }

    function balance() external view returns (uint256) {
        uint256 totalToClaim = 0;

        for (uint256 i = 0; i < paymentIDs.length; i++) {
            string memory paymentID = paymentIDs[i];
            Payment storage payment = outstandingPayments[paymentID];

            if (isNodeEligibleForPayment(paymentID, msg.sender)) {
                require(payment.amount > 0, "No payment available for this payment ID");
                require(!payment.claimed, "Payment already claimed");

                totalToClaim += payment.amount;
            }
        }

        return totalToClaim;
    } 

    function contains (string memory what, string memory where) internal pure returns (bool) {
        bytes memory whatBytes = bytes (what);
        bytes memory whereBytes = bytes (where);

        require(whereBytes.length >= whatBytes.length);

        bool found = false;
        for (uint i = 0; i <= whereBytes.length - whatBytes.length; i++) {
            bool flag = true;
            for (uint j = 0; j < whatBytes.length; j++)
                if (whereBytes [i + j] != whatBytes [j]) {
                    flag = false;
                    break;
                }
            if (flag) {
                found = true;
                break;
            }
        }

        return found;
    }

    function addressToString(address _address) internal pure returns (string memory) {
        bytes memory addressBytes = abi.encodePacked(_address);
        bytes memory hexString = new bytes(42);  

        hexString[0] = '0';
        hexString[1] = 'x';

        for (uint256 i = 0; i < 20; i++) {
            uint8 byteValue = uint8(addressBytes[i]);
            hexString[2 + i * 2] = byteToChar(byteValue / 16);
            hexString[3 + i * 2] = byteToChar(byteValue % 16);
        }

        return string(hexString);
    }


    function byteToChar(uint8 _byte) internal pure returns (bytes1) {
        if (_byte < 10) {
            return bytes1(_byte + 48); 
        } else {
            return bytes1(_byte + 87);  
        }
    }
}

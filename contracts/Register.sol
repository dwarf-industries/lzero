// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import "../structures/Oracle.sol";
import "../interfaces/IFeeSetter.sol";

contract Register {
    IFeeSetter feeSetter;
    Oracle[] private oracles;
    uint256 private registerTaxPercentage = 5;
    uint256 private registerFee;
    uint256 private reportFee;
    address private dao;
    bool private isRevoked = false;

    mapping(address => mapping(address => bool)) private oracleReports;
    mapping(address => uint256) private reportCounts;
    mapping(address => uint256) private oracleIndex;
    mapping(address => uint256) private rewards;
    mapping(address => uint256) private stakes;

    event OracleRegistered(address indexed oracleAddress, string ip, string port);
    event OracleReported(address indexed reporter, address indexed reportedOracle);
    event OracleBlacklisted(address indexed blacklistedOracle);
    event OracleRegisterTaxUpdated(uint256 newTax);
    event OracleOnline(address indexed oracleAddress);
    event OracleOffline(address indexed oracleAddress);

    constructor(uint256 _registerFee, uint256 _reportFee, address _feeSetter, address daoOwner) {
        registerFee = _registerFee;
        reportFee = _reportFee;
        feeSetter = IFeeSetter(_feeSetter);
        dao = daoOwner;
    }

    function register(string memory ip, string memory port) public payable returns (bool) {
        require(msg.value >= registerFee, "Insufficient registration fee");

        oracles.push(Oracle({
            name: msg.sender,
            ip: ip,
            port: port,
            reputation: 1,
            isOnline: true
        }));

        oracleIndex[msg.sender] = oracles.length - 1;  

        uint256 registrationTax = (registerFee * registerTaxPercentage) / 100;
        uint256 stakeAmount = msg.value - registrationTax;
        address taxCollector = feeSetter.getNetworkFeeCollector();
        payable(taxCollector).transfer(registrationTax);
        stakes[msg.sender] = stakeAmount;

        emit OracleRegistered(msg.sender, ip, port);
        return true;
    }

    function LogOut() public onlyOracle returns (bool) {
        uint256 index = oracleIndex[msg.sender];
        oracles[index].isOnline = false;
        emit OracleOffline(msg.sender);
        return true;
    }

    function Login() public onlyOracle returns (bool) {
        uint256 index = oracleIndex[msg.sender];
        oracles[index].isOnline = true;
        emit OracleOnline(msg.sender);
        return true;
    }

    function self() external view onlyOracle returns (Oracle memory) {
        uint256 index = oracleIndex[msg.sender];
        require(index < oracles.length, "Invalid oracle index");
        return oracles[index];
    }

    function getOracle(address _oracle) external view onlyOracle returns (Oracle memory) {
        uint256 index = oracleIndex[_oracle];
        require(index < oracles.length, "Invalid oracle index");
        return oracles[index];
    }
 
    function changeRegisterTax(uint256 tax) external onlyDao returns (bool) {
        registerTaxPercentage = tax;
        emit OracleRegisterTaxUpdated(tax);
        return true;
    }

    function revokeOwnership() public onlyDao returns (bool) {
        isRevoked = true;
        return true;
    }

    function isOracleRegistered() external view returns (bool) {
        uint256 index = oracleIndex[msg.sender];
        return index < oracles.length && oracles[index].name == msg.sender;
    }

    function getRegistrationFee() external view returns (uint256) {
        return registerFee;
    }

    function getReportFee() external view returns (uint256) {
        return reportFee;
    }

    function updateRegistrationFee(uint256 fee) external onlyDao returns (bool) {
        registerFee = fee;
        return true;
    }

    function updateReportFee(uint256 fee) external onlyDao returns (bool) {
        reportFee = fee;
        return true;
    }

    function getOracles() external view returns (Oracle[] memory) {
        return oracles;
    }
 
    modifier onlyOracle() {
        uint256 index = oracleIndex[msg.sender];
        require(index < oracles.length, "Not an authorized oracle");
        require(oracles[index].name == msg.sender, "Oracle mismatch at index");
        _;
    }

    modifier onlyDao() {
        require(!isRevoked, "Ownership is revoked, no administrative changes allowed!");
        require(msg.sender == dao, "Not authorized");
        _;
    }
}

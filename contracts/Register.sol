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
    mapping(address => bool) private blacklisted;  
    mapping(address => uint256) private rewards;
    mapping(address => uint256) private stakes;  

    event OracleRegistered(address indexed oracleAddress, string ip, string port);
    event OracleReported(address indexed reporter, address indexed reportedOracle);
    event OracleBlacklisted(address indexed blacklistedOracle);
    event OracleRegisterTaxUpdated(uint256 newTax);

    constructor(uint256 _registerFee, uint256 _reportFee, address _feeSetter, address daoOwner) {
        registerFee = _registerFee;
        reportFee = _reportFee;
        feeSetter = IFeeSetter(_feeSetter);
        dao = daoOwner;
    }

    function register(string memory ip, string memory port) public payable returns (bool) {
        require(msg.value >= registerFee, "Insufficient registration fee");
        require(!blacklisted[msg.sender], "Cannot register a blacklisted oracle");

        oracles.push(Oracle({
            name: msg.sender,
            ip: ip,
            port: port,
            reputation: 1 
        }));

        uint256 registrationTax = (registerFee * registerTaxPercentage) / 100;
        uint256 stakeAmount = msg.value - registrationTax;
        address taxCollector = feeSetter.getNetworkFeeCollector();
        payable(taxCollector).transfer(registrationTax);
        stakes[msg.sender] = stakeAmount;  

        emit OracleRegistered(msg.sender, ip, port);
        return true;
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
        for (uint i = 0; i < oracles.length; i++) {
            Oracle memory oracle = oracles[i];
            if(oracle.name == msg.sender) {
                return true;
            }
        }

        return false;
    }

    function getRegistrationFee() external view returns (uint256) {
        return registerFee;
    }

    function getReportFee() external view returns (uint256) {
        return reportFee;
    }

    function updateRegistrationFee(uint256 fee) external payable onlyDao returns (bool) {
        registerFee = fee;
        return true;
    }


    function updateReportFee(uint256 fee) external payable onlyDao returns (bool) {
        reportFee = fee;
        return true;
    }

    function getOracles() external view returns (Oracle[] memory) {
        return oracles;
    }

    function reportOracle(address oracleAddress) external payable onlyOracle returns (bool) {
        require(oracleAddress != msg.sender, "Cannot report yourself");
        require(!blacklisted[oracleAddress], "Oracle is already blacklisted");
        require(!oracleReports[msg.sender][oracleAddress], "Oracle already reported by you");
        require(msg.value >= reportFee, "Insufficient report fee");

        oracleReports[msg.sender][oracleAddress] = true;
        reportCounts[oracleAddress]++;
        
        emit OracleReported(msg.sender, oracleAddress);

        if (reportCounts[oracleAddress] >= (oracles.length / 2)+1) {
            blacklisted[oracleAddress] = true;
            emit OracleBlacklisted(oracleAddress);
            rewards[msg.sender] += reportFee;  
            
            distributeRewards(oracleAddress);
        }

        return true;
    }

    function distributeRewards(address blacklistedOracle) private {
        uint256 numReporters = 0;

        for (uint256 i = 0; i < oracles.length; i++) {
            if (oracleReports[oracles[i].name][blacklistedOracle]) {
                numReporters++;
            }
        }
        uint256 rewardPerReporter = registerFee / numReporters;
        
        for (uint256 i = 0; i < oracles.length; i++) {
            if (oracleReports[oracles[i].name][blacklistedOracle]) {
                payable(oracles[i].name).transfer(rewards[oracles[i].name] + rewardPerReporter);
                rewards[oracles[i].name] = 0;  
            }
        }
    }

    function isBlacklisted(address oracleAddress) external view returns (bool) {
        return blacklisted[oracleAddress];
    }

    modifier onlyOracle() {
        require(!isRevoked, "Ownership is revoked, no administrative changes allowed!");

        bool isOracle = false;
        for (uint256 i = 0; i < oracles.length; i++) {
            if (oracles[i].name == msg.sender && !blacklisted[msg.sender]) {
                isOracle = true;
                break;
            }
        }
        require(isOracle, "Not an authorized oracle");
        _;
    }


    modifier onlyDao() {
        require(msg.sender == dao, "Not authorized");
        _;
    }

}


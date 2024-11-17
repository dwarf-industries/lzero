const Register = artifacts.require("Register");
require("dotenv").config();

module.exports = function (deployer) {
    const registerFee = process.env.REGISTER_FEE;
    const reportFee = process.env.REPORT_FEE;
    console.log(registerFee);
    console.log(reportFee);
    const registerFeeEther = web3.utils.toWei(registerFee, "ether");
    const reportFeeEther = web3.utils.toWei(reportFee ?? "", "ether");
  
    deployer.deploy(Register,registerFeeEther,reportFeeEther,process.env.DAO);
};

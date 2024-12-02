const Register = artifacts.require("Register");
const FeeSetter = artifacts.require("FeeSetter");

require("dotenv").config();

module.exports = async function (deployer) {
    const registerFee = process.env.REGISTER_FEE;
    const reportFee = process.env.REPORT_FEE;
    console.log(registerFee);
    console.log(reportFee);
    const registerFeeEther = web3.utils.toWei(registerFee, "ether");
    const reportFeeEther = web3.utils.toWei(reportFee ?? "", "ether");

    const networkId = await web3.eth.net.getId();
    const deployedFeeSetter = FeeSetter.networks[networkId];
    if (!deployedFeeSetter) {
        throw new Error(`Contract not found on network with ID ${networkId}`);
    }
    
    console.log("Fee Setter Service address");
    console.log(deployedFeeSetter.address);

    
   await deployer.deploy(Register,registerFeeEther,reportFeeEther,deployedFeeSetter.address,process.env.DAO);
};

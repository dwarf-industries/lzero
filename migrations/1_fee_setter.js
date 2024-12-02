const FeeSetter = artifacts.require("FeeSetter");
require("dotenv").config();

module.exports = async function (deployer) {
    const feePerKylobyte = process.env.FEE_PER_KYLOBYTE;
    const networkFee = process.env.NETWORK_FEE;
    const networkCollector = process.env.NETWORK_FEE_COLLECTOR;
    
    console.log(feePerKylobyte);
    console.log(networkCollector);
    console.log(networkFee);

    const feePerKylobyteEther = web3.utils.toWei(feePerKylobyte, "ether");
  
    await deployer.deploy(FeeSetter,feePerKylobyteEther,networkFee, networkCollector,process.env.DAO);
};

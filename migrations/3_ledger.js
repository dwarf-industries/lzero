const Ledger = artifacts.require("PaymentLedger");
const FeeSetter = artifacts.require("FeeSetter");
require("dotenv").config();


module.exports = async function  (deployer)  {
    
    const networkId = await web3.eth.net.getId();
    const deployedFeeSetter = FeeSetter.networks[networkId];
    if (!deployedFeeSetter) {
        throw new Error(`Contract not found on network with ID ${networkId}`);
    }
    
    console.log("Fee Setter Service address");
    console.log(deployedFeeSetter.address);

    
    deployer.deploy(Ledger,deployedFeeSetter.address);
};

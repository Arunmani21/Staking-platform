//jshint esversion:8
 const Gate = artifacts.require("Gate");
  const TUFToken = artifacts.require("TUFToken");
 const Defi = artifacts.require("Defi");

module.exports =  async function (deployer) {
  const gateinstance = await deployer.deploy(Gate); 
  console.log("Deployed NFT:", Gate.address);
  const TUFTokeninstance = await deployer.deploy(TUFToken); 
  console.log("Deployed Token:", TUFToken.address);
   await deployer.deploy(Defi, Gate.address, TUFToken.address);

};




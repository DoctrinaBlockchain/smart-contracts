//const IRegistry_Contract = artifacts.require("IRegistry");
const Registry_Contract = artifacts.require("Registry");

module.exports = function(deployer) {
 // deployer.deploy(IRegistry_Contract);
  deployer.deploy(Registry_Contract);
};
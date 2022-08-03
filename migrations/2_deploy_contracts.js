const Factory = artifacts.require("Factory");

const tokenA = artifacts.require("tokenA");
const tokenB = artifacts.require("tokenB");

module.exports = function(deployer) {
  deployer.deploy(Factory);

  deployer.deploy(tokenA);
  deployer.deploy(tokenB);
};

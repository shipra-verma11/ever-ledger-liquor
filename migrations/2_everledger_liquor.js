const EverLedgerLiquorManager = artifacts.require("EverLedgerLiquorManager");
const LabelManufacture = artifacts.require("LabelManufacture");
const BeverageManufacture = artifacts.require("BeverageManufacture");

module.exports = function(deployer) {
  deployer.deploy(EverLedgerLiquorManager);
  deployer.deploy(LabelManufacture);
  deployer.deploy(BeverageManufacture);
};

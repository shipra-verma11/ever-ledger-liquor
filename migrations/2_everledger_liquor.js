const EverLedgerLiquorManager = artifacts.require("EverLedgerLiquorManager");
const LabelManufacture = artifacts.require("LabelManufacture");
const BeverageManufacture = artifacts.require("BeverageManufacture");

module.exports = function(deployer, network, accounts) {
  deployer.deploy(EverLedgerLiquorManager, {from: accounts[0]});
  deployer.deploy(LabelManufacture, {from: accounts[1]});
  deployer.deploy(BeverageManufacture, {from: accounts[2]});
};

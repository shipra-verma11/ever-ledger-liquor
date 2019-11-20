const LabelManufacture = artifacts.require("LabelManufacture");
const KingFisherBeverageVendor = artifacts.require("KingFisherBeverageVendor");
const Buyer = artifacts.require("Buyer");

module.exports = function(deployer) {
  deployer.deploy(LabelManufacture);
  deployer.deploy(KingFisherBeverageVendor);
  deployer.deploy(Buyer);
};

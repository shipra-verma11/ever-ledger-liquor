const EverLedgerLiquorManager = artifacts.require("EverLedgerLiquorManager");
const LabelManufacture = artifacts.require("LabelManufacture");
const BeverageManufacture = artifacts.require("BeverageManufacture");

/**
 *  Test suite to test below contract: 
 *      EverLedgerLiquorManager.sol (deployed in ganache accont 0)
 *      LabelManufacture.sol (deployed in ganache accont 1)
 *      BeverageManufacture.sol (deployed in ganache account 2)
 */
contract("TestEverLedgerContracts", async accounts => {
    let labelInstance;
    let managerInstance;
    let beverageInstance;
    // creating active instance to all the deployed contracts
    beforeEach(async function(){
        labelInstance = await LabelManufacture.deployed({from: accounts[1]});
        managerInstance = await EverLedgerLiquorManager.deployed({from: accounts[0]});
        beverageInstance = await BeverageManufacture.deployed({from: accounts[2]});
    })
    // tc1: test registration process for label vendor
    it("should register label account with manager", async ()=> {
        await labelInstance.RegisterMyIdentity("DLF", managerInstance.address, {from: accounts[1]});
        let vendorAddress = await managerInstance.getLabelVendorAddress('DLF');
        assert.equal( vendorAddress.logs[0].args.label_vendor_address, accounts[1], "Address should match");
    });
    // tc2: Negative test case, registration process for label vendor
    it("make sure only registered vendor able to get vendor address", async ()=> {
        try{
            await managerInstance.getLabelVendorAddress('Test');
            assert.isNotOk("Only registered will be able to get the vendor address");
        }
        catch(err) {
            assert.isOk("Test vendor doesn't registered");
        }
    });    
    // tc3: test registration process for beverage vendor
    it("should register beverage account with manager", async ()=> {
        await beverageInstance.RegisterMyIdentity("kingfisher", managerInstance.address, {from: accounts[2]});
        let vendorAddress = await managerInstance.getBeverageVendorAddress('kingfisher');
        assert.equal( vendorAddress.logs[0].args.beverage_vendor_address, accounts[2], "Address should match");
    });
    // tc4: Negative test case, registration process for beverage vendor
    it("make sure only registered vendor able to get vendor information", async ()=> {
        try{
            await managerInstance.getBeverageVendorAddress('jacob');
            assert.isNotOk("Only registered will be able to get the vendor address")
        }
        catch(err) {
            assert.isOk("Test vendor doesn't registered")
        }
    });
    // tc5: Update label company name
    it("make sure label company name is getting updated", async ()=> {
        await labelInstance.UpdateCompanyName("xyz", managerInstance.address, {from: accounts[1]})
        let vendorAddress = await managerInstance.getLabelVendorAddress('xyz');
        assert.equal( vendorAddress.logs[0].args.label_vendor_address, accounts[1], "Address should match");
    });
    // tc6: Update beverage company name
    it("make sure updating company name updates the existing records", async ()=> {
        await beverageInstance.UpdateCompanyName("Jacob", managerInstance.address, {from: accounts[2]})
        try{
            await managerInstance.getBeverageVendorAddress('kingfisher');
            assert.isNotOk("Update of company name failed");
        }
        catch(err){
            assert.isOk("Update of company is successful");
        }
    });
    // tc7: check the label cost
    it("check adding label cost aganist the registered label vendor", async ()=> {
        await beverageInstance.RegisterMyIdentity("jacob", managerInstance.address, {from: accounts[2]});
        await labelInstance.AddLabelStandardCost("jacob", "jacobwine", 2);
        let labelcost = await getLabelCosts("jacob");
        console.log(labelcost);
        assert.equal(labelcost, 2 ,"Label cost should match");
    });
    // tc8: check label cost for non registered vendor
    it("check label cost for non registered vendor", async ()=> {
        try{
            await labelInstance.AddLabelStandardCost("whisky", "jacobwine", 2);
            assert.isNotOk("Should not update cost for vendor whisky");
        }
        catch (err){
            assert.isOk("Label cost thrown a event - Pass");
        }
    });
    // tc9: fill liquor
    it("checking filling of liquor", async ()=> {
        await beverageInstance.fillLiquor("jacob12", 2, 3, 4, 5, 6, 2018, 5, xyz);
        await productIDExistance("jacon12");
    });
});


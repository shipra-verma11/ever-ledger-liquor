pragma solidity >=0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/EverLedgerLiquorManager.sol";
import "../contracts/LabelManufacture.sol";


// To test everledger liquor manager
contract TestEverLedgerLiquorManager {
    // test label vendor
    function testadddingLabelVendor() public{
        EverLedgerLiquorManager elm = EverLedgerLiquorManager(DeployedAddresses.EverLedgerLiquorManager());
        elm.addVendor(0x090153563d0AC20865b5238b03A51Da023cB8b32, 'kingfisher', 'label', DeployedAddresses.EverLedgerLiquorManager());
        address vendorAddres = elm.getLabelVendorAddress('kingfisher');
        Assert.equal(vendorAddres, 0x090153563d0AC20865b5238b03A51Da023cB8b32, "vendor address should match.");
    }
    // test beverage vendor
    function testaddingBeverageVendor() public{
        EverLedgerLiquorManager elm = EverLedgerLiquorManager(DeployedAddresses.EverLedgerLiquorManager());
        elm.addVendor(0xDD787382ea1946b91fC56287aD1213a377B71ee9, 'xyz', 'beverage', DeployedAddresses.EverLedgerLiquorManager());
        address vendorAddres = elm.getBeverageVendorAddress('xyz');
        Assert.equal(vendorAddres, 0xDD787382ea1946b91fC56287aD1213a377B71ee9, "vendor address should match.");
    }
    // test with wrong vendor address
    function testWrongVendorAddress() public{
        EverLedgerLiquorManager elm = EverLedgerLiquorManager(DeployedAddresses.EverLedgerLiquorManager());
        elm.addVendor(0xfD84709079174c4b401D3E425D849888c5473f17, 'xyz', 'beverage', DeployedAddresses.EverLedgerLiquorManager());
        address vendorAddress = elm.getBeverageVendorAddress('xyz');
        bool r;
        if (vendorAddress != 0x8cAce25a10147319cD63B1ddDf4d8C198b0F6D1a){
            r = false;
        } else {
            r = true;
        }
        Assert.isFalse(r, "vendor address should not match.");
    }
    // test label cost
    function testLabelCost() public{
        EverLedgerLiquorManager elm = EverLedgerLiquorManager(DeployedAddresses.EverLedgerLiquorManager());
        elm.addVendor(0x9704C117BE0AEc44189dB03C8a7322F07A88aCad, 'z', 'beverage', DeployedAddresses.EverLedgerLiquorManager());
        elm.labelDetails(0x9704C117BE0AEc44189dB03C8a7322F07A88aCad, 'z', 2);
        uint256 labelcost = elm.getLabelCost('z');
        Assert.equal(labelcost, 2, "Label cost doesn't match.");
    }
    // test label cost - negative test case
    function testLabelCostNegative() public{
        EverLedgerLiquorManager elm = EverLedgerLiquorManager(DeployedAddresses.EverLedgerLiquorManager());
        elm.addVendor(0x9704C117BE0AEc44189dB03C8a7322F07A88aCad, 'z', 'beverage', DeployedAddresses.EverLedgerLiquorManager());
        elm.labelDetails(0xDD787382ea1946b91fC56287aD1213a377B71ee9, 'z', 2);
        uint256 labelcost = elm.getLabelCost('z');
        bool validate;
        if (labelcost == 2) {
            validate = false;
        } else {
            validate = true;
        }
        Assert.isFalse(r, "Label cost matches, check logic !!!.");
    }
}

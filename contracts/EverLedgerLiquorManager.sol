pragma solidity >=0.5.0;

// Importing LabelManufacture for transferring label to beverage vendor
// Importing BeverageManufacture for transferring funds from buyer to beverage vendor
import "./LabelManufacture.sol";
import "./BeverageManufacture.sol";

/// @title EverLedgerLiquorManager
/// @author vivekganesan

/* This contract works as an admin which controls the label, beverage and helps buyers to verify product */
contract EverLedgerLiquorManager{
    // Stores the address of the everledger adminer
    address everLedgerManagerAddress;
    // Stores the address of everledger contract
    address everLedgerManagerContractAddres;
    // To make sure vendor exists, its mapped with bool value
    mapping(string=>bool) labelVendorExistance;
    // To make sure vendor exists, its mapped with bool value
    mapping(string=>bool) beverageVendorExistance;
    // Stores cost for each label type
    struct labelStandardInformation{
        uint256 labelCost;
        string labelType;
    }
    // Stores the label vendor address and deployed contract address
    struct LabelVendorInfo{
        address payable LabelVendorAddress;
        address LabelVendorContractAddress;
    }
    mapping(string => LabelVendorInfo) LabelVendorLedger;
    // Stores the label vendor address and deployed contract address
    struct BeverageVendorInfo{
        address payable BeverageVendorAddress;
        address BeverageVendorContractAddress;
    }
    mapping(string => BeverageVendorInfo) BeverageVendorLedger;
    // Stores cost for each label standards
    /// @notice helps beverage vendor to buy for the label based on the type
    mapping(address => labelStandardInformation) labelStandard;
    // Add everledger manager address and everledger contract address
    constructor() public {
        everLedgerManagerAddress = msg.sender;
        everLedgerManagerContractAddres = address(this);
    }
    /// Fetch the label vendor address based on given vendor name
    /// @notice All the registered vendor will be available here
    /// @param label_vendor_name vendor name
    function getLabelVendorAddress(string memory label_vendor_name) public returns (address payable VendorAddress) {
        require(labelVendorExistance[label_vendor_name], "Label Vendor doesn't exists...");
        emit getLabelVendorAddressLog(label_vendor_name, LabelVendorLedger[label_vendor_name].LabelVendorAddress);
        return  LabelVendorLedger[label_vendor_name].LabelVendorAddress;
    }
    /// Fetch the beverage vendor address based on given vendor name
    /// @notice All the registered vendor will be available here
    /// @param beverage_vendor_name name of the vendor
    function getBeverageVendorAddress(string memory beverage_vendor_name) public returns (address payable VendorAddress) {
        require(beverageVendorExistance[beverage_vendor_name], "Beverage Vendor doesn't exists...");
        emit getBeverageVendorAddressLog(beverage_vendor_name, BeverageVendorLedger[beverage_vendor_name].BeverageVendorAddress);
        return  BeverageVendorLedger[beverage_vendor_name].BeverageVendorAddress;
    }
    // Helps each vendor to register in to everledger wine trading
    /// @notice Only the registered vendor can perform the trading
    // It is mandatory to register for all the vendor to perform trading
    /// @notice Here validation of the vendor is not defined because currently they have a provision to update the registeration info anytime
    // Todo: Need to delete the map if existing vendor calls addVendor for updates or need to create a separate update method
    /// @param vendorAddress address of the vendor
    /// @param vendorName name of the vendor
    /// @param vendorType either label or beverage
    /// @param contractAddress vendor contract address for communicating between the contracts
    function addVendor(address payable vendorAddress, string calldata vendorName, string calldata vendorType, address contractAddress) external {
        if(keccak256(abi.encodePacked((vendorType))) == keccak256(abi.encodePacked(("label")))) {
            LabelVendorLedger[vendorName].LabelVendorAddress = vendorAddress;
            LabelVendorLedger[vendorName].LabelVendorContractAddress = contractAddress;
            labelVendorExistance[vendorName] = true;
        } else if(keccak256(abi.encodePacked((vendorType))) == keccak256(abi.encodePacked(("beverage")))) {
            BeverageVendorLedger[vendorName].BeverageVendorAddress = vendorAddress;
            BeverageVendorLedger[vendorName].BeverageVendorContractAddress = contractAddress;
            beverageVendorExistance[vendorName] = true;
        } else {
            emit addVendorLog(vendorAddress, vendorName, "only label or beverage vendor can register.");
            revert("only label or beverage vendor can register.");
        }
        emit addVendorLog(vendorAddress, vendorName, "Successfully registered new vendor...");
    }
    // Helps each vendor to register in to everledger wine trading
    /// @notice Only the registered vendor can perform the trading
    // It is mandatory to register for all the vendor to perform trading
    /// @param fromLabelVendor name of the label vendor
    /// @param forBeverageVendor name of the beverage vendor
    /// @param labelType label type
    function fetchLabel(string calldata fromLabelVendor, string calldata forBeverageVendor, string calldata labelType)
        external
        returns (uint256 labelID, uint256 labelCost) {
        LabelManufacture lm = LabelManufacture(LabelVendorLedger[fromLabelVendor].LabelVendorContractAddress);
        address buyerAddress = getBeverageVendorAddress(forBeverageVendor);
        uint256 label = lm.GenerateLabel(buyerAddress, labelType, labelStandard[buyerAddress].labelCost);
        emit fetchLabelLog(fromLabelVendor, forBeverageVendor, labelType, labelStandard[buyerAddress].labelCost, "Label has been generated");
        return (label, labelStandard[buyerAddress].labelCost);
    }
    // Stores cost for the each label type based on the label vendor
    /// @param labelManufactureAddress address of the label vendor
    /// @param labelType type of the label like S,M,L,Xl,XXL
    /// @param cost cost of the label in ether
    function labelDetails(address labelManufactureAddress, string calldata labelType, uint256 cost) external{
        labelStandard[labelManufactureAddress].labelCost = cost;
        labelStandard[labelManufactureAddress].labelType = labelType;
        emit labelDetailsLog(labelManufactureAddress, labelStandard[labelManufactureAddress].labelType,
                labelStandard[labelManufactureAddress].labelCost, "label type has been added");
    }
    // Helps consumers to buy and verify the products
    /// @param labelid scanned id of the label
    /// @param productid scanned id of the product
    /// @param vendorname name of the vendor
    function buyliquor(uint256 labelid, string calldata productid, string calldata vendorname) external payable{
        require(beverageVendorExistance[vendorname], "This product is not from a registered beverage vendor");
        BeverageManufacture bm = BeverageManufacture(BeverageVendorLedger[vendorname].BeverageVendorContractAddress);
        // return bool result, uint256 year, bool approved, uint256 labelID, uint256 beveragePrice
        bool result;
        uint256 yearManufactured;
        bool approved;
        bool sold;
        uint256 labelId;
        uint256 beverageCost;
        (result, yearManufactured, approved, sold, labelId, beverageCost) = bm.productIDExistance(productid);
        require(result, "Product ID doen't exists with beverage vendor.");
        if(labelid != labelId){
            revert("Provided label ID doesn't match with the product ID.");
        }
        if(approved == true && sold == false){
            BeverageVendorLedger[vendorname].BeverageVendorAddress.transfer(beverageCost);
            emit buyliquorLog(labelId, productid, vendorname, yearManufactured, beverageCost, "Thank You !!!!!");
        }
        else{
            revert("Product is not approved");
        }
    }
    /// @notice events
    event getLabelVendorAddressLog(string label_vendor_name, address label_vendor_address);
    event getBeverageVendorAddressLog(string beverage_vendor_name, address beverage_vendor_address);
    event addVendorLog(address vendorAddress, string vendorName, string msg);
    event fetchLabelLog(string labelvendorname, string beveragevendorname, string labeltype, uint256 labelcost, string msg);
    event labelDetailsLog(address labelManufactureAddress, string labelType, uint256 cost, string msg);
    event buyliquorLog(uint256 labelid, string productid, string vendorname, uint256 year, uint256 beveragecost, string msg);
}
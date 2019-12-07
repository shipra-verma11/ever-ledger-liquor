pragma solidity >=0.5.0;

// Importing EverLedgerLiquorManager contract
/// @dev By doing this label manufacture call register with manager
import "./EverLedgerLiquorManager.sol";

/// @title LabelManufacture
/// @author vivekganesan

/* This contract controls label ID generation, initially the label ID will be loaded with some default value
then for every `fetch label` request, the label ID will be incremented with `1` (numeric operation)
best practice: Need to randomize the intial labelID number, to prevent the prediction of labelID by some third party (priority low) */

contract LabelManufacture{
    // Stores the address of the label manufacture
    /// @dev This will be used for registeration and for payment transfer
    address payable LabelOwnerAddress;
    // Stores the contract address after deployment
    address LabelContractAddress;
    // Name of the label manufacture company
    string LabelManufactureName;
    /// @notice For initializing the everledger manager contract
    /// @dev Used for registeration and provide selling standards like cost
    EverLedgerLiquorManager elm;
    address EverLedgerManagerContractAddress;
    /// Stores label information like cost and vendor who used this label for each unique label ID
    struct labelInfo{
        uint256 labelCost;
        string labelType;
        address usedByVendor;
    }
    /// @notice This will be initial label identifier counter, which acts as a label ID
    /// @dev This will get auto incremented for each request to a label
    uint256 labelCounter = 2019;
    // This holds all the label cost based on the label type
    /// @notice Label cost should be registered with everledget manager contract for vendor to be paid
    /// @dev Make sure cost has been added to manager contract and its been approved
    mapping(string => uint256) labelCost;
    /// This holds all the label information for the created Label ID
    /// @dev mapping for label ID => labelInfo(labelCost, usedByVendor)
    mapping(uint256 => labelInfo) labelInformation;
    // This represent boolean representation for each unique label ID existence
    mapping(uint256 => bool) labelExists;
    // Add label owner address based on the contract deployment and stores the current contract address
    constructor() public{
        LabelOwnerAddress = msg.sender;
        LabelContractAddress = address(this);
    }
    // Only label address can perform some operations
    modifier onlyLabelOwner{
        require(msg.sender == LabelOwnerAddress, "Only label contract owner can perform the operation.");
        _;
    }
    // Fetch the company name defined in the contract
    /// @notice This is just a reference function to view the company name
    function GetMyCompanyName() public view onlyLabelOwner returns(string memory){
        return LabelManufactureName;
    }
    // Updates the company name
    /// @notice Updating the company name needs to be re-registered with the everledger manager
    /// because only the registered vendor can perform trading
    /// @param companyName name of the company
    function UpdateCompanyName(string memory companyName) public onlyLabelOwner{
        LabelManufactureName = companyName;
        RegisterMyIdentity(LabelManufactureName, EverLedgerManagerContractAddress);
    }
    // Register this owner with the ever ledger manager
    /// @notice For first time each vendor has to be registered with manager, only registered vendor can perform trading
    /// @param myName name of the company
    /// @param everLedgerManagerContractAddress manager contract address
    function RegisterMyIdentity(string memory myName, address everLedgerManagerContractAddress)
        public
        onlyLabelOwner{
        // update state var `EverLedgerManagerContractAddress`
        EverLedgerManagerContractAddress = everLedgerManagerContractAddress;
        // updates state var `LabelManufactureName`
        LabelManufactureName = myName;
        // create an active instance of everledger manager for communication between contracts
        elm = EverLedgerLiquorManager(EverLedgerManagerContractAddress);
        // registration happens with manager contract object
        elm.addVendor(LabelOwnerAddress, LabelManufactureName, "label", LabelContractAddress);
        emit RegisterMyIdentityLog(LabelManufactureName, EverLedgerManagerContractAddress, "Vendor Registered.");
    }
    // Add label cost and updates the manager with label type and cost
    /// @notice Based on the label type each consuming vendor has to tranfer the cost
    // If the cost and label type is not registered with the manager then tranfer of ether might be lost
    // so make sure to update the label cost for each label type
    /// @param labelType type of the label
    /// @param cost cost for the label in ether
    function AddLabelStandardCost(address beverageVendor, string memory labelType, uint256 cost) public onlyLabelOwner{
        elm.labelDetails(beverageVendor, labelType, cost);
        emit AddLabelStandardCostLog(labelType, beverageVendor, cost, "Added label type with cost.");
    }
    // Generate unique label for the buyers
    /// @notice Generating unique label invloves initial value derived from the initial label counter
    /// @dev Currently this value is hard coded, but it can controlled from manager itself
    // The idea is to regerate unique label ID value by increment the value when ever request comes
    // and it will be uploaded to storage with mapping label ID with vendor address who requested for the label
    // so this remain always unique even if some other vendor has the same label ID
    /// @param requestedVendor vendor name who is requesting label
    /// @param labelType type of label needed
    /// @param costOfLabel cost for that type of label
    function GenerateLabel(address requestedVendor, string calldata labelType, uint256 costOfLabel) external returns (uint256 labelID){
        // increment label counter for label ID
        uint256 updatedLabel = labelCounter++;
        // update the label ID with cost and vendor who requested
        // cost: will be fetch from manager (refer manager contract)
        labelInformation[updatedLabel].labelCost = costOfLabel;
        labelInformation[updatedLabel].labelType = labelType;
        labelInformation[updatedLabel].usedByVendor = requestedVendor;
        labelExists[updatedLabel] = true;
        emit GenerateLabelLog(updatedLabel, labelInformation[updatedLabel].usedByVendor, labelInformation[updatedLabel].labelCost);
        return updatedLabel;
    }
    // To check whether label ID exists in the system
    /// @param labelIdentityNumber label id number
    function LabelIDExistance(uint256 labelIdentityNumber) public returns (bool labelIDResults){
        bool result = false;
        if(labelExists[labelIdentityNumber]){
            result = true;
            emit LabelIDExistanceLog(labelIdentityNumber, result, "Label exists..");
            return result;
        }
        emit LabelIDExistanceLog(labelIdentityNumber, result, "Label doesn't exists..");
        return result;
    }
    // Only for testing the stored data.
    function getAllInfo() public returns(address labelowneraddress, address labelcontractaddress, string memory labelvendorname) {
        emit getAllInfoLog(LabelOwnerAddress, LabelContractAddress, LabelManufactureName);
        return (LabelOwnerAddress, LabelContractAddress, LabelManufactureName);
    }
    /// @notice events
    event getAllInfoLog(address owneraddress, address contractaddress, string name);
    event RegisterMyIdentityLog(string name, address manageraddress, string msg);
    event AddLabelStandardCostLog(string labelType, address labelowneraddress, uint256 cost, string msg);
    event LabelIDExistanceLog(uint256 labelID, bool result, string msg);
    event GenerateLabelLog(uint256 labelid, address requestedvendoraddress, uint256 cost);
}

pragma solidity >=0.5.0;

// Importing EverLedgerLiquorManager contract
/// @dev By doing this beverage manufacture call register with manager
import "./EverLedgerLiquorManager.sol";


/// @title BeverageManufacture
/// @author vivekganesan

/* This contract controls beverage bottling plant works like filling liquor with product ID and determining cost for the
wine product and wine ingredients information
*/

contract BeverageManufacture {
    // Stores address of the beverage manufacture
    address payable beverageManufactureAddress;
    // Stores the contract address after deployment
    address beverageContractAddress;
    // Name of the beverage manufacture company
    string BeverageManufactureName;
    /// @notice For initializing the everledger manager contract
    /// @dev Used for registeration and provide wine information to the user
    EverLedgerLiquorManager elm;
    address EverLedgerManagerContractAddress;
    // Stores wine information
    struct BeverageInfo{
        uint256 labelID;
        string productID;
        bool approved;
        bool sold;
        uint256 beveragePrice;
        uint256 yearManufactured;
        bytes32 wineIngredients;
    }
    // Stores beverage information against the product ID
    mapping(string => BeverageInfo) BeverageInformation;
    // Bool to verify whether label consumed or not
    mapping(uint256 => bool) LabelConsumed;
    // Bool to verify whether product ID exist or not
    mapping(string => bool) ProductExistance;
    // Add beverage owner address based on the contract deployment and stores the current contract address
    constructor() public {
        beverageManufactureAddress = msg.sender;
        beverageContractAddress = address(this);
    }
    // only beverage owner can perform the operation
    modifier onlyBeverageOwner {
        require(msg.sender == beverageManufactureAddress, "Only label contract owner can perform the operation.");
        _;
    }
    // Fetch the company name defined in the contract
    /// @notice This is just a reference function to view the company name
    function GetMyCompanyName() external view onlyBeverageOwner returns(string memory){
        return BeverageManufactureName;
    }
    // Updates the company name
    /// @notice Updating the company name needs to be re-registered with the everledger manager
    /// because only the registered vendor can perform trading
    /// @param companyName name of the company
    function UpdateCompanyName(string calldata companyName) external onlyBeverageOwner{
        BeverageManufactureName = companyName;
        RegisterMyIdentity(BeverageManufactureName, EverLedgerManagerContractAddress);
    }
    // Register this owner with the ever ledger manager
    /// @notice For first time each vendor has to be registered with manager, only registered vendor can perform trading
    /// @param myName name of the company
    /// @param everLedgerManagerContractAddress manager contract address
    function RegisterMyIdentity(string memory myName, address everLedgerManagerContractAddress)
        public
        onlyBeverageOwner{
        // update state var `EverLedgerManagerContractAddress`
        EverLedgerManagerContractAddress = everLedgerManagerContractAddress;
        // updates state var `BeverageManufactureName`
        BeverageManufactureName = myName;
        // create an active instance of everledger manager for communication between contracts
        elm = EverLedgerLiquorManager(EverLedgerManagerContractAddress);
        // registration happens with manager contract object
        elm.addVendor(beverageManufactureAddress, BeverageManufactureName, "beverage", beverageContractAddress);
        emit RegisterMyIdentityLog(BeverageManufactureName, EverLedgerManagerContractAddress, "Vendor Registered.");

    }
    // Helps to perform updating liquor details for specific label id and product id
    /// @param productTrackingCode product id
    /// @param CalciumCarbonate % of component
    /// @param PotassiumSorbate % of component
    /// @param SulfurDioxide % of component
    /// @param Water % of component
    /// @param Flavors % of component
    /// @param preservedFromYear % of component
    /// @param beverageCost cost of the product
    /// @param fromLabelVendor to fetch label from vendor
    function fillLiquor(
        string memory productTrackingCode,
        uint256 CalciumCarbonate,
        uint256 PotassiumSorbate,
        uint256 SulfurDioxide,
        uint256 Water,
        uint256 Flavors,
        uint256 preservedFromYear,
        uint256 beverageCost,
        string memory fromLabelVendor
        )
        public
        onlyBeverageOwner{
        // getting the label details
        uint256 labelID;
        uint256 labelCost;

        (labelID, labelCost) = elm.fetchLabel(fromLabelVendor, BeverageManufactureName, "L");
        // check whether the label ID and product ID exists already in the contract
        require(LabelConsumed[labelID] == false, 'Label shows already consumed...');
        require(ProductExistance[productTrackingCode] == false, 'ProductCode already exists in the system');
        bytes memory agriWineIngredients = abi.encodePacked(CalciumCarbonate, PotassiumSorbate, SulfurDioxide, Water, Flavors);
        bytes32 agriWineIngredientsHash = keccak256(agriWineIngredients);
        BeverageInformation[productTrackingCode].labelID = labelID;
        BeverageInformation[productTrackingCode].yearManufactured = preservedFromYear;
        BeverageInformation[productTrackingCode].approved = true;
        BeverageInformation[productTrackingCode].sold = false;
        BeverageInformation[productTrackingCode].beveragePrice = beverageCost * (10*18);
        BeverageInformation[productTrackingCode].wineIngredients = agriWineIngredientsHash;
        LabelConsumed[labelID] = true;
        ProductExistance[productTrackingCode] = true;
        emit fillLiquorLog(productTrackingCode, labelID, "Product has been filled ...");
    }
    // Verify the existance of the product
    /// @param productIdentityNumber id of the product
    function productIDExistance(string calldata productIdentityNumber) external view returns
        (bool productIDResults, uint256 year, bool approved, bool sold, uint256 labelid, uint256 beverageprice){
        bool result = false;
        if(ProductExistance[productIdentityNumber]){
            return(
                true,
                BeverageInformation[productIdentityNumber].yearManufactured,
                BeverageInformation[productIdentityNumber].approved,
                BeverageInformation[productIdentityNumber].sold,
                BeverageInformation[productIdentityNumber].labelID,
                BeverageInformation[productIdentityNumber].beveragePrice);
        }
        // return bool result, uint256 year, bool approved, bool sold, uint256 labelID, uint256 beveragePrice
        return (result, 0, false, false, 0, 0);
    }
    /// @notice events
    event RegisterMyIdentityLog(string name, address manageraddress, string msg);
    event fillLiquorLog(string productid, uint256 labelid, string msg);
}

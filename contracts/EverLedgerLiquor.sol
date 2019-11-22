pragma solidity >=0.5.0;

/***************************************************************************************************************************
 * This module is mainly focused mainly to trace back the tamper proof of the wine available in the market.
 *
 *
 * author : vivekganesan (vivekganesan01 at gmail.com)
 * version : v1.0.0
 * Has 3 contracts, parent contract will be LabelManufacture and other two contracts are `contract KingFisherBeverageVendor`
 * for beverage owner and `contract Buyer` for the buyers.
 * LabelManufacture - helps label vendor to create a unique label and this unique label once mined will be passed
 *                    to beverage owners for bottle filling.
 * KingFisherBeverageVendor - helps beverage vendor to fill the wine and push the wine ingredients into tamper proof p2p network.
 * Buyer - helps customer to buy tamper proof product.
 **************************************************************************************************************************/

// This contract trace back the label that is being created for the beverage liquor manufacture.
// basically this contract have set of keys called approved and sold which determine whether the
// product is has been `APPROVED` by beverage vendor and whether is has been `SOLD` for the end
// user.

contract LabelManufacture {
    // label owner address [payable since the label amount has been transferred]
    address payable labelManufactureAddress = 0x161AA779140417C8aE9aEAae4cC6d838b5815B5f;
    address contractOwner = address(0x0);
    // data structure to hold the label and beverage data
    struct labelDetails {
        uint256 labelID;  // unique id loaded at the time of creation
        string productID;  // to be updated by the beverage vendor
        bool approved;  // to trace whether beverage is approved by beverage vendor
        bool sold;  // to trace whether beverage is sold
        address payable seller;  // beverage seller address
        uint beveragePrice;  // price of the beverage
        uint labelPrice;  // price for the label created
        bytes32 wineIngredients;  // beverage ingredients as hash value
    }
    mapping(uint256 => labelDetails) labelInformation;  // data structure to hold all the information of label based on unique ID
    mapping(uint256 => bool) labelExists;  // to check whether label exists or not
    uint256[] private availableLabel;  // list of available Labels to be used by beverage company
    // sets the contract owner address (address which deployes the contract)
    constructor() public {
        contractOwner = msg.sender;
    }

    // MODIFIER
    // access control: only this label company can access
    modifier onlyLabelManufacture {
        require(msg.sender == labelManufactureAddress, "Only Label owner can access or update the label data...");
        _;
    }
    // access control: anyone apart from this label company can access
    modifier OnlyNonLabelVendor {
        require(msg.sender != labelManufactureAddress, "Only Non label vendor can access or update the data...");
        _;
    }
    // access control: only contract owner can change the vendor address
    modifier onlyContractOwner {
        require(msg.sender == contractOwner, "Only contract owner can update the data...");
        _;
    }

    // FUNCTION
    // updateLabelManufactureAddress: helps to update the manufacture address
    function updateLabelManufactureAddress(address payable manufactureAddress) private
        onlyContractOwner
    {
        labelManufactureAddress = manufactureAddress;
    }
    
    // createLabel: create a label with all necessary details for the beverage company
    // only label manufacture can create new label
    event CreateLabelLog(uint256 labelID, string message);
    function createLabel(uint256 labelIDFromIOT, uint labelCost) public
        onlyLabelManufacture
    {
        require(labelExists[labelIDFromIOT] == false, "Label ID already exists. Cannot create the label");
        labelInformation[labelIDFromIOT].labelID = labelIDFromIOT;
        labelInformation[labelIDFromIOT].productID = "null";
        labelInformation[labelIDFromIOT].approved = false;
        labelInformation[labelIDFromIOT].sold = false;
        labelInformation[labelIDFromIOT].seller = address(0x0);
        labelInformation[labelIDFromIOT].beveragePrice = 0;
        labelInformation[labelIDFromIOT].labelPrice = labelCost * (10*18);
        labelInformation[labelIDFromIOT].wineIngredients = "null";
        labelExists[labelIDFromIOT] = true;
        availableLabel.push(labelIDFromIOT);  // pushes label id for tracking back
        emit CreateLabelLog(labelIDFromIOT, "Successfully uploaded the labelID");
    }

    // validateLabelExistance: to verify whether label exists or not and only non label company can modify the state of
    // approved (for beverage vendor) and sold (for end user validation)
    event ValidateLabelExistanceLog(uint256 labelID, string msg);
    function validateLabelExistance(uint256 labelID, bool approved, bool sold)
        internal
        OnlyNonLabelVendor
        returns (
            bool
        )
    {
        if(labelExists[labelID] && labelInformation[labelID].approved == approved && labelInformation[labelID].sold == sold) {
            emit ValidateLabelExistanceLog(labelID, "labelID is approved to be consumed... ");
            return true;
        } else {
            emit ValidateLabelExistanceLog(labelID, "labelID is not approved to be consumed... ");
            return false;
        }
    }

    // fetchEmptyLabel: fetchs the empty label for the beverage vendor and called only by vendor
    event fetchEmptyLabelLog(uint256 labelID, string message);
    function fetchEmptyLabel()
        internal
        OnlyNonLabelVendor
        returns (
            uint256
        )
    {
        require(availableLabel.length > 0, "Non of the label is available... Check with label vendor to create the label");
        uint256 lastLabel = availableLabel[availableLabel.length - 1];
        availableLabel.pop();
        emit fetchEmptyLabelLog(lastLabel, "New label Successfully Fetched... ");
        return lastLabel;
    }

    // buy liquor: helps to validate and buy the tamper proof liquor, called by only the vendor
    event BuyLiquorLog(uint256 labelID, bool sold, string message);
    function buyLiquor(uint256 scanLabelID)
        internal
    {
        require(msg.sender.balance > labelInformation[scanLabelID].beveragePrice + labelInformation[scanLabelID].labelPrice,
        "Insufficient Balance");
        bool verified = validateLabelExistance(scanLabelID, true, false);
        if (verified) {
            address payable beverageVendor = labelInformation[scanLabelID].seller;
            beverageVendor.transfer(labelInformation[scanLabelID].beveragePrice);
            labelManufactureAddress.transfer(labelInformation[scanLabelID].labelPrice);
            labelInformation[scanLabelID].sold = true;
            emit BuyLiquorLog(scanLabelID, labelInformation[scanLabelID].sold, "Successfully sold and transferred the amount");
        } else {
            emit BuyLiquorLog(scanLabelID, labelInformation[scanLabelID].sold, "This product is not for SALE");
            revert("Can't buy the product...");
        }
    }
}

// KingFisherBeverageVendor: vendor based contract which inherits the label manufacture properties for the label id's.
// helps to update filled liquor statistics based on label ID and approves it to do sales.
contract KingFisherBeverageVendor is LabelManufacture {
    address payable beverageManufactureAddress = 0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c;

    // MODIFIER
    // access control: only this beverage company can access
    modifier onlybeverageOwner {
        require(msg.sender == beverageManufactureAddress, "Only beverage manufacture can access the state...");
        _;
    }

    // access control: only contract owner can change the vendor address
    modifier onlyContractOwner {
        require(msg.sender == contractOwner, "Only contract owner can update the data...");
        _;
    }

    // FUNCTION
    // updateBeverageManufactureAddress: helps to update the manufacture address
    function updateBeverageManufactureAddress(address payable manufactureAddress) private
        onlyContractOwner
    {
        beverageManufactureAddress = manufactureAddress;
    }

    // helps to fill the liquor for a label ID with all the information and mark it as approved for sales.
    event fillLiquorLog(
        string productID,
        uint beverageCost,
        uint256 CalciumCarbonate,
        uint256 PotassiumSorbate,
        uint256 SulfurDioxide,
        uint256 Water,
        uint256 Flavors,
        bytes32 agriWineIngredientsHash,
        string message
        );
    function fillLiquor(
        string memory productID,
        uint beverageCost,
        uint256 CalciumCarbonate,
        uint256 PotassiumSorbate,
        uint256 SulfurDioxide,
        uint256 Water,
        uint256 Flavors
        )
        public
        onlybeverageOwner
    {
        uint256 label = fetchEmptyLabel();
        bytes memory agriWineIngredients = abi.encodePacked(CalciumCarbonate, PotassiumSorbate, SulfurDioxide, Water, Flavors);
        bytes32 agriWineIngredientsHash = keccak256(agriWineIngredients);
        labelInformation[label].productID = productID;
        labelInformation[label].approved = true;
        labelInformation[label].seller = beverageManufactureAddress;
        labelInformation[label].beveragePrice = beverageCost * (10*18);
        labelInformation[label].wineIngredients = agriWineIngredientsHash;
        emit fillLiquorLog(
            productID,
            labelInformation[label].beveragePrice,
            CalciumCarbonate,
            PotassiumSorbate,
            SulfurDioxide,
            Water,
            Flavors,
            agriWineIngredientsHash,
            "Succesfully filled the liquor ...");
    }
}

// Buyer: for end customer contract which facilicate tamper proof buying of the beverage product.
contract Buyer is LabelManufacture {
    // address of the buyer
    address payable private buyerAddress;

    // FUNCTION
    // buy: to buy the liquor
    function buy(uint256 scanQRCode)
        public
    {
        buyLiquor(scanQRCode);
    }
}

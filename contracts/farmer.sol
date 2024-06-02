// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "./Imuavza.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";



contract registry {
    AggregatorV3Interface internal dataFeed;
    address public muavza;
    Imuavza muavzaContract;
    IERC20 token;
    address owner;


    constructor(address muavzaContractAddress){
        dataFeed = AggregatorV3Interface(
            0x001382149eBa3441043c1c66972b4772963f5D43
        );
        token = IERC20(0x01e6822bE224429218f0E5Fc67f61f6A2744476a);
        muavza = muavzaContractAddress;
        muavzaContract = Imuavza(address(muavza));
        owner = msg.sender;
    }

    uint256 public constant FACTOR = 1000000;  
    uint256 public constant USABLESTAKE = 70;

    uint256 public farmerId = 0;
    uint256 public buyerId = 0;
    uint256 public cropId = 0;

    struct Farmer{
        uint256 farmerId;
        address farmerAddress;
        uint256 area;
        string[] state;
        string country;
        bytes32 requestId;
        bool requestedClaim;
        bool hasClaimed;
        bool isVerified;
        // string cropName;
        // uint256 price;
        // mapping (string => uint256) cropToPrice;
    }
    struct Crop{
        uint256 cropId;
        address buyerAddress;
        address sellerAddress;
        string cropName;
        uint256 quantity;
        uint256 price;
    }

    mapping (address => bool) public isVerifier;
    mapping (uint256 => Farmer) public IdToFarmer;
    mapping (address => uint256) public addressToId;
    // mapping (address => mapping (string => uint256)) public farmerToCropToPrice;
    mapping (uint256 => Crop) public idTocrop;
    mapping (address => uint256) public addressToCropId;


    struct Buyer{
        uint256 buyerId;
        address buyerAddress;
        uint256 stakedAmount;
        uint256 useableStake;

    }

    struct land{
        uint256 landId;

    }

    mapping (uint256 => Buyer) public IdTobuyer;
    mapping (address => uint256) public buyerAddressToId;
    // mapping (address => mapping (string => uint256)) public buyerToCropToQuantity;

    mapping (string => uint256) public cropToMSP;

    event farmerVerified(address farmeraddress);
    event farmerClaimed(address farmeraddress, uint256 amount);
    event fakeClaim(address farmeraddress);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function verifyUsers(address verifier) public onlyOwner {
        isVerifier[verifier] = true;
    }

    // uncoment
    function farmerRegister(uint256 _area, string[] calldata _state, string memory _country) public {
        // uint256 farmerid = addressToId[msg.sender];
        // require(farmerid != 0, "already regestered");
        farmerId++;
        IdToFarmer[farmerId] = 
            Farmer(
                farmerId,
                msg.sender,
                _area,
                _state,
                _country,
                0,
                false,
                false,
                false
        );
        addressToId[msg.sender] = farmerId;
    }

    function verifyFarmer(uint256 _farmerId) public {
        require(isVerifier[msg.sender] == true , " only verifier can verify " );
        Farmer storage farmer = IdToFarmer[_farmerId] ;
        farmer.isVerified = true;
        emit farmerVerified(farmer.farmerAddress);   
    }

    function getAllFarmers() public view returns(Farmer[] memory) {
        uint counter = 0;
        Farmer[] memory farmer = new Farmer[](farmerId);
         for (uint i = 1; i <= farmerId; i++) {
            Farmer memory currentItem = IdToFarmer[i];
            farmer[counter] = currentItem;
            counter++;
        }
        return farmer;

    }

    function callRequestClaim() public returns (bytes32) {
        Farmer storage farmer = IdToFarmer[addressToId[msg.sender]] ;
        require(farmer.isVerified == true, "only for verified farmers");
        farmer.requestedClaim = true;
        bytes32 requestId = muavzaContract.requestClaim(farmer.state);
        farmer.requestId = requestId;
        return requestId;
    }

    function callClaim(string memory b) public {
    Farmer storage farmer = IdToFarmer[addressToId[msg.sender]] ;
        require( farmer.requestedClaim == true, "only for verified farmers");
        require( farmer.hasClaimed == false, "only for verified farmers");
        // bool result = apiContract.getValue(farmer.requestId);
        string memory result = muavzaContract.claim(farmer.requestId);
        require(keccak256(abi.encodePacked((result))) == keccak256(abi.encodePacked((b))), "false claimdone by farmer");
        if(keccak256(abi.encodePacked((result))) == keccak256(abi.encodePacked((b)))){
            farmer.hasClaimed = true;
            token.transfer(msg.sender, (farmer.area * FACTOR));
            emit farmerClaimed(msg.sender, (farmer.area * FACTOR));
        }else{
            emit fakeClaim(msg.sender);
        }
    }


    function _buyerRegister() internal {
        buyerId++;
        IdTobuyer[buyerId] = Buyer(
            buyerId,
            msg.sender,
            0,
            0
        );
        buyerAddressToId[ msg.sender] = buyerId;

    }

    function buyerStake(uint256 amount) public {
       buyerId = buyerAddressToId[ msg.sender];
       if(buyerId != 10000){
            _buyerRegister();
       }
        buyerId = buyerAddressToId[ msg.sender];
        Buyer storage buyer  = IdTobuyer[buyerId];
        token.approve(address(this), amount);
        token.transferFrom(msg.sender, address(this), amount);
        buyer.stakedAmount += amount;
        buyer.useableStake += (amount * USABLESTAKE)/100;
    }

    function addCrop(string memory cropName, uint256 price, uint256 quantity) public {
        require(price > cropToMSP[cropName], "price must be greater than MSP" );
        buyerId = buyerAddressToId[ msg.sender];
        Buyer storage buyer  = IdTobuyer[buyerId];
        require(buyer.useableStake > price, "add more stake" );
        cropId++;
        idTocrop[cropId] =
        Crop(
            cropId,
            msg.sender,
            address(0),
            cropName,
            quantity,
            price
        );
        addressToCropId[msg.sender] = cropId;
    }

    function getAllCrop() public view returns(Crop[] memory) {
        uint counter = 0;
        Crop[] memory crop = new Crop[](cropId);
         for (uint i = 1; i <= cropId; i++) {
            Crop memory currentItem = idTocrop[i];
            crop[counter] = currentItem;
            counter++;
        }
        return crop;
    }

    // function getBuyerBalance() public returns (uint256) {
    //     buyerId = buyerAddressToId[ msg.sender];
    //     Buyer memory buyer  = IdTobuyer[buyerId];
    //     return buyer.useableStake;
    // }

    function sell(uint256 _cropId) public {
        Crop storage crop = idTocrop[_cropId];
        crop.sellerAddress = msg.sender;
        // token.transferFrom(address(this), crop.buyerAddress, crop.price);
        // buyer.useableStake -= value;
    }

    function cropRecieved(uint256 _cropId, bool _value ) public {
        if(_value == true){
            Crop storage crop = idTocrop[_cropId];
            buyerId = buyerAddressToId[ msg.sender];
            Buyer storage buyer  = IdTobuyer[buyerId];
            token.transferFrom(address(this), crop.sellerAddress, crop.price);
            buyer.useableStake -= crop.price;
        }
    }

    function withdrawStake() public {
        buyerId = buyerAddressToId[ msg.sender];
        Buyer memory buyer  = IdTobuyer[buyerId];
        uint256 value = buyer.useableStake + (buyer.stakedAmount * 30)/100;
        require(
            token.transfer(msg.sender, value),
            "Unable to transfer"
        );
    }

    function setMsp(string memory cropName, uint256 _msp) public onlyOwner{
        cropToMSP[cropName] = _msp;
    }

    function getStake(address buyerAddress) public view returns(uint256, uint256) {
        uint256 Id = buyerAddressToId[ buyerAddress];
        Buyer storage buyer  = IdTobuyer[Id];
        return (buyer.stakedAmount, buyer.useableStake);
    }

    function getArea(address farmerAddress) public view returns(uint256) {
        Farmer storage farmer = IdToFarmer[addressToId[farmerAddress]] ;
        return (farmer.area);
    }

    function calculate(uint _amount) public view returns (uint) {
        uint256 chainlinkDecimals = 10 ** 10;  // chainlink returns in 8 decimals, needs to add 10 more
        uint256 PriceInUsdt = uint256(getLatestPrice()) * chainlinkDecimals;
        uint256 usdtAmount = (_amount * PriceInUsdt) / 10**18;
        return usdtAmount;
   }

    function getLatestPrice() public view returns (int) {
        (,int price,,,) = dataFeed.latestRoundData();
        return price;
    }


}
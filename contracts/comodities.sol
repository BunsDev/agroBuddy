// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";

contract comodities{

    uint256 public requestId;
     IERC20 token;
     address owner;

     constructor(){
        token = IERC20(0x01e6822bE224429218f0E5Fc67f61f6A2744476a);
        owner = msg.sender; 
     }

    struct Request{
        uint256 requestId;
        address borrowerAddress;
        address sellerAddress;
        string _itemName;
        uint256 _timePeriod;
        uint256 price;
        bool requestAccept;
    }

    mapping (uint256 => Request) public IdToRequest;
    mapping (address => uint256) public addressToId;

    event priceSet(address borrowerAddress, address sellerAddress, uint256 price);
    event requestAccepted(address borrowerAddress, address sellerAddress, uint256 price);

    function borrowRequest(string memory _itemName, uint256 _timePeriod) public {
       requestId++;
       IdToRequest[requestId] = 
       Request(
        requestId,
        msg.sender,
        address(0),
        _itemName,
        _timePeriod,
        0,
        false
       );
       addressToId[msg.sender] = requestId;
    }

    function getAllRequest() public view returns(Request[] memory) {
        uint counter = 0;
        Request[] memory request = new Request[](requestId);
         for (uint i = 1; i <= requestId; i++) {
            Request memory currentItem = IdToRequest[i];
            request[counter] = currentItem;
            counter++;
        }
        return request;
    }

    function setPrice(uint256 _requestId, uint256 _price) public {
        Request storage request = IdToRequest[_requestId];
        require(_price > 0 ,"price must be greater than 0");
        request.price = _price;
        request.sellerAddress = msg.sender;
        request.requestAccept = true;
        token.approve(address(this), request.price);
        token.transferFrom(msg.sender, request.sellerAddress, request.price);
        emit requestAccepted(request.borrowerAddress, request.sellerAddress, request.price);   

    }

    // function AcceptRequest(bool _value) public {
    //     requestId = addressToId[msg.sender];
    //     Request storage request = IdToRequest[requestId];
    //     require(request.requestAccept == false,"request already accepted");
    //     request.requestAccept = _value;
    //     token.approve(address(this), request.price);
    //     if(request.requestAccept == true){
    //         token.transferFrom(msg.sender, request.sellerAddress, request.price);
    //         emit requestAccepted(request.borrowerAddress, request.sellerAddress, request.price);   
    //     }

    // }
}
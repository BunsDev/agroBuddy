// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


interface Imuavza{

    function requestClaim(string[] calldata state) external returns (bytes32) ;

    function claim(bytes32 _requestId) external view returns (string memory);

}
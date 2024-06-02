
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";


contract APICall is FunctionsClient {
    address router = 
    0xC22a79eBA640940ABB6dF0f7982cc119578E11De;
    bytes32 donID = 
    0x66756e2d706f6c79676f6e2d616d6f792d310000000000000000000000000000;
    uint64 subscriptionId;

    constructor(uint64 _subscriptionId) FunctionsClient(router) {
       subscriptionId= _subscriptionId;
    }

    using FunctionsRequest for FunctionsRequest.Request;

    bytes32 public s_lastRequestId;
    bytes public s_lastResponse;
    bytes public s_lastError;
    string public results;

    mapping (bytes32 => string) public requestIdToResults;
    
    error UnexpectedRequestID(bytes32 requestId);

    uint32 gasLimit = 300000;

    string APIScript =
        "const characterId = args[0];"
        "const apiResponse = await Functions.makeHttpRequest({"
        "url: `https://restapt-production.up.railway.app/${characterId}`,"
        "});"
        "if (apiResponse.error) {"
        "throw Error('Request failed');"
        "}"
        "const { data } = apiResponse;"
        "return Functions.encodeString(data.data);";

    function APICallFunction(
        string[] calldata args
    ) public returns (bytes32 requestId) {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(APIScript);
        
        if (args.length > 0) req.setArgs(args);
        s_lastRequestId = _sendRequest(
            req.encodeCBOR(),
            subscriptionId,
            gasLimit,
            donID
        );
        return s_lastRequestId;
    }

    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        if (s_lastRequestId != requestId) {
            revert UnexpectedRequestID(requestId);
        }
        s_lastResponse = response;
        s_lastError = err;
        results = string(response);
        requestIdToResults[requestId] = string(response);
        // initContractInstance.fallbackAPICallExecution(result);
    }

    function getValue() public view returns (string memory) {
        return results;
    }

    function requestClaim(string[] calldata state) public returns (bytes32) {
        // string memory mainurl = concatenate(dataUrl, state);
        bytes32 requestId = APICallFunction(state);
        // requestId = requestId;
        return requestId;
    }

    function claim(bytes32 _requestId) public view returns (string memory){
        // string memory result = getValue();
        string memory result = requestIdToResults[_requestId];
        return result;
    }

}
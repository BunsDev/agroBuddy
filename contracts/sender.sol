// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/utils/SafeERC20.sol";
import "./rentTokens.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";


contract Sender is CCIPReceiver, OwnerIsCreator {
    error NoMessageReceived(); 
    error IndexOutOfBound(uint256 providedIndex, uint256 maxIndex); 
    error MessageIdNotExist(bytes32 messageId); 
    error NothingToWithdraw(); 
    error FailedToWithdrawEth(address owner, address target, uint256 value); 

    struct GameSession {
        uint256 rentalId;
        address owner;
        address renter;
        uint256 rentAmount;
        uint256 rentDuration; // in seconds
        uint256 rentStartTime;
        uint256 area;
        uint256 lastPayment;
    }
    mapping(uint256 => GameSession) public gameSessions;
    uint256[] public sessionIds;
    uint256 rentalId = 0;

    uint8[9] initialCombination = [0, 0, 0, 0, 0, 0, 0, 0, 0];


    event MessageSent(
        bytes32 indexed messageId, 
        uint64 indexed destinationChainSelector, 
        address receiver, 
        GameSession message, 
        uint256 fees 
    );

    event MessageReceived(
        bytes32 indexed messageId, 
        uint64 indexed sourceChainSelector, 
        address sender, 
        GameSession message 
    );

    struct Message {
        uint64 sourceChainSelector; 
        address sender; 
        GameSession message;
        address token;
        uint256 amount; 
    }

    bytes32[] public receivedMessages; 
    mapping(bytes32 => Message) public messageDetail;
    address public _router;
    rentTokens public rentalToken;

     IERC20 private s_linkToken;

    constructor(address router, address _link) CCIPReceiver(router) {
        s_linkToken = IERC20(_link);
    }
    function updateRouter(address routerAddr) external {
        _router = routerAddr;
    }

    function updateRealtoken(rentTokens realtoken) external {
        rentalToken = realtoken;
    }

    function start(uint256 rentAmount, 
        uint256 rentDuration, 
        uint256 area, uint64 destinationChainSelector, address receiver) external {
        // bytes32 uniqueId = keccak256(abi.encodePacked(block.timestamp, msg.sender));
        rentalId++;
        sessionIds.push(rentalId);
        gameSessions[rentalId]= GameSession(
            rentalId,
            msg.sender,
            address(0),
            rentAmount,
            rentDuration,
            0,
            area,
            0
            );

        rentalToken.mint(msg.sender, area); 

        sendMessage(destinationChainSelector, receiver, gameSessions[rentalId] );

    }

    function sendMessage(
        uint64 destinationChainSelector,
        address receiver,
        GameSession memory message
    ) public returns (bytes32 messageId) {
        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver), // ABI-encoded receiver address
            data: abi.encode(message), // ABI-encoded string message
            tokenAmounts: new Client.EVMTokenAmount[](0), // Empty array indicating no tokens are being sent
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: 400_000}) // Additional arguments, setting gas limit and non-strict sequency mode
            ),
            feeToken: address(0) // Setting feeToken to zero address, indicating native asset will be used for fees
        });

        // Initialize a router client instance to interact with cross-chain router
        IRouterClient router = IRouterClient(_router);

        // Get the fee required to send the message
        uint256 fees = router.getFee(destinationChainSelector, evm2AnyMessage);

        // Send the message through the router and store the returned message ID
        messageId = router.ccipSend{value: fees}(
            destinationChainSelector,
            evm2AnyMessage
        );

        // Emit an event with message details
        emit MessageSent(
            messageId,
            destinationChainSelector,
            receiver,
            message,
            fees
        );

        // Return the message ID
        return messageId;
    }

    function _ccipReceive(
        Client.Any2EVMMessage memory any2EvmMessage
    )
        internal
        override
    // Make sure source chain and sender are allowlisted
    {
        bytes32 messageId = any2EvmMessage.messageId; // fetch the messageId
         GameSession memory message = abi.decode(any2EvmMessage.data, (GameSession)); // abi-decoding of the sent text
        // Expect one token to be transferred at once, but you can transfer several tokens.
        uint64 sourceChainSelector = any2EvmMessage.sourceChainSelector;
        address sender = abi.decode(any2EvmMessage.sender, (address));
    //    Client.EVMTokenAmount[] memory tokenAmounts = any2EvmMessage.destTokenAmounts;

        address token = any2EvmMessage.destTokenAmounts[0].token;
        uint256 amount = any2EvmMessage.destTokenAmounts[0].amount;

        Message memory detail = Message(sourceChainSelector, sender, message, token, amount);
        messageDetail[messageId] = detail;

    }

    function getNumberOfReceivedMessages()
        external
        view
        returns (uint256 number)
    {
        return receivedMessages.length;
    }

    function getLastReceivedMessageDetails()
        external
        view
        returns (
            bytes32 messageId,
            uint64 sourceChainSelector,
            address sender,
            GameSession memory message
   )
    {
        if (receivedMessages.length == 0) revert NoMessageReceived();

        messageId = receivedMessages[receivedMessages.length - 1];

        Message memory detail = messageDetail[messageId];

        return (
            messageId,
            detail.sourceChainSelector,
            detail.sender,
            detail.message
        );
    }

    receive() external payable {}

    function withdraw(address beneficiary) public onlyOwner {
        uint256 amount = address(this).balance;

        if (amount == 0) revert NothingToWithdraw();

        (bool sent, ) = beneficiary.call{value: amount}("");

        if (!sent) revert FailedToWithdrawEth(msg.sender, beneficiary, amount);
    }

    function getAllRentals() public view returns(GameSession[] memory) {
        uint counter = 0;
        GameSession[] memory farmer = new GameSession[](rentalId);
         for (uint i = 1; i <= rentalId; i++) {
            GameSession memory currentItem = gameSessions[i];
            farmer[counter] = currentItem;
            counter++;
        }
        return farmer;

    }


    function performUpkeep(bytes calldata /* performData */) public {
         for(uint256 i; i > sessionIds.length;i++){
                GameSession storage rental = gameSessions[i];
            require(rental.renter != address(0), "Not rented");
            require(block.timestamp >= rental.lastPayment + 33 days, "rent not payed on time");

            rentalToken.transferFrom(rental.renter, rental.owner, rental.rentAmount);

            rental.renter = address(0);
            rental.rentStartTime = 0;

            // emit RentEnded(rentalId);
        }
    }

}

// 0xd4c92b67D5544F4ED1bD0ed7Edd381d6E7158f89
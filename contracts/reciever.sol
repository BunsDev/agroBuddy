// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/utils/SafeERC20.sol";
import "./rentTokens.sol";


contract Receiver is CCIPReceiver, OwnerIsCreator {
    // Custom errors to provide more descriptive revert messages.
    error NoMessageReceived(); // Used when trying to access a message but no messages have been received.
    error IndexOutOfBound(uint256 providedIndex, uint256 maxIndex); // Used when the provided index is out of bounds.
    error MessageIdNotExist(bytes32 messageId); // Used when the provided message ID does not exist.
    error NothingToWithdraw(); // Used when trying to withdraw Ether but there's nothing to withdraw.
    error FailedToWithdrawEth(address owner, address target, uint256 value); // Used when the withdrawal of Ether fails.
    error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees); // Used to make sure contract has enough balance to cover the fees.


    struct GameSession {
        uint256 rentalId;
        address owner;
        address renter;
        uint256 rentAmount;
        uint256 rentDuration; // in seconds
        uint256 rentStartTime;
        uint256 area;
        uint256 lastPayment;// current status for player 2
    }
    mapping(uint256 => GameSession) public gameSessions;
    uint256[] public sessionIds;
    uint256 rentalId = 0;

    uint8[9] initialCombination = [0, 0, 0, 0, 0, 0, 0, 0, 0];

    // Event emitted when a message is sent to another chain.
    event MessageSent(
        bytes32 indexed messageId, // The unique ID of the message.
        uint64 indexed destinationChainSelector, // The chain selector of the destination chain.
        address receiver, // The address of the receiver on the destination chain.
        GameSession message, // The message being sent.
        uint256 fees // The fees paid for sending the message.
    );

    // Event emitted when a message is received from another chain.
    event MessageReceived(
        bytes32 indexed messageId, // The unique ID of the message.
        uint64 indexed sourceChainSelector, // The chain selector of the source chain.
        address sender, // The address of the sender from the source chain.
        GameSession message // The message that was received.
    );

    // Struct to hold details of a message.
    struct Message {
        uint64 sourceChainSelector; // The chain selector of the source chain.
        address sender; // The address of the sender.
        GameSession message; // The content of the message.
    }

    // Storage variables.
    bytes32[] public receivedMessages; // Array to keep track of the IDs of received messages.
    mapping(bytes32 => Message) public messageDetail; // Mapping from message ID to Message struct, storing details of each received message.
    address public _router;
    rentTokens public rentalToken;
        IERC20 private s_linkToken;


    /// @notice Constructor initializes the contract with the router address.
    /// @param router The address of the router contract.
    constructor(address router, address _link) CCIPReceiver(router) {
        s_linkToken = IERC20(_link);
    }

    function updateRouter(address routerAddr) external {
        _router = routerAddr;
    }

    function updateRealtoken(rentTokens realtoken) external {
        rentalToken = realtoken;
    }


    function acceptRental(uint256 rentId, uint256 _amount, address _token, uint64 destinationChainSelector, address receiver) public{

        GameSession storage rental = gameSessions[rentId];
        rental.renter = msg.sender;
        rental.rentStartTime = block.timestamp;
        rental.lastPayment = block.timestamp;
        
        sendMessage(destinationChainSelector, receiver, gameSessions[rentId], _token, _amount, address(s_linkToken));


    }

    function sendMessage(
        uint64 destinationChainSelector,
        address receiver,
        GameSession memory message,
        address _token,
        uint256 _amount,
        address _feeTokenAddress
    ) public returns (bytes32 messageId) {

        Client.EVMTokenAmount[]
            memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({
            token: _token,
            amount: _amount
        });
        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver), // ABI-encoded receiver address
            data: abi.encode(message), // ABI-encoded string message
            tokenAmounts: tokenAmounts, // Empty array indicating no tokens are being sent
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: 200_000}) // Additional arguments, setting gas limit and non-strict sequency mode
            ),
            feeToken:_feeTokenAddress // Setting feeToken to zero address, indicating native asset will be used for fees
        });

        // Initialize a router client instance to interact with cross-chain router
       
        IRouterClient router = IRouterClient(_router);

        // Get the fee required to send the CCIP message
        uint256 fees = router.getFee(destinationChainSelector, evm2AnyMessage);

         if (fees > address(this).balance)
            revert NotEnoughBalance(address(this).balance, fees);

        // approve the Router to transfer LINK tokens on contract's behalf. It will spend the fees in LINK
        s_linkToken.approve(address(router), fees);

        // approve the Router to spend tokens on contract's behalf. It will spend the amount of the given token
        IERC20(_token).approve(address(router), _amount);

        // Send the message through the router and store the returned message ID
        messageId = router.ccipSend(destinationChainSelector, evm2AnyMessage);

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

    function sendMessagePaylink(
        uint256 rentId,
        uint64 _destinationChainSelector,
        address _receiver,
        // GameSession memory message,
        address _token,
        uint256 _amount
    )
        public
        returns (bytes32 messageId)
    {
        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        // address(0) means fees are paid in native gas
        GameSession storage rental = gameSessions[rentId];
        rental.renter = msg.sender;
        rental.rentStartTime = block.timestamp;
        rental.lastPayment = block.timestamp;

        Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(
            _receiver,
            gameSessions[rentId],
            _token,
            _amount,
            address(s_linkToken)
        );

        // Initialize a router client instance to interact with cross-chain router
        IRouterClient router = IRouterClient(this.getRouter());

        // Get the fee required to send the CCIP message
        uint256 fees = router.getFee(_destinationChainSelector, evm2AnyMessage);

        if (fees > address(this).balance)
            revert NotEnoughBalance(address(this).balance, fees);

        // approve the Router to spend tokens on contract's behalf. It will spend the amount of the given token
        IERC20(_token).approve(address(router), _amount);
        s_linkToken.approve(address(router), fees);


        // Send the message through the router and store the returned message ID
        messageId = router.ccipSend{value: fees}(
            _destinationChainSelector,
            evm2AnyMessage
        );

        // Return the message ID
        return messageId;
    }
    function _buildCCIPMessage(
        address _receiver,
        GameSession memory message,
        address _token,
        uint256 _amount,
        address _feeTokenAddress
    ) private pure returns (Client.EVM2AnyMessage memory) {
        // Set the token amounts
        Client.EVMTokenAmount[]
            memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({
            token: _token,
            amount: _amount
        });
        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        return
            Client.EVM2AnyMessage({
                receiver: abi.encode(_receiver), // ABI-encoded receiver address
                data: abi.encode(message), // ABI-encoded string
                tokenAmounts: tokenAmounts, // The amount and type of token being transferred
                extraArgs: Client._argsToBytes(
                    // Additional arguments, setting gas limit
                    Client.EVMExtraArgsV1({gasLimit: 200_000})
                ),
                // Set the feeToken to a feeTokenAddress, indicating specific asset will be used for fees
                feeToken: _feeTokenAddress
            });
    }
    

    function _ccipReceive(
        Client.Any2EVMMessage memory any2EvmMessage
    ) internal override {
        bytes32 messageId = any2EvmMessage.messageId; // fetch the messageId
        uint64 sourceChainSelector = any2EvmMessage.sourceChainSelector; // fetch the source chain identifier (aka selector)
        address sender = abi.decode(any2EvmMessage.sender, (address)); // abi-decoding of the sender address
        GameSession memory message = abi.decode(any2EvmMessage.data, (GameSession)); // abi-decoding of the sent string message
        receivedMessages.push(messageId);
        Message memory detail = Message(sourceChainSelector, sender, message);
        messageDetail[messageId] = detail;
        gameSessions[message.rentalId] = message;
        sessionIds.push(message.rentalId);

        emit MessageReceived(messageId, sourceChainSelector, sender, message);
    }

    /// @notice Get the total number of received messages.
    /// @return number The total number of received messages.
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
        // Revert if no messages have been received
        if (receivedMessages.length == 0) revert NoMessageReceived();

        // Fetch the last received message ID
        messageId = receivedMessages[receivedMessages.length - 1];

        // Fetch the details of the last received message
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
        // Retrieve the balance of this contract
        uint256 amount = address(this).balance;

        // Revert if there is nothing to withdraw
        if (amount == 0) revert NothingToWithdraw();

        // Attempt to send the funds, capturing the success status and discarding any return data
        (bool sent, ) = beneficiary.call{value: amount}("");

        // Revert if the send failed, with information about the attempted transfer
        if (!sent) revert FailedToWithdrawEth(msg.sender, beneficiary, amount);
    }

    function payRent(uint256 rentId) public {
        GameSession storage rental = gameSessions[rentId];
        require(rental.owner != address(0), "Invalid rental");
        require(rental.renter == address(0), "Already rented");
        // require(paymentToken.transferFrom(msg.sender, rental.owner, rental.rentAmount), "Rent payment failed");

        // rentalToken.transferFrom(rental.renter, rental.owner, rental.rentAmount);

        rental.rentDuration -= 30 days;
        // emit RentPaid(rentalId, msg.sender, rental.rentAmount);
        rental.lastPayment = block.timestamp;
        if(block.timestamp >= rental.rentStartTime + rental.rentDuration){
            endRent(rentalId);
        }

    }

    function endRent(uint256 rentId) public {
        GameSession storage rental = gameSessions[rentId];
        require(rental.renter != address(0), "Not rented");
        require(block.timestamp >= rental.rentStartTime + rental.rentDuration, "Rent period not over");

        rentalToken.transferFrom(rental.renter, rental.owner, rental.rentAmount);

        rental.renter = address(0);
        rental.rentStartTime = 0;

        // emit RentEnded(rentalId);
    }
}


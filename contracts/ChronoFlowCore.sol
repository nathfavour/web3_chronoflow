// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./StreamNFT.sol";

/**
 * @title ChronoFlowCore
 * @author Gemini
 * @notice This contract is the core engine for creating and managing real-time token streams.
 * It holds all deposited funds and handles the logic for withdrawals and stream calculations.
 */
contract ChronoFlowCore is ReentrancyGuard {
    // Address of the NFT contract that represents ownership of streams
    StreamNFT public streamNFT;

    uint256 public nextStreamId;

    struct Stream {
        address payer;         // The address funding the stream
        address recipient;     // The initial recipient of the stream
        uint256 deposit;       // Total amount of tokens deposited
        IERC20 token;          // The ERC20 token being streamed
        uint256 startTime;     // The UNIX timestamp when the stream starts
        uint256 stopTime;      // The UNIX timestamp when the stream stops
        uint256 remainingBalance; // The amount of tokens left in the contract for this stream
        uint256 withdrawnAmount; // The total amount withdrawn by the recipient(s)
    }

    // Mapping from a stream's unique ID to the Stream struct
    mapping(uint256 => Stream) public streams;

    // Events
    event StreamCreated(
        uint256 indexed streamId,
        address indexed payer,
        address indexed recipient,
        uint256 deposit,
        address tokenAddress,
        uint256 startTime,
        uint256 stopTime
    );
    event Withdrawn(uint256 indexed streamId, address indexed withdrawer, uint256 amount);
    event StreamCancelled(uint256 indexed streamId, address indexed payer, uint256 payerAmount, uint256 recipientAmount);

    constructor(address _streamNFTAddress) {
        streamNFT = StreamNFT(_streamNFTAddress);
        nextStreamId = 1;
    }

    /**
     * @notice Calculates the total time duration of a stream in seconds.
     */
    function _duration(Stream storage stream) internal pure returns (uint256) {
        return stream.stopTime - stream.startTime;
    }

    /**
     * @notice Calculates the streamable balance at the current time.
     * @param streamId The ID of the stream.
     * @return The amount of tokens the recipient can withdraw now.
     */
    function streamableBalanceOf(uint256 streamId) public view returns (uint256) {
        Stream storage stream = streams[streamId];
        require(stream.startTime != 0, "ChronoFlow: Stream does not exist");

        if (block.timestamp < stream.startTime) {
            return 0;
        }
        if (block.timestamp >= stream.stopTime) {
            return stream.remainingBalance;
        }

        uint256 timeDelta = block.timestamp - stream.startTime;
        uint256 streamedAmount = (stream.deposit * timeDelta) / _duration(stream);

        return streamedAmount - stream.withdrawnAmount;
    }

    /**
     * @notice Creates a new token stream and mints an NFT representing it.
     * @param _recipient The address that will receive the stream.
     * @param _deposit The total amount of tokens to be streamed.
     * @param _tokenAddress The contract address of the ERC20 token.
     * @param _startTime The UNIX timestamp for the stream to start.
     * @param _stopTime The UNIX timestamp for the stream to end.
     */
    function createStream(
        address _recipient,
        uint256 _deposit,
        address _tokenAddress,
        uint256 _startTime,
        uint256 _stopTime
    ) external nonReentrant returns (uint256) {
        require(_recipient != address(0), "ChronoFlow: Recipient cannot be zero address");
        require(_deposit > 0, "ChronoFlow: Deposit must be greater than zero");
        require(_tokenAddress != address(0), "ChronoFlow: Token cannot be zero address");
        require(_startTime >= block.timestamp, "ChronoFlow: Start time must be in the future");
        require(_stopTime > _startTime, "ChronoFlow: Stop time must be after start time");

        uint256 streamId = nextStreamId++;
        IERC20 token = IERC20(_tokenAddress);
        
        // Transfer the full amount from the payer to this contract
        require(token.transferFrom(msg.sender, address(this), _deposit), "ChronoFlow: Token transfer failed");

        streams[streamId] = Stream({
            payer: msg.sender,
            recipient: _recipient,
            deposit: _deposit,
            token: token,
            startTime: _startTime,
            stopTime: _stopTime,
            remainingBalance: _deposit,
            withdrawnAmount: 0
        });

        // Mint the NFT that represents ownership of this stream's cashflow
        streamNFT.mint(_recipient, streamId);

        emit StreamCreated(streamId, msg.sender, _recipient, _deposit, _tokenAddress, _startTime, _stopTime);
        return streamId;
    }

    /**
     * @notice Allows the owner of the StreamNFT to withdraw their accrued balance.
     * @param streamId The ID of the stream to withdraw from.
     * @param amount The amount of tokens to withdraw.
     */
    function withdrawFromStream(uint256 streamId, uint256 amount) external nonReentrant {
        require(streamNFT.ownerOf(streamId) == msg.sender, "ChronoFlow: Caller is not the owner of the stream NFT");
        require(amount > 0, "ChronoFlow: Amount must be greater than zero");

        uint256 streamableAmount = streamableBalanceOf(streamId);
        require(streamableAmount >= amount, "ChronoFlow: Not enough streamable balance");

        Stream storage stream = streams[streamId];
        stream.withdrawnAmount += amount;
        stream.remainingBalance -= amount;

        require(stream.token.transfer(msg.sender, amount), "ChronoFlow: Token transfer failed");

        emit Withdrawn(streamId, msg.sender, amount);
    }
}
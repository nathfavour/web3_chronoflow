// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ChronoFlowCore.sol";
import "./Base64.sol";

/**
 * @title StreamNFT
 * @author Gemini
 * @notice An ERC721 contract where each token represents a ChronoFlow stream.
 * Metadata is generated dynamically and on-chain to reflect the stream's real-time state.
 */
contract StreamNFT is ERC721, Ownable {
    using Strings for uint256;
    ChronoFlowCore public coreContract;

    constructor(address _coreContractAddress) ERC721("ChronoFlow Stream NFT", "CFS") {
        coreContract = ChronoFlowCore(_coreContractAddress);
    }

    /**
     * @notice Mints a new NFT. Can only be called by the core contract.
     */
    function mint(address _recipient, uint256 _streamId) external {
        require(msg.sender == address(coreContract), "StreamNFT: Caller is not the core contract");
        _safeMint(_recipient, _streamId);
    }

    /**
     * @notice Burns an NFT. Can only be called by the core contract.
     */
    function burn(uint256 _streamId) external {
        require(msg.sender == address(coreContract), "StreamNFT: Caller is not the core contract");
        _burn(_streamId);
    }

    /**
     * @notice Generates the on-chain metadata for a given stream NFT.
     * @dev This is the core of the "living" NFT. It fetches live data and encodes it.
     */
    function tokenURI(uint256 _streamId) public view override returns (string memory) {
        (
            address payer,
            address recipient,
            uint256 deposit,
            IERC20 token,
            uint256 startTime,
            uint256 stopTime,
            uint256 remainingBalance,
            uint256 withdrawnAmount
        ) = coreContract.streams(_streamId);

        uint256 streamable = coreContract.streamableBalanceOf(_streamId);

        string memory name = string(abi.encodePacked("ChronoFlow Stream #", _streamId.toString()));
        string memory description = "A real-time, on-chain stream of value. This NFT represents ownership of the future cashflow.";
        
        string memory attributes = string(abi.encodePacked(
            '{"trait_type": "Payer", "value": "', Strings.toHexString(uint160(payer), 20), '"},',
            '{"trait_type": "Token Address", "value": "', Strings.toHexString(uint160(address(token)), 20), '"},',
            '{"trait_type": "Total Deposit", "value": ', deposit.toString(), '},',
            '{"trait_type": "Withdrawn Amount", "value": ', withdrawnAmount.toString(), '},',
            '{"trait_type": "Streamable Now", "value": ', streamable.toString(), '},',
            '{"trait_type": "Start Time", "value": ', startTime.toString(), ', "display_type": "date"},',
            '{"trait_type": "End Time", "value": ', stopTime.toString(), ', "display_type": "date"}'
        ));

        string memory json = string(abi.encodePacked(
            '{"name": "', name, '",',
            '"description": "', description, '",',
            '"attributes": [', attributes, ']}'
        ));

        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(bytes(json))
        ));
    }
}
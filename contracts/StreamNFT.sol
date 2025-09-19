// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
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

    constructor(address _coreContractAddress) ERC721("ChronoFlow Stream NFT", "CFS") Ownable(msg.sender) {
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
        ChronoFlowCore.Stream memory stream = coreContract.streams(_streamId);
        uint256 streamable = coreContract.streamableBalanceOf(_streamId);

        string memory name = string(abi.encodePacked("ChronoFlow Stream #", _streamId.toString()));
        string memory description = "A real-time, on-chain stream of value. This NFT represents ownership of the future cashflow.";
        
        string memory attributes = string(abi.encodePacked(
            '{"trait_type": "Payer", "value": "', Strings.toHexString(uint160(stream.payer), 20), '"},',
            '{"trait_type": "Token Address", "value": "', Strings.toHexString(uint160(address(stream.token)), 20), '"},',
            '{"trait_type": "Total Deposit", "value": ', stream.deposit.toString(), '},',
            '{"trait_type": "Withdrawn Amount", "value": ', stream.withdrawnAmount.toString(), '},',
            '{"trait_type": "Streamable Now", "value": ', streamable.toString(), '},',
            '{"trait_type": "Start Time", "value": ', stream.startTime.toString(), ', "display_type": "date"},',
            '{"trait_type": "End Time", "value": ', stream.stopTime.toString(), ', "display_type": "date"}'
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
import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("ChronoFlowModule", (m) => {
  const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

  // Deploy StreamNFT with a zero address placeholder for the core contract
  const streamNFT = m.contract("StreamNFT", [ZERO_ADDRESS]);

  // Deploy ChronoFlowCore and point it at the deployed StreamNFT (pass the future itself)
  const chronoCore = m.contract("ChronoFlowCore", [streamNFT]);

  // Set the core contract in StreamNFT (owner is the deployer by default)
  m.call(streamNFT, "setCoreContract", [chronoCore]);

  // Deploy the marketplace pointing at the StreamNFT
  const marketplace = m.contract("ChronoFlowMarketplace", [streamNFT]);

  return { streamNFT, chronoCore, marketplace };
});

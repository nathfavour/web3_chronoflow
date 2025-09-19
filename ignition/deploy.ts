import hre from "hardhat";
import ChronoFlowModule from "./modules/ChronoFlowModule.js";

async function main() {
  const { ignition } = await hre.network.connect();
  const { streamNFT, chronoCore, marketplace } = await ignition.deploy(ChronoFlowModule);

  console.log("ChronoFlow deployment completed!");
  console.log("StreamNFT deployed to:", streamNFT.address);
  console.log("ChronoFlowCore deployed to:", chronoCore.address);
  console.log("ChronoFlowMarketplace deployed to:", marketplace.address);
}

main().catch(console.error);
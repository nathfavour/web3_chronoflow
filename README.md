# ChronoFlow - Real-Time Token Streaming Platform

ChronoFlow is a decentralized platform for creating and managing real-time token streams on the blockchain. It allows users to stream ERC20 tokens over time, creating "living" NFTs that represent ownership of future cashflows.

## Features

- **Real-time Token Streaming**: Stream ERC20 tokens continuously over specified time periods
- **Dynamic NFTs**: Each stream is represented by an NFT with metadata that updates in real-time based on stream state
- **Marketplace**: Built-in marketplace for trading stream NFTs
- **Flexible Withdrawals**: Recipients can withdraw their accrued balance at any time
- **On-chain Metadata**: All NFT metadata is generated and stored on-chain

## Smart Contracts

The platform consists of three main contracts:

### StreamNFT
The ERC721 contract that represents stream ownership. Each token's metadata is dynamically generated to reflect the current state of the stream.

### ChronoFlowCore  
The core engine that manages stream creation, token deposits, and withdrawal logic. Handles all the mathematical calculations for streaming rates.

### ChronoFlowMarketplace
A simple marketplace where users can list and trade their stream NFTs for the native blockchain token.

## Deployed Contracts (Somnia Network)

- **StreamNFT**: `0x75a0d486ce7730fA3752f91D3101997ABc942297`
- **ChronoFlowCore**: `0x5803335a6B851C0438281c7F37E95480f7fc586a`  
- **ChronoFlowMarketplace**: `0x6ff1561da1cce79765E2F541196894F9EF0BC170`

## Usage

### Running Tests

```shell
npx hardhat test
```

### Compilation

```shell
npx hardhat compile
```

### Deployment

To deploy to Somnia network:

```shell
npx hardhat run ignition/deploy.ts --network somnia
```

To deploy to other networks, update the network configuration in `hardhat.config.ts` and run:

```shell
npx hardhat run ignition/deploy.ts --network <network-name>
```

## Environment Setup

Create a `.env` file with your private keys:

```
SOMNIA_PRIVATE_KEY=your_private_key_here
SEPOLIA_PRIVATE_KEY=your_sepolia_private_key_here
```

## How It Works

1. **Create Stream**: Users call `createStream()` with recipient, amount, token, start time, and end time
2. **NFT Minting**: An NFT is automatically minted to represent ownership of the stream
3. **Real-time Streaming**: Tokens become available for withdrawal linearly over the specified time period
4. **Withdrawal**: NFT owners can call `withdrawFromStream()` to claim their accrued balance
5. **Trading**: Stream NFTs can be traded on the built-in marketplace

## Client Integration (Viem)

A minimal TypeScript helper file `contractsClient.ts` is included to streamline frontend or script interactions without a full TypeChain setup.

Example:

```ts
import { initPublicClient, getChronoFlowCoreContract } from './contractsClient';

const pc = initPublicClient();
const core = getChronoFlowCoreContract(pc);

async function demo() {
  const nextId = await core.read.nextStreamId();
  console.log('Next stream id', nextId);
}

demo();
```

To create a stream (ensure the token is approved for transfer):

```ts
import { parseEther } from 'viem';
// Assume you have a wallet client "wc" and ERC20 approval already done.
const streamId = await core.write.createStream([
  recipientAddress,
  parseEther('10'), // deposit amount
  tokenAddress,
  Math.floor(Date.now()/1000) + 60, // start in 1 min
  Math.floor(Date.now()/1000) + 3600 // stop in 1 hour
]);
console.log('Created stream', streamId);
```

You can switch to a stronger typing story later using TypeChain or viem's `generate` if desired. A wagmi CLI config (`wagmi.config.ts`) is provided so you can run `npm install @wagmi/cli @wagmi/core wagmi react@latest` in a Next.js project and then `npm run codegen` here to emit `generated/wagmi.ts` with typed hooks.

## Technical Details

- Built with Solidity 0.8.28
- Uses OpenZeppelin contracts for security and standards compliance
- Hardhat 3 Beta for development and testing
- Viem integration for type-safe Ethereum interactions
- On-chain Base64 encoding for dynamic NFT metadata

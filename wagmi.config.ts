import { defineConfig } from '@wagmi/cli';
import { react } from '@wagmi/cli/plugins';
import { Abi } from 'viem';
import { streamNftAbi, chronoFlowCoreAbi, marketplaceAbi, addresses } from './contractsClient';

// Central manifest enabling generation of typed hooks for Next.js/React usage.
export default defineConfig({
  out: 'generated/wagmi.ts',
  plugins: [react()],
  contracts: [
    { name: 'StreamNFT', abi: streamNftAbi as Abi, address: addresses.StreamNFT },
    { name: 'ChronoFlowCore', abi: chronoFlowCoreAbi as Abi, address: addresses.ChronoFlowCore },
    { name: 'ChronoFlowMarketplace', abi: marketplaceAbi as Abi, address: addresses.ChronoFlowMarketplace },
  ],
});

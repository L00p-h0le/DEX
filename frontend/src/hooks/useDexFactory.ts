import { useReadContract, useReadContracts, useChainId } from 'wagmi';
import type { Address } from 'viem';
import { FACTORY_ABI, PAIR_ABI } from '../constants/abi';
import { CONTRACTS } from '../constants/constants';

export function useDexFactory() {
  const chainId = useChainId();
  const factoryAddress = CONTRACTS[chainId as keyof typeof CONTRACTS]?.factory as Address;
  return factoryAddress;
}

export function usePairAddress(tokenA?: Address, tokenB?: Address) {
  const factoryAddress = useDexFactory();

  return useReadContract({
    address: factoryAddress,
    abi: FACTORY_ABI,
    functionName: 'getPair',
    args: tokenA && tokenB ? [tokenA, tokenB] as const : undefined,
    query: {
      enabled: !!factoryAddress && !!tokenA && !!tokenB,
      refetchInterval: 3000,
    }
  });
}

export function usePairData(pairAddress?: Address) {
  return useReadContracts({
    contracts: [
      {
        address: pairAddress,
        abi: PAIR_ABI,
        functionName: 'getReserve',
      },
      {
        address: pairAddress,
        abi: PAIR_ABI,
        functionName: 'totalSupply',
      },
      {
        address: pairAddress,
        abi: PAIR_ABI,
        functionName: 'token0',
      }
    ],
    query: {
      enabled: !!pairAddress && pairAddress !== '0x0000000000000000000000000000000000000000',
      refetchInterval: 3000,
    }
  });
}

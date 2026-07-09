import { useReadContract, useChainId } from 'wagmi';
import type { Address } from 'viem';
import { FACTORY_ABI } from '../constants/abi';
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
    }
  });
}

import { useReadContract, useWriteContract, useWaitForTransactionReceipt, useChainId } from 'wagmi';
import type { Address } from 'viem';
import { ROUTER_ABI } from '../constants/abi';
import { CONTRACTS } from '../constants/constants';

export function useDexRouterAddress() {
  const chainId = useChainId();
  return CONTRACTS[chainId as keyof typeof CONTRACTS]?.router as Address;
}

export function useAmountsOut(amountIn: bigint, path?: Address[]) {
  const routerAddress = useDexRouterAddress();

  return useReadContract({
    address: routerAddress,
    abi: ROUTER_ABI,
    functionName: 'getAmountsOut',
    args: path ? [amountIn, path] as const : undefined,
    query: {
      enabled: !!routerAddress && !!path && path.length >= 2 && amountIn > 0n,
      refetchInterval: 3000,
    }
  });
}

export function useSwap() {
  const routerAddress = useDexRouterAddress();
  const { writeContractAsync, data: hash, isPending: isWritePending, error: writeError } = useWriteContract();

  const { isLoading: isWaiting, isSuccess: isConfirmed } = useWaitForTransactionReceipt({
    hash,
  });

  const swap = async (amountIn: bigint, amountOutMin: bigint, path: Address[], to: Address, deadline: bigint) => {
    if (!routerAddress) throw new Error("Router not found");
    return writeContractAsync({
      address: routerAddress,
      abi: ROUTER_ABI as any,
      functionName: 'swapExactTokensForTokens',
      args: [amountIn, amountOutMin, path, to, deadline] as const,
    } as any);
  };

  return {
    swap,
    hash,
    isPending: isWritePending || isWaiting,
    isSuccess: isConfirmed,
    error: writeError,
  };
}

export function useAddLiquidity() {
  const routerAddress = useDexRouterAddress();
  const { writeContractAsync, data: hash, isPending: isWritePending, error: writeError } = useWriteContract();

  const { isLoading: isWaiting, isSuccess: isConfirmed } = useWaitForTransactionReceipt({
    hash,
  });

  const addLiquidity = async (
    tokenA: Address, 
    tokenB: Address, 
    amountADesired: bigint, 
    amountBDesired: bigint, 
    amountAMin: bigint, 
    amountBMin: bigint, 
    to: Address, 
    deadline: bigint
  ) => {
    if (!routerAddress) throw new Error("Router not found");
    return writeContractAsync({
      address: routerAddress,
      abi: ROUTER_ABI as any,
      functionName: 'addLiquidity',
      args: [tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin, to, deadline] as const,
    } as any);
  };

  return {
    addLiquidity,
    hash,
    isPending: isWritePending || isWaiting,
    isSuccess: isConfirmed,
    error: writeError,
  };
}

export function useRemoveLiquidity() {
  const routerAddress = useDexRouterAddress();
  const { writeContractAsync, data: hash, isPending: isWritePending, error: writeError } = useWriteContract();

  const { isLoading: isWaiting, isSuccess: isConfirmed } = useWaitForTransactionReceipt({
    hash,
  });

  const removeLiquidity = async (
    tokenA: Address, 
    tokenB: Address, 
    liquidity: bigint, 
    amountAMin: bigint, 
    amountBMin: bigint, 
    to: Address, 
    deadline: bigint
  ) => {
    if (!routerAddress) throw new Error("Router not found");
    return writeContractAsync({
      address: routerAddress,
      abi: ROUTER_ABI as any,
      functionName: 'removeLiquidity',
      args: [tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline] as const,
    } as any);
  };

  return {
    removeLiquidity,
    hash,
    isPending: isWritePending || isWaiting,
    isSuccess: isConfirmed,
    error: writeError,
  };
}

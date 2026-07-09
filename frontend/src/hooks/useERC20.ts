import { useReadContract, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { erc20Abi } from 'viem';
import type { Address } from 'viem';

export function useERC20Balance(tokenAddress?: Address, owner?: Address) {
  return useReadContract({
    address: tokenAddress,
    abi: erc20Abi,
    functionName: 'balanceOf',
    args: owner ? [owner] as const : undefined,
    query: {
      enabled: !!tokenAddress && !!owner,
      refetchInterval: 3000,
    }
  });
}

export function useERC20Allowance(tokenAddress?: Address, owner?: Address, spender?: Address) {
  return useReadContract({
    address: tokenAddress,
    abi: erc20Abi,
    functionName: 'allowance',
    args: owner && spender ? [owner, spender] as const : undefined,
    query: {
      enabled: !!tokenAddress && !!owner && !!spender,
      refetchInterval: 3000,
    }
  });
}

export function useERC20Approve(tokenAddress?: Address) {
  const { writeContractAsync, data: hash, isPending: isWritePending, error: writeError } = useWriteContract();

  const { isLoading: isWaiting, isSuccess: isConfirmed } = useWaitForTransactionReceipt({
    hash,
  });

  const approve = async (spender: Address, amount: bigint) => {
    if (!tokenAddress) throw new Error("No token address");
    return writeContractAsync({
      address: tokenAddress,
      abi: erc20Abi,
      functionName: 'approve',
      args: [spender, amount] as const,
    } as any);
  };

  return {
    approve,
    hash,
    isPending: isWritePending || isWaiting,
    isSuccess: isConfirmed,
    error: writeError,
  };
}

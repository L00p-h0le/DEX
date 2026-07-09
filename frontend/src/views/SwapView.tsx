import { useState, useEffect } from 'react';
import { useAccount } from 'wagmi';
import { parseUnits, formatUnits, isAddress } from 'viem';
import type { Address } from 'viem';
import { TokenInput } from '../components/TokenInput';
import { Button } from '../components/Button';
import { Card } from '../components/Card';
import { useDexRouterAddress, useAmountsOut, useSwap } from '../hooks/useDexRouter';
import { useERC20Allowance, useERC20Approve } from '../hooks/useERC20';

export function SwapView() {
  const { address: account } = useAccount();
  const [tokenIn, setTokenIn] = useState('');
  const [tokenOut, setTokenOut] = useState('');
  const [amountIn, setAmountIn] = useState('');
  const [slippage, setSlippage] = useState(0.5);
  
  const [debouncedAmountIn, setDebouncedAmountIn] = useState('');
  useEffect(() => {
    const timer = setTimeout(() => setDebouncedAmountIn(amountIn), 400);
    return () => clearTimeout(timer);
  }, [amountIn]);

  const parsedAmountIn = debouncedAmountIn && !isNaN(Number(debouncedAmountIn)) ? parseUnits(debouncedAmountIn, 18) : 0n;
  const path = isAddress(tokenIn) && isAddress(tokenOut) ? [tokenIn as Address, tokenOut as Address] : undefined;

  const { data: amountsOutData } = useAmountsOut(parsedAmountIn, path);
  const amountOut = amountsOutData ? formatUnits(amountsOutData[1], 18) : '';

  const routerAddress = useDexRouterAddress();
  const { data: allowanceData, refetch: refetchAllowance } = useERC20Allowance(
    isAddress(tokenIn) ? (tokenIn as Address) : undefined,
    account,
    routerAddress
  );

  const { approve, isPending: isApprovePending, isSuccess: isApproveSuccess } = useERC20Approve(
    isAddress(tokenIn) ? (tokenIn as Address) : undefined
  );
  
  useEffect(() => {
    if (isApproveSuccess) {
      refetchAllowance();
    }
  }, [isApproveSuccess, refetchAllowance]);

  const { swap, isPending: isSwapPending } = useSwap();

  const handleApprove = () => {
    approve(routerAddress, parsedAmountIn);
  };

  const handleSwap = () => {
    if (!path || !account || !amountsOutData) return;
    const expectedOut = amountsOutData[1];
    const slippageMultiplier = BigInt(Math.floor((100 - slippage) * 100));
    const minAmountOut = (expectedOut * slippageMultiplier) / 10000n;
    
    const deadline = BigInt(Math.floor(Date.now() / 1000) + 20 * 60);
    swap(parsedAmountIn, minAmountOut, path, account, deadline);
  };

  const needsApproval = allowanceData !== undefined && allowanceData < parsedAmountIn;

  return (
    <div className="max-w-xl mx-auto w-full mt-10">
      <Card heavyShadow className="bg-[#FFF4E0]">
        <div className="flex justify-between items-center mb-6">
          <h2 className="text-3xl font-black uppercase tracking-tight">Swap</h2>
          <div className="flex gap-2 items-center">
             <span className="text-xs font-bold uppercase">Slippage</span>
             <select 
                className="neo-input py-1 px-2 text-sm bg-white" 
                value={slippage} 
                onChange={(e) => setSlippage(Number(e.target.value))}
             >
                <option value={0.1}>0.1%</option>
                <option value={0.5}>0.5%</option>
                <option value={1.0}>1.0%</option>
             </select>
          </div>
        </div>
        
        <TokenInput
          label="You Pay"
          amount={amountIn}
          onAmountChange={setAmountIn}
          address={tokenIn}
          onAddressChange={setTokenIn}
        />

        <TokenInput
          label="You Receive"
          amount={amountOut}
          onAmountChange={() => {}}
          address={tokenOut}
          onAddressChange={setTokenOut}
          disabled={true}
        />

        {!account ? (
          <Button fullWidth disabled variant="secondary">
            Connect Wallet
          </Button>
        ) : parsedAmountIn === 0n ? (
          <Button fullWidth disabled variant="secondary">
            Enter an amount
          </Button>
        ) : needsApproval ? (
          <Button fullWidth onClick={handleApprove} disabled={isApprovePending}>
            {isApprovePending ? 'Approving...' : 'Approve'}
          </Button>
        ) : (
          <Button fullWidth onClick={handleSwap} disabled={isSwapPending || !isAddress(tokenIn) || !isAddress(tokenOut)}>
            {isSwapPending ? 'Swapping...' : 'Swap'}
          </Button>
        )}
      </Card>
    </div>
  );
}

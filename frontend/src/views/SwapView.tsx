import { useState, useEffect } from 'react';
import { toast } from 'react-hot-toast';
import { useAccount } from 'wagmi';
import { parseUnits, formatUnits, isAddress } from 'viem';
import type { Address } from 'viem';
import { TokenInput } from '../components/TokenInput';
import { Button } from '../components/Button';
import { Card } from '../components/Card';
import { useDexRouterAddress, useAmountsOut, useSwap } from '../hooks/useDexRouter';
import { useERC20Allowance, useERC20Approve, useERC20Balance } from '../hooks/useERC20';
import { usePairAddress } from '../hooks/useDexFactory';

export function SwapView() {
  const { address: account } = useAccount();
  const [tokenIn, setTokenIn] = useState('');
  const [tokenOut, setTokenOut] = useState('');
  const [amountIn, setAmountIn] = useState('');
  const [slippage, setSlippage] = useState(0.5);
  const [deadlineMinutes, setDeadlineMinutes] = useState(20);
  
  useEffect(() => {
    if (!account) {
      setTokenIn('');
      setTokenOut('');
      setAmountIn('');
    }
  }, [account]);
  
  const [debouncedAmountIn, setDebouncedAmountIn] = useState('');
  useEffect(() => {
    const timer = setTimeout(() => setDebouncedAmountIn(amountIn), 400);
    return () => clearTimeout(timer);
  }, [amountIn]);

  const parsedAmountIn = debouncedAmountIn && !isNaN(Number(debouncedAmountIn)) ? parseUnits(debouncedAmountIn, 18) : 0n;
  const path = isAddress(tokenIn) && isAddress(tokenOut) ? [tokenIn as Address, tokenOut as Address] : undefined;

  const { data: amountsOutData, isError: isAmountsOutError, isLoading: isAmountsOutLoading } = useAmountsOut(parsedAmountIn, path);
  const amountOut = amountsOutData ? formatUnits(amountsOutData[1], 18) : '';

  const { data: pairAddress } = usePairAddress(
    isAddress(tokenIn) ? (tokenIn as Address) : undefined,
    isAddress(tokenOut) ? (tokenOut as Address) : undefined
  );

  const { data: balanceIn } = useERC20Balance(
    isAddress(tokenIn) ? (tokenIn as Address) : undefined,
    pairAddress as Address | undefined
  );

  const { data: balanceOut } = useERC20Balance(
    isAddress(tokenOut) ? (tokenOut as Address) : undefined,
    pairAddress as Address | undefined
  );

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

  let priceImpact = 0;
  if (parsedAmountIn > 0n && amountsOutData && balanceIn && balanceOut && balanceIn > 0n) {
    const expectedOut = amountsOutData[1];
    const idealAmountOut = (parsedAmountIn * balanceOut) / balanceIn;
    if (idealAmountOut > 0n) {
      priceImpact = Number(((idealAmountOut - expectedOut) * 10000n) / idealAmountOut) / 100;
      if (priceImpact < 0) priceImpact = 0;
    }
  }

  const { swap, isPending: isSwapPending, isSuccess: isSwapSuccess } = useSwap();
  
  useEffect(() => {
    if (isSwapSuccess) {
      toast.success('Swap successful!');
      setAmountIn('');
    }
  }, [isSwapSuccess]);

  const handleApprove = () => {
    approve(routerAddress, parsedAmountIn);
  };

  const handleSwap = async () => {
    if (!path || !account || !amountsOutData) return;
    const expectedOut = amountsOutData[1];
    const slippageMultiplier = BigInt(Math.floor((100 - slippage) * 100));
    const minAmountOut = (expectedOut * slippageMultiplier) / 10000n;
    
    const deadline = BigInt(Math.floor(Date.now() / 1000) + deadlineMinutes * 60);
    try {
      await swap(parsedAmountIn, minAmountOut, path, account, deadline);
    } catch (err: any) {
      toast.error(err.shortMessage || err.message || 'Swap failed');
    }
  };

  const handleSwitchTokens = () => {
    const temp = tokenIn;
    setTokenIn(tokenOut);
    setTokenOut(temp);
  };

  const needsApproval = allowanceData !== undefined && allowanceData < parsedAmountIn;

  return (
    <div className="max-w-xl mx-auto w-full mt-10">
      <Card heavyShadow className="bg-[#FFF4E0]">
        <div className="flex justify-between items-center mb-6">
          <h2 className="text-3xl font-black uppercase tracking-tight">Swap</h2>
          <div className="flex gap-4 items-center">
             <div className="flex gap-2 items-center">
                <span className="text-xs font-bold uppercase">Deadline (m)</span>
                <input 
                  type="number" 
                  min="1" 
                  className="neo-input py-1 px-2 text-sm bg-white w-16" 
                  value={deadlineMinutes} 
                  onChange={(e) => setDeadlineMinutes(Number(e.target.value))} 
                />
             </div>
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
        </div>

        <div className="flex justify-between items-center bg-white border-[3px] border-black p-3 mb-6">
          <span className="font-bold text-sm uppercase">Pool Liquidity</span>
          <div className="flex gap-4 text-xs font-mono font-bold">
            <span>In: {isAddress(tokenIn) && isAddress(tokenOut) && pairAddress && pairAddress !== '0x0000000000000000000000000000000000000000' && balanceIn !== undefined ? parseFloat(formatUnits(balanceIn, 18)).toFixed(4) : '-'}</span>
            <span>Out: {isAddress(tokenIn) && isAddress(tokenOut) && pairAddress && pairAddress !== '0x0000000000000000000000000000000000000000' && balanceOut !== undefined ? parseFloat(formatUnits(balanceOut, 18)).toFixed(4) : '-'}</span>
          </div>
        </div>
        
        <div className="flex flex-col relative">
          <TokenInput
            label="You Pay"
            amount={amountIn}
            onAmountChange={setAmountIn}
            address={tokenIn}
            onAddressChange={setTokenIn}
          />

          <div className="absolute left-1/2 top-[calc(50%-8px)] -translate-x-1/2 -translate-y-1/2 z-10">
            <button 
              onClick={handleSwitchTokens}
              className="w-12 h-12 flex items-center justify-center bg-[#CCFF00] border-[3px] border-black hover:bg-[#b8e600] active:translate-y-1 active:translate-x-1 shadow-[4px_4px_0px_rgba(0,0,0,1)] active:shadow-none transition-all cursor-pointer"
            >
              <svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="black" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
                <path d="m3 16 4 4 4-4" />
                <path d="M7 20V4" />
                <path d="m21 8-4-4-4 4" />
                <path d="M17 4v16" />
              </svg>
            </button>
          </div>

          <TokenInput
            label="You Receive"
            amount={amountOut}
            onAmountChange={() => {}}
            address={tokenOut}
            onAddressChange={setTokenOut}
            disabled={true}
          />
        </div>

        {parsedAmountIn > 0n && amountsOutData && (
          <div className="flex justify-between items-center bg-white border-[3px] border-black p-3 mb-6">
            <span className="font-bold text-sm uppercase">Price Impact</span>
            <span className={`font-bold text-sm ${priceImpact >= 3 ? 'text-red-600' : priceImpact >= 1 ? 'text-orange-500' : 'text-green-600'}`}>
              {priceImpact.toFixed(2)}%
            </span>
          </div>
        )}

        {!account ? (
          <Button fullWidth disabled variant="secondary">
            Connect Wallet
          </Button>
        ) : parsedAmountIn === 0n ? (
          <Button fullWidth disabled variant="secondary">
            Enter an amount
          </Button>
        ) : isAmountsOutLoading ? (
          <Button fullWidth disabled variant="secondary">
            Calculating...
          </Button>
        ) : isAmountsOutError || !amountsOutData ? (
          <Button fullWidth disabled variant="secondary">
            Insufficient Liquidity
          </Button>
        ) : balanceIn !== undefined && parsedAmountIn > balanceIn ? (
          <Button fullWidth disabled variant="secondary">
            Insufficient Balance
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

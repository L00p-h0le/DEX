import { useState, useEffect } from 'react';
import { toast } from 'react-hot-toast';
import { useAccount } from 'wagmi';
import { parseUnits, formatUnits, isAddress } from 'viem';
import type { Address } from 'viem';
import { TokenInput } from '../components/TokenInput';
import { AddressInput } from '../components/AddressInput';
import { Button } from '../components/Button';
import { Card } from '../components/Card';
import { useDexRouterAddress, useAddLiquidity, useRemoveLiquidity } from '../hooks/useDexRouter';
import { useERC20Allowance, useERC20Approve, useERC20Balance } from '../hooks/useERC20';
import { usePairAddress, usePairData } from '../hooks/useDexFactory';

export function LiquidityView() {
  const [tab, setTab] = useState<'add' | 'remove'>('add');
  const [deadlineMinutes, setDeadlineMinutes] = useState(20);
  const { address: account } = useAccount();

  return (
    <div className="max-w-xl mx-auto w-full mt-10">
      <Card heavyShadow className="bg-[#E0F4FF]">
        <div className="flex justify-between items-center mb-6">
          <h2 className="text-3xl font-black uppercase tracking-tight">Liquidity</h2>
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
             <div className="flex bg-white border-2 border-black rounded-sm overflow-hidden neo-shadow-sm">
               <button 
                 className={`px-4 py-1 text-sm font-bold uppercase ${tab === 'add' ? 'bg-[#FF90E8]' : 'bg-white hover:bg-gray-100'}`}
                 onClick={() => setTab('add')}
               >
                 Add
               </button>
               <div className="w-[2px] bg-black"></div>
               <button 
                 className={`px-4 py-1 text-sm font-bold uppercase ${tab === 'remove' ? 'bg-[#FF90E8]' : 'bg-white hover:bg-gray-100'}`}
                 onClick={() => setTab('remove')}
               >
                 Remove
               </button>
             </div>
          </div>
        </div>

        <div style={{ display: tab === 'add' ? 'block' : 'none' }}>
          <AddLiquidity account={account} deadlineMinutes={deadlineMinutes} />
        </div>
        <div style={{ display: tab === 'remove' ? 'block' : 'none' }}>
          <RemoveLiquidity account={account} deadlineMinutes={deadlineMinutes} />
        </div>
      </Card>
    </div>
  );
}

function AddLiquidity({ account, deadlineMinutes }: { account?: Address, deadlineMinutes: number }) {
  const [tokenA, setTokenA] = useState('');
  const [tokenB, setTokenB] = useState('');
  const [amountA, setAmountA] = useState('');
  const [amountB, setAmountB] = useState('');
  const [lastChanged, setLastChanged] = useState<'A' | 'B'>('A');

  useEffect(() => {
    if (!account) {
      setTokenA('');
      setTokenB('');
      setAmountA('');
      setAmountB('');
    }
  }, [account]);
  
  const parsedAmountA = amountA && !isNaN(Number(amountA)) ? parseUnits(amountA, 18) : 0n;
  const parsedAmountB = amountB && !isNaN(Number(amountB)) ? parseUnits(amountB, 18) : 0n;

  const routerAddress = useDexRouterAddress();
  
  const { data: pairAddress } = usePairAddress(
    isAddress(tokenA) ? (tokenA as Address) : undefined,
    isAddress(tokenB) ? (tokenB as Address) : undefined
  );

  const { data: pairData } = usePairData(pairAddress as Address | undefined);
  const reserves = pairData?.[0]?.result as readonly [bigint, bigint, number] | undefined;
  const totalSupply = pairData?.[1]?.result as bigint | undefined;
  const token0 = pairData?.[2]?.result as Address | undefined;

  useEffect(() => {
    if (!reserves || !token0) return;
    const isAToken0 = tokenA.toLowerCase() === token0.toLowerCase();
    const reserveA = isAToken0 ? reserves[0] : reserves[1];
    const reserveB = isAToken0 ? reserves[1] : reserves[0];

    if (reserveA === 0n || reserveB === 0n) return;

    if (lastChanged === 'A' && parsedAmountA > 0n) {
      const calculatedB = (parsedAmountA * reserveB) / reserveA;
      setAmountB(formatUnits(calculatedB, 18));
    } else if (lastChanged === 'B' && parsedAmountB > 0n) {
      const calculatedA = (parsedAmountB * reserveA) / reserveB;
      setAmountA(formatUnits(calculatedA, 18));
    }
  }, [amountA, amountB, lastChanged, reserves, token0, tokenA]);

  let estimatedLP = 0n;
  let poolShare = 0;
  
  if (parsedAmountA > 0n && parsedAmountB > 0n) {
    if (!reserves || reserves[0] === 0n || !totalSupply) {
      const aNum = Number(formatUnits(parsedAmountA, 18));
      const bNum = Number(formatUnits(parsedAmountB, 18));
      estimatedLP = parseUnits(Math.sqrt(aNum * bNum).toFixed(18), 18);
      poolShare = 100;
    } else {
      const isAToken0 = tokenA.toLowerCase() === token0?.toLowerCase();
      const reserveA = isAToken0 ? reserves[0] : reserves[1];
      const reserveB = isAToken0 ? reserves[1] : reserves[0];
      
      const liquidityA = (parsedAmountA * totalSupply) / reserveA;
      const liquidityB = (parsedAmountB * totalSupply) / reserveB;
      estimatedLP = liquidityA < liquidityB ? liquidityA : liquidityB;
      poolShare = Number((estimatedLP * 10000n) / (totalSupply + estimatedLP)) / 100;
    }
  }

  const { data: allowanceA, refetch: refetchA } = useERC20Allowance(
    isAddress(tokenA) ? (tokenA as Address) : undefined, account, routerAddress
  );
  const { data: allowanceB, refetch: refetchB } = useERC20Allowance(
    isAddress(tokenB) ? (tokenB as Address) : undefined, account, routerAddress
  );

  const { approve: approveA, isPending: isApproveAPending, isSuccess: isApproveASuccess } = useERC20Approve(isAddress(tokenA) ? (tokenA as Address) : undefined);
  const { approve: approveB, isPending: isApproveBPending, isSuccess: isApproveBSuccess } = useERC20Approve(isAddress(tokenB) ? (tokenB as Address) : undefined);

  const { data: balanceA } = useERC20Balance(isAddress(tokenA) ? (tokenA as Address) : undefined, account);
  const { data: balanceB } = useERC20Balance(isAddress(tokenB) ? (tokenB as Address) : undefined, account);
  
  useEffect(() => { if (isApproveASuccess) refetchA(); }, [isApproveASuccess, refetchA]);
  useEffect(() => { if (isApproveBSuccess) refetchB(); }, [isApproveBSuccess, refetchB]);

  const { addLiquidity, isPending: isAddPending, isSuccess: isAddSuccess } = useAddLiquidity();

  useEffect(() => {
    if (isAddSuccess) {
      toast.success('Liquidity added!');
      setAmountA('');
      setAmountB('');
    }
  }, [isAddSuccess]);

  const handleAdd = async () => {
    if (!account || !isAddress(tokenA) || !isAddress(tokenB)) return;
    const deadline = BigInt(Math.floor(Date.now() / 1000) + deadlineMinutes * 60);
    try {
      await addLiquidity(tokenA as Address, tokenB as Address, parsedAmountA, parsedAmountB, 0n, 0n, account, deadline);
    } catch (err: any) {
      toast.error(err.shortMessage || err.message || 'Transaction failed');
    }
  };

  const needsApproveA = allowanceA !== undefined && allowanceA < parsedAmountA;
  const needsApproveB = allowanceB !== undefined && allowanceB < parsedAmountB;
  const insufficientA = balanceA !== undefined && balanceA < parsedAmountA;
  const insufficientB = balanceB !== undefined && balanceB < parsedAmountB;

  return (
    <div className="flex flex-col gap-4">
      <TokenInput label="Token A" amount={amountA} onAmountChange={(v) => { setAmountA(v); setLastChanged('A'); }} address={tokenA} onAddressChange={setTokenA} />
      <div className="text-center font-black text-2xl">+</div>
      <TokenInput label="Token B" amount={amountB} onAmountChange={(v) => { setAmountB(v); setLastChanged('B'); }} address={tokenB} onAddressChange={setTokenB} />

      {account && parsedAmountA > 0n && parsedAmountB > 0n && (
        <div className="flex flex-col gap-2 bg-white border-[3px] border-black p-3 mb-2">
          <div className="flex justify-between items-center">
            <span className="font-bold text-sm uppercase">Est. LP Tokens</span>
            <span className="font-bold text-sm">{formatUnits(estimatedLP, 18)}</span>
          </div>
          <div className="flex justify-between items-center">
            <span className="font-bold text-sm uppercase">Pool Share</span>
            <span className="font-bold text-sm">{poolShare.toFixed(2)}%</span>
          </div>
        </div>
      )}

      {!account ? (
        <Button fullWidth disabled variant="secondary">Connect Wallet</Button>
      ) : parsedAmountA === 0n || parsedAmountB === 0n ? (
        <Button fullWidth disabled variant="secondary">Enter amounts</Button>
      ) : insufficientA || insufficientB ? (
        <Button fullWidth disabled variant="secondary">Insufficient Balance</Button>
      ) : needsApproveA ? (
        <Button fullWidth onClick={() => approveA(routerAddress, parsedAmountA)} disabled={isApproveAPending}>
          {isApproveAPending ? 'Approving Token A...' : 'Approve Token A'}
        </Button>
      ) : needsApproveB ? (
        <Button fullWidth onClick={() => approveB(routerAddress, parsedAmountB)} disabled={isApproveBPending}>
          {isApproveBPending ? 'Approving Token B...' : 'Approve Token B'}
        </Button>
      ) : (
        <Button fullWidth onClick={handleAdd} disabled={isAddPending || !isAddress(tokenA) || !isAddress(tokenB)}>
          {isAddPending ? 'Adding...' : 'Add Liquidity'}
        </Button>
      )}
    </div>
  );
}

function RemoveLiquidity({ account, deadlineMinutes }: { account?: Address, deadlineMinutes: number }) {
  const [tokenA, setTokenA] = useState('');
  const [tokenB, setTokenB] = useState('');
  const [liquidity, setLiquidity] = useState('');

  useEffect(() => {
    if (!account) {
      setTokenA('');
      setTokenB('');
      setLiquidity('');
    }
  }, [account]);

  const parsedLiquidity = liquidity && !isNaN(Number(liquidity)) ? parseUnits(liquidity, 18) : 0n;
  const routerAddress = useDexRouterAddress();

  const { data: pairAddress } = usePairAddress(
    isAddress(tokenA) ? (tokenA as Address) : undefined,
    isAddress(tokenB) ? (tokenB as Address) : undefined
  );

  const { data: allowanceLP, refetch: refetchLP } = useERC20Allowance(
    pairAddress as Address | undefined, account, routerAddress
  );

  const { data: lpBalance } = useERC20Balance(pairAddress as Address | undefined, account);

  const { data: pairData } = usePairData(pairAddress as Address | undefined);
  const reserves = pairData?.[0]?.result as readonly [bigint, bigint, number] | undefined;
  const totalSupply = pairData?.[1]?.result as bigint | undefined;
  const token0 = pairData?.[2]?.result as Address | undefined;

  let estA = 0n;
  let estB = 0n;
  if (parsedLiquidity > 0n && reserves && totalSupply && token0) {
    const isAToken0 = tokenA.toLowerCase() === token0.toLowerCase();
    const reserveA = isAToken0 ? reserves[0] : reserves[1];
    const reserveB = isAToken0 ? reserves[1] : reserves[0];
    
    estA = (parsedLiquidity * reserveA) / totalSupply;
    estB = (parsedLiquidity * reserveB) / totalSupply;
  }

  const handlePercentage = (percent: number) => {
    if (!lpBalance) return;
    const amount = (lpBalance * BigInt(percent)) / 100n;
    setLiquidity(formatUnits(amount, 18));
  };

  const { approve: approveLP, isPending: isApproveLPPending, isSuccess: isApproveLPSuccess } = useERC20Approve(pairAddress as Address | undefined);
  
  useEffect(() => { if (isApproveLPSuccess) refetchLP(); }, [isApproveLPSuccess, refetchLP]);

  const { removeLiquidity, isPending: isRemovePending, isSuccess: isRemoveSuccess } = useRemoveLiquidity();

  useEffect(() => {
    if (isRemoveSuccess) {
      toast.success('Liquidity removed!');
      setLiquidity('');
    }
  }, [isRemoveSuccess]);

  const handleRemove = async () => {
    if (!account || !isAddress(tokenA) || !isAddress(tokenB)) return;
    const deadline = BigInt(Math.floor(Date.now() / 1000) + deadlineMinutes * 60);
    try {
      await removeLiquidity(tokenA as Address, tokenB as Address, parsedLiquidity, 0n, 0n, account, deadline);
    } catch (err: any) {
      toast.error(err.shortMessage || err.message || 'Transaction failed');
    }
  };

  const needsApproveLP = allowanceLP !== undefined && allowanceLP < parsedLiquidity;

  return (
    <div className="flex flex-col gap-4">
      <div className="flex gap-4">
        <div className="flex-1">
          <label className="text-sm font-bold uppercase tracking-widest text-gray-500 mb-1 block">Token A Address</label>
          <AddressInput value={tokenA} onChange={setTokenA} />
        </div>
        <div className="flex-1">
          <label className="text-sm font-bold uppercase tracking-widest text-gray-500 mb-1 block">Token B Address</label>
          <AddressInput value={tokenB} onChange={setTokenB} />
        </div>
      </div>
      
      <div className="mt-2">
        <div className="flex justify-between items-center mb-1">
          <label className="text-sm font-bold uppercase tracking-widest text-gray-500 block">LP Tokens to Remove</label>
          {account && <span className="text-xs font-bold uppercase">Balance: {lpBalance ? parseFloat(formatUnits(lpBalance, 18)).toFixed(4) : '0.0000'}</span>}
        </div>
        <input type="number" min="0" className="neo-input w-full text-2xl font-bold bg-white mb-2" placeholder="0.0" value={liquidity} onChange={(e) => setLiquidity(e.target.value)} />
        <div className="flex gap-2 mb-4">
          {[25, 50, 75, 100].map(pct => (
            <button key={pct} onClick={() => handlePercentage(pct)} className="flex-1 bg-white border-2 border-black neo-shadow-sm text-xs font-bold py-1 hover:bg-gray-100">{pct}%</button>
          ))}
        </div>
      </div>

      {account && parsedLiquidity > 0n && estA > 0n && (
        <div className="flex flex-col gap-2 bg-white border-[3px] border-black p-3 mb-4">
          <div className="flex justify-between items-center">
            <span className="font-bold text-sm uppercase">Est. Token A</span>
            <span className="font-bold text-sm">{parseFloat(formatUnits(estA, 18)).toFixed(6)}</span>
          </div>
          <div className="flex justify-between items-center">
            <span className="font-bold text-sm uppercase">Est. Token B</span>
            <span className="font-bold text-sm">{parseFloat(formatUnits(estB, 18)).toFixed(6)}</span>
          </div>
        </div>
      )}

      {!account ? (
        <Button fullWidth disabled variant="secondary">Connect Wallet</Button>
      ) : parsedLiquidity === 0n ? (
        <Button fullWidth disabled variant="secondary">Enter amount</Button>
      ) : !pairAddress || pairAddress === '0x0000000000000000000000000000000000000000' ? (
        <Button fullWidth disabled variant="secondary">Pair not found</Button>
      ) : lpBalance !== undefined && parsedLiquidity > lpBalance ? (
        <Button fullWidth disabled variant="secondary">Insufficient LP Balance</Button>
      ) : needsApproveLP ? (
        <Button fullWidth onClick={() => approveLP(routerAddress, parsedLiquidity)} disabled={isApproveLPPending}>
          {isApproveLPPending ? 'Approving LP Token...' : 'Approve LP Token'}
        </Button>
      ) : (
        <Button fullWidth onClick={handleRemove} disabled={isRemovePending || !isAddress(tokenA) || !isAddress(tokenB)}>
          {isRemovePending ? 'Removing...' : 'Remove Liquidity'}
        </Button>
      )}
    </div>
  );
}

import { useState, useEffect } from 'react';
import { useAccount } from 'wagmi';
import { parseUnits, isAddress } from 'viem';
import type { Address } from 'viem';
import { TokenInput } from '../components/TokenInput';
import { Button } from '../components/Button';
import { Card } from '../components/Card';
import { useDexRouterAddress, useAddLiquidity, useRemoveLiquidity } from '../hooks/useDexRouter';
import { useERC20Allowance, useERC20Approve } from '../hooks/useERC20';
import { usePairAddress } from '../hooks/useDexFactory';

export function LiquidityView() {
  const [tab, setTab] = useState<'add' | 'remove'>('add');
  const { address: account } = useAccount();

  return (
    <div className="max-w-xl mx-auto w-full mt-10">
      <Card heavyShadow className="bg-[#E0F4FF]">
        <div className="flex justify-between items-center mb-6">
          <h2 className="text-3xl font-black uppercase tracking-tight">Liquidity</h2>
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

        {tab === 'add' ? <AddLiquidity account={account} /> : <RemoveLiquidity account={account} />}
      </Card>
    </div>
  );
}

function AddLiquidity({ account }: { account?: Address }) {
  const [tokenA, setTokenA] = useState('');
  const [tokenB, setTokenB] = useState('');
  const [amountA, setAmountA] = useState('');
  const [amountB, setAmountB] = useState('');
  
  const parsedAmountA = amountA && !isNaN(Number(amountA)) ? parseUnits(amountA, 18) : 0n;
  const parsedAmountB = amountB && !isNaN(Number(amountB)) ? parseUnits(amountB, 18) : 0n;

  const routerAddress = useDexRouterAddress();
  
  const { data: allowanceA, refetch: refetchA } = useERC20Allowance(
    isAddress(tokenA) ? (tokenA as Address) : undefined, account, routerAddress
  );
  const { data: allowanceB, refetch: refetchB } = useERC20Allowance(
    isAddress(tokenB) ? (tokenB as Address) : undefined, account, routerAddress
  );

  const { approve: approveA, isPending: isApproveAPending, isSuccess: isApproveASuccess } = useERC20Approve(isAddress(tokenA) ? (tokenA as Address) : undefined);
  const { approve: approveB, isPending: isApproveBPending, isSuccess: isApproveBSuccess } = useERC20Approve(isAddress(tokenB) ? (tokenB as Address) : undefined);
  
  useEffect(() => { if (isApproveASuccess) refetchA(); }, [isApproveASuccess, refetchA]);
  useEffect(() => { if (isApproveBSuccess) refetchB(); }, [isApproveBSuccess, refetchB]);

  const { addLiquidity, isPending: isAddPending } = useAddLiquidity();

  const handleAdd = () => {
    if (!account || !isAddress(tokenA) || !isAddress(tokenB)) return;
    const deadline = BigInt(Math.floor(Date.now() / 1000) + 20 * 60);
    // Setting min amounts to 0 for simplicity, in a real app this should be calculated with slippage
    addLiquidity(tokenA as Address, tokenB as Address, parsedAmountA, parsedAmountB, 0n, 0n, account, deadline);
  };

  const needsApproveA = allowanceA !== undefined && allowanceA < parsedAmountA;
  const needsApproveB = allowanceB !== undefined && allowanceB < parsedAmountB;

  return (
    <div className="flex flex-col gap-4">
      <TokenInput label="Token A" amount={amountA} onAmountChange={setAmountA} address={tokenA} onAddressChange={setTokenA} />
      <div className="text-center font-black text-2xl">+</div>
      <TokenInput label="Token B" amount={amountB} onAmountChange={setAmountB} address={tokenB} onAddressChange={setTokenB} />

      {!account ? (
        <Button fullWidth disabled variant="secondary">Connect Wallet</Button>
      ) : parsedAmountA === 0n || parsedAmountB === 0n ? (
        <Button fullWidth disabled variant="secondary">Enter amounts</Button>
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

function RemoveLiquidity({ account }: { account?: Address }) {
  const [tokenA, setTokenA] = useState('');
  const [tokenB, setTokenB] = useState('');
  const [liquidity, setLiquidity] = useState('');

  const parsedLiquidity = liquidity && !isNaN(Number(liquidity)) ? parseUnits(liquidity, 18) : 0n;
  const routerAddress = useDexRouterAddress();

  const { data: pairAddress } = usePairAddress(
    isAddress(tokenA) ? (tokenA as Address) : undefined,
    isAddress(tokenB) ? (tokenB as Address) : undefined
  );

  const { data: allowanceLP, refetch: refetchLP } = useERC20Allowance(
    pairAddress as Address | undefined, account, routerAddress
  );

  const { approve: approveLP, isPending: isApproveLPPending, isSuccess: isApproveLPSuccess } = useERC20Approve(pairAddress as Address | undefined);
  
  useEffect(() => { if (isApproveLPSuccess) refetchLP(); }, [isApproveLPSuccess, refetchLP]);

  const { removeLiquidity, isPending: isRemovePending } = useRemoveLiquidity();

  const handleRemove = () => {
    if (!account || !isAddress(tokenA) || !isAddress(tokenB)) return;
    const deadline = BigInt(Math.floor(Date.now() / 1000) + 20 * 60);
    removeLiquidity(tokenA as Address, tokenB as Address, parsedLiquidity, 0n, 0n, account, deadline);
  };

  const needsApproveLP = allowanceLP !== undefined && allowanceLP < parsedLiquidity;

  return (
    <div className="flex flex-col gap-4">
      <div className="flex gap-4">
        <div className="flex-1">
          <label className="text-sm font-bold uppercase tracking-widest text-gray-500 mb-1 block">Token A Address</label>
          <input type="text" className="neo-input w-full bg-white" placeholder="0x..." value={tokenA} onChange={(e) => setTokenA(e.target.value)} />
        </div>
        <div className="flex-1">
          <label className="text-sm font-bold uppercase tracking-widest text-gray-500 mb-1 block">Token B Address</label>
          <input type="text" className="neo-input w-full bg-white" placeholder="0x..." value={tokenB} onChange={(e) => setTokenB(e.target.value)} />
        </div>
      </div>
      
      <div className="mt-2">
        <label className="text-sm font-bold uppercase tracking-widest text-gray-500 mb-1 block">LP Tokens to Remove</label>
        <input type="number" min="0" className="neo-input w-full text-2xl font-bold bg-white" placeholder="0.0" value={liquidity} onChange={(e) => setLiquidity(e.target.value)} />
      </div>

      {!account ? (
        <Button fullWidth disabled variant="secondary">Connect Wallet</Button>
      ) : parsedLiquidity === 0n ? (
        <Button fullWidth disabled variant="secondary">Enter amount</Button>
      ) : !pairAddress || pairAddress === '0x0000000000000000000000000000000000000000' ? (
        <Button fullWidth disabled variant="secondary">Pair not found</Button>
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

import { useAccount, useChainId, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { parseUnits } from 'viem';
import { toast } from 'react-hot-toast';
import { Card } from '../components/Card';
import { Button } from '../components/Button';
import { TEST_TOKENS } from '../constants/constants';
import { MOCK_ERC20_ABI } from '../constants/abi';

export function FaucetView() {
  const { address: account } = useAccount();
  const chainId = useChainId();
  
  const { writeContractAsync, data: hash, isPending: isWritePending } = useWriteContract();
  const { isLoading: isWaiting } = useWaitForTransactionReceipt({ hash });
  const isPending = isWritePending || isWaiting;

  const tokens = TEST_TOKENS[chainId as keyof typeof TEST_TOKENS] || [];

  const handleMint = async (tokenAddress: string, symbol: string) => {
    if (!account) return;
    try {
      await writeContractAsync({
        address: tokenAddress as `0x${string}`,
        abi: MOCK_ERC20_ABI as any,
        functionName: 'mint',
        args: [account, parseUnits('1000', 18)] as const,
      } as any);
      toast.success(`Minted 1000 ${symbol}!`);
    } catch (err: any) {
      toast.error(err.shortMessage || err.message || `Failed to mint ${symbol}`);
    }
  };

  const handleCopy = (address: string) => {
    navigator.clipboard.writeText(address);
    toast.success("Address copied!");
  };

  const handleMintEth = async () => {
    if (!account) return;
    try {
      const res = await fetch('http://127.0.0.1:8545', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          jsonrpc: '2.0',
          method: 'anvil_setBalance',
          params: [account, '0x3635c9adc5dea00000'], // 1000 ETH in hex
          id: 1,
        })
      });
      if (res.ok) {
        toast.success('Minted 1000 ETH! (Balance may take a moment to update)');
      } else {
        throw new Error('RPC failed');
      }
    } catch (err: any) {
      toast.error('Failed to mint ETH. Make sure Anvil is running.');
    }
  };

  return (
    <div className="max-w-xl mx-auto w-full mt-10">
      <Card heavyShadow className="bg-[#E0F4FF]">
        <h2 className="text-3xl font-black uppercase tracking-tight mb-2">Faucet</h2>
        <p className="text-sm font-bold text-gray-600 mb-6 uppercase tracking-wider">Mint test tokens for the DEX</p>
        
        <div className="flex flex-col gap-4">
          {chainId === 31337 && (
            <div className="flex justify-between items-center bg-white border-[3px] border-black p-4 neo-shadow-sm">
              <div>
                <div className="font-black text-xl">ETH</div>
                <div className="text-xs font-bold text-gray-500 uppercase">NATIVE ETHER (LOCAL ONLY)</div>
              </div>
              <Button 
                onClick={handleMintEth}
                disabled={!account}
              >
                Mint 1000
              </Button>
            </div>
          )}

          {tokens.map((token, idx) => (
            <div key={idx} className="flex justify-between items-center bg-white border-[3px] border-black p-4 neo-shadow-sm">
              <div>
                <div className="font-black text-xl">{token.symbol}</div>
                <div className="text-xs font-bold text-gray-500 uppercase">{token.name}</div>
                <button 
                  onClick={() => handleCopy(token.address)}
                  className="mt-1 flex gap-1 items-center text-xs font-mono font-bold bg-gray-100 px-2 py-1 border-2 border-black hover:bg-[#CCFF00] transition-colors"
                >
                  {token.address.slice(0, 6)}...{token.address.slice(-4)}
                  <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <rect width="14" height="14" x="8" y="8" rx="2" ry="2"/>
                    <path d="M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2"/>
                  </svg>
                </button>
              </div>
              <Button 
                onClick={() => handleMint(token.address, token.symbol)}
                disabled={!account || isPending}
              >
                Mint 1000
              </Button>
            </div>
          ))}
          
          {tokens.length === 0 && (
            <div className="p-4 bg-white border-[3px] border-black text-center font-bold">
              No test tokens configured for this network ({chainId}).
            </div>
          )}
        </div>
      </Card>
    </div>
  );
}

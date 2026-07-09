import { useAccount, useConnect, useDisconnect, useBalance } from 'wagmi';
import { formatUnits } from 'viem';

export function Navbar() {
  const { address, isConnected } = useAccount();
  const { connectors, connect } = useConnect();
  const { disconnect } = useDisconnect();

  const { data: balance } = useBalance({ address });

  // Format address
  const shortAddress = address
    ? `${address.slice(0, 6)}...${address.slice(-4)}`
    : '';

  return (
    <nav className="flex justify-between items-center py-6 px-8 border-b-[3px] border-black bg-white neo-shadow mb-12">
      <div className="flex items-center gap-2">
        <div className="w-8 h-8 rounded-full bg-[#FF90E8] border-[3px] border-black"></div>
        <h1 className="text-2xl tracking-tighter m-0">UNIDEX</h1>
      </div>

      <div className="flex gap-4">
        {isConnected ? (
          <div className="flex gap-4 items-center">
            <div className="neo-box px-4 py-2 font-mono text-sm hidden md:block">
              {balance ? `${parseFloat(formatUnits(balance.value, balance.decimals)).toFixed(4)} ${balance.symbol}` : '0.0000 ETH'}
            </div>
            <button
              onClick={() => disconnect()}
              className="neo-box px-4 py-2 font-bold cursor-pointer hover:bg-neo-secondary hover:text-white transition-colors group"
            >
              <span className="block group-hover:hidden">{shortAddress}</span>
              <span className="hidden group-hover:block">Disconnect</span>
            </button>
          </div>
        ) : (
          <button
            onClick={() => connect({ connector: connectors[0] })}
            className="neo-button neo-button-primary px-6 py-2"
          >
            Connect Wallet
          </button>
        )}
      </div>
    </nav>
  );
}

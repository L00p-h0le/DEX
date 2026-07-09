import { useState } from 'react';
import { Layout } from './components/Layout';
import { SwapView } from './views/SwapView';
import { LiquidityView } from './views/LiquidityView';

function App() {
  const [activeTab, setActiveTab] = useState<'swap' | 'liquidity'>('swap');

  return (
    <Layout>
      <div className="flex justify-center mb-8 gap-4">
        <button
          className={`neo-box px-6 py-2 font-black uppercase text-xl transition-all ${
            activeTab === 'swap' 
              ? 'bg-[#FF90E8] neo-shadow-heavy translate-y-[-4px] translate-x-[-4px]' 
              : 'bg-white hover:bg-gray-50'
          }`}
          onClick={() => setActiveTab('swap')}
        >
          Swap
        </button>
        <button
          className={`neo-box px-6 py-2 font-black uppercase text-xl transition-all ${
            activeTab === 'liquidity' 
              ? 'bg-[#FF90E8] neo-shadow-heavy translate-y-[-4px] translate-x-[-4px]' 
              : 'bg-white hover:bg-gray-50'
          }`}
          onClick={() => setActiveTab('liquidity')}
        >
          Liquidity
        </button>
      </div>

      {activeTab === 'swap' ? <SwapView /> : <LiquidityView />}
    </Layout>
  );
}

export default App;

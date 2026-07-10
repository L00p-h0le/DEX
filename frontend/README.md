# UNIDEX Frontend

The frontend user interface for **UNIDEX**, a Decentralized Exchange (DEX). It provides a seamless, modern, neo-brutalist web interface for users to interact with the underlying DEX smart contracts on local testnets (Anvil) and public testnets (Sepolia).

## Overview

UNIDEX Frontend is a highly optimized React-based application that allows users to connect their Web3 wallets and perform decentralized finance operations. It integrates directly with the `DexRouter`, `DexFactory`, and `DexPair` contracts deployed on the blockchain.

### Key Features
- **Token Swapping**: Swap between any two ERC20 tokens (e.g., USDC, WBTC) with user-defined slippage tolerance and transaction deadlines. Calculates estimated outputs dynamically.
- **Liquidity Provision**: Add liquidity to existing pools or create new trading pairs. Automatically calculates pool shares and required token ratios based on current reserves.
- **Liquidity Removal**: Withdraw liquidity from pools by burning LP tokens to receive the underlying assets back, complete with real-time reserve estimations.
- **Testnet Faucet**: Built-in functionality for minting test ETH and mock ERC20 tokens directly from the UI for testing purposes.
- **Wallet Integration**: Connect and disconnect various Ethereum wallets seamlessly via Wagmi and Viem.
- **Neo-Brutalist Design**: A bold, high-contrast user interface with distinctive borders, solid colors (featuring the signature UNIDEX neon pink and yellow), and a clean grid background.

## Tech Stack

- **Framework**: React 19 + Vite for rapid development and HMR.
- **Styling**: Tailwind CSS v4 for utility-first styling and custom thematic design.
- **Web3 Integration**: 
  - [Wagmi v2](https://wagmi.sh/): React Hooks for Ethereum (connecting wallets, reading/writing contracts).
  - [Viem](https://viem.sh/): A lightweight, fast TypeScript interface for Ethereum (used for ABIs, addresses, formatting, and low-level interactions).
- **Language**: TypeScript (Strict mode enabled) for type-safe smart contract interactions.
- **State Management & Notifications**: React Query (under the hood of Wagmi) and `react-hot-toast` for transaction feedback.

## Project Structure

```text
frontend/
├── src/
│   ├── components/       # Reusable UI components
│   │   ├── AddressInput.tsx  # Input field for token addresses
│   │   ├── Navbar.tsx        # Top navigation & Wallet connect button
│   │   └── TokenInput.tsx    # Token amount input with balance fetching
│   ├── constants/        # Contract addresses, ABIs, and configuration
│   │   ├── abi.ts            # Exported ABIs for Factory, Router, Pair, ERC20
│   │   └── constants.ts      # Multi-chain addresses (Anvil 31337, Sepolia 11155111)
│   ├── hooks/            # Custom Wagmi hooks for smart contract interactions
│   │   ├── useDexFactory.ts
│   │   ├── useDexRouter.ts
│   │   └── useERC20.ts
│   ├── utils/            # Helper functions
│   │   └── format.ts         # Formatting balances, truncating hashes/addresses
│   ├── views/            # Main application views
│   │   ├── FaucetView.tsx    # Minting test tokens
│   │   ├── LiquidityView.tsx # Add/Remove Liquidity logic
│   │   └── SwapView.tsx      # Token swapping logic
│   ├── App.tsx           # Application root and routing layout
│   ├── main.tsx          # React entry point and providers setup
│   ├── index.css         # Global styles and Tailwind imports
│   └── wagmi.ts          # Wagmi client configuration (chains & transports)
├── package.json
└── vite.config.ts
```

## Smart Contract Integration Architecture

The frontend uses a custom hook architecture built on top of Wagmi to interact with the blockchain cleanly:

- **`useDexRouter.ts`**: Handles routing operations like `swapExactTokensForTokens`, `addLiquidity`, and `removeLiquidity`. It also fetches expected output amounts (`getAmountsOut`) for quoting prices to the user in real-time as they type.
- **`useDexFactory.ts`**: Interacts with the Factory contract to fetch pair addresses (`getPair`) dynamically when users select two tokens.
- **`useERC20.ts`**: Provides token approvals (`approve`) and balance fetching (`balanceOf`) for any ERC20 token, including the generated LP tokens.

### Cross-Chain Compatibility
The frontend is built to seamlessly support multiple chains. Configuration is stored in `constants.ts` keyed by Chain ID (e.g., `31337` for Anvil, `11155111` for Sepolia). Wagmi automatically detects the connected user's network and utilizes the corresponding contract addresses.

## Getting Started

### Prerequisites
- [Node.js](https://nodejs.org/) (v18 or higher recommended)
- A package manager (`npm`, `yarn`, or `pnpm`)
- A Web3 wallet extension installed in your browser (e.g., MetaMask, Rabby)

### Installation & Setup

1. **Install dependencies**:
   ```bash
   npm install
   ```

2. **Configure Contract Addresses**:
   Open `src/constants/constants.ts` and ensure the contract addresses match your deployed contracts. If you redeploy the smart contracts locally, update the `31337` chain config. 

3. **Start the development server**:
   ```bash
   npm run dev
   ```

4. Open your browser and navigate to `http://localhost:5173`.

### Available Scripts

- `npm run dev`: Starts the Vite development server.
- `npm run build`: Compiles TypeScript and builds the application for production.
- `npm run lint`: Runs ESLint to check for code quality issues.
- `npm run preview`: Locally previews the production build.

## Design Aesthetic (Neo-Brutalist)

The application utilizes a **Neo-Brutalist** design language to create an engaging, modern DeFi experience. This is achieved using:
- **High Contrast**: Bright yellow (`#e2ff3b`), neon pink (`#ff3bff`), and crisp whites against solid blacks.
- **Harsh Borders**: Thick black borders on all interactive elements (`border-2 border-black` / `border-4`).
- **Offset Shadows**: Flat, solid shadows offset to the bottom right (`shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]`) that compress on click for tactile feedback.
- **Mathematical Grid**: A clean grid background layout in `index.css` to align with the decentralized, mathematical nature of AMMs.
- **Typography**: `Lexend` (for headings/accents) and `Inter` (for readable body text).

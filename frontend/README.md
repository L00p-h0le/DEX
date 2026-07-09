# DexProtocol Frontend

The frontend user interface for the Decentralized Exchange (DEX). It provides a seamless, modern, neo-brutalist web interface for users to interact with the underlying DEX smart contracts.

## Overview

The DexProtocol Frontend is a React-based application that allows users to connect their Web3 wallets and perform decentralized finance operations. It integrates directly with the `DexRouter`, `DexFactory`, and `DexPair` contracts deployed on the blockchain.

### Key Features
- **Token Swapping**: Swap between any two ERC20 tokens with a specified slippage tolerance and transaction deadline.
- **Liquidity Provision**: Add liquidity to existing pools or create new trading pairs by depositing token pairs.
- **Liquidity Removal**: Withdraw your liquidity from pools, burning LP tokens to receive the underlying assets.
- **Wallet Integration**: Connect and disconnect various Ethereum wallets seamlessly.
- **Neo-Brutalist Design**: A bold, high-contrast user interface with distinctive borders, solid colors, and a clean grid background.

## Tech Stack

- **Framework**: React 19 + Vite
- **Styling**: Tailwind CSS v4
- **Web3 Integration**: 
  - [Wagmi v2](https://wagmi.sh/): React Hooks for Ethereum (connecting wallets, reading/writing contracts).
  - [Viem](https://viem.sh/): A lightweight, fast TypeScript interface for Ethereum (used for ABIs, addresses, and low-level interactions).
- **Language**: TypeScript (Strict mode enabled)
- **State Management**: React Query (under the hood of Wagmi)

## Project Structure

```text
frontend/
├── src/
│   ├── components/       # Reusable UI components (Button, Card, Navbar, TokenInput)
│   ├── constants/        # Contract addresses, ABIs, and configuration
│   ├── hooks/            # Custom Wagmi hooks for smart contract interactions
│   │   ├── useDexFactory.ts
│   │   ├── useDexRouter.ts
│   │   └── useERC20.ts
│   ├── views/            # Main application views (Swap, Liquidity)
│   ├── App.tsx           # Application root and routing layout
│   ├── main.tsx          # React entry point and providers setup
│   ├── index.css         # Global styles and Tailwind imports
│   └── wagmi.ts          # Wagmi client configuration
├── package.json
└── vite.config.ts
```

## Smart Contract Integration

The frontend uses custom React hooks built on top of Wagmi to interact with the blockchain:

- **`useDexRouter.ts`**: Handles routing operations like `swapExactTokensForTokens`, `addLiquidity`, and `removeLiquidity`. It also fetches expected output amounts (`getAmountsOut`) for quoting prices to the user.
- **`useDexFactory.ts`**: Interacts with the Factory contract to fetch pair addresses (`getPair`).
- **`useERC20.ts`**: Provides token approvals (`approve`) and balance fetching (`balanceOf`) for any ERC20 token, including LP tokens.

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
   Open `src/constants/constants.ts` and ensure the contract addresses match your deployed contracts on the target network. Currently configured for the local Anvil devnet (Chain ID 31337).

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

## Design Aesthetic

The application utilizes a **Neo-Brutalist** design language. This is achieved using:
- High contrast colors (e.g., bright yellow `#e2ff3b`, neon pink `#ff3bff`).
- Hard, thick black borders on interactive elements (`border-2 border-black`).
- Flat shadows offset to the bottom right (`shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]`).
- A clean, mathematical grid background layout.
- The `Lexend` and `Inter` font families for sharp, readable typography.

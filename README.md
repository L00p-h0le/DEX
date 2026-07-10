# UNIDEX

A decentralized exchange built from scratch in modern Solidity (0.8.20+), implementing Uniswap V2's constant product AMM architecture with deliberate improvements guided by the RareSkills Uniswap V2 Build Checklist. It features a fully integrated Neo-Brutalist React frontend and is actively deployed on the **Sepolia Testnet**.

## What is this?

UNIDEX is a fully functional DEX supporting:

- Permissionless token pair creation
- Liquidity provision and withdrawal
- Token swaps with slippage and deadline protection
- Multi-hop routing across multiple pairs
- A TWAP price oracle resistant to flash loan manipulation
- Flash swap support
- A neo-brutalist web interface for interacting with the protocol

This is not a line-for-line clone of Uniswap V2. It uses V2's battle-tested economic model and security architecture as the reference design, then implements it with modern Solidity patterns, audited library dependencies, and improved gas efficiency. Every deviation from V2 is intentional and documented.

## Repository Structure

```text
DEX/
├── contracts/          # All Solidity — core, periphery, tests, scripts
│   ├── src/
│   │   ├── Core/       # DexFactory, DexPair
│   │   └── Periphery/  # DexRouter, DexOracle, DexLibrary
│   └── test/           # 65 tests — unit, fuzz, invariant
└── frontend/           # React + Wagmi swap UI
```

→ [Full technical documentation and architecture breakdown](./contracts/README.md)
→ [Frontend documentation](./frontend/README.md)

## Quick Start

### Contracts

```bash
git clone https://github.com/L00p-h0le/DEX
cd DEX/contracts

forge install
forge test -vv
```

### Frontend

```bash
cd DEX/frontend

npm install
npm run dev
```

## Test Results

**65 tests, 0 failures**
- Ran 11 tests for DexFactory      — 11 passed
- Ran 17 tests for DexPair         — 17 passed (includes 2 fuzz tests)
- Ran 17 tests for DexLibrary      — 17 passed
- Ran 9  tests for DexOracle       — 9  passed
- Ran 10 tests for DexRouter       — 10 passed
- Ran 1  invariant test            — 1  passed (128,000 calls, 0 reverts)

The invariant test verifies that `reserve0 * reserve1` never decreases across any randomized sequence of mint, burn, and swap operations — the core safety property of a constant product AMM.

## Key Improvements Over Uniswap V2

Built following the RareSkills checklist for modernizing V2:

- **Solidity 0.8.20+** — native overflow protection, cleaner syntax
- **Solady ERC20 for the LP token** — significant gas savings over V2's custom ERC20
- **OpenZeppelin ReentrancyGuard** — replaces V2's custom `uint private unlocked` flag
- **OpenZeppelin SafeERC20** — replaces V2's hand-rolled assembly `_safeTransfer`
- **Native CREATE2 syntax** — `new DexPair{salt: salt}()` replaces assembly-based deployment in Factory
- **Custom errors** — replaces all require strings for cheaper deployment and clearer reverts
- **immutable feeToSetter** — protocol fee admin locked at deploy time, not transferable
- **Explicit uint256 casting in K-invariant check** — prevents silent overflow on large balances
- **unchecked price accumulator** — intentional overflow preserved correctly for TWAP math

The economic model — constant product formula, 0.3% fee, LP token share math, protocol fee mechanism, TWAP accumulator design — is identical to Uniswap V2.

## Tech Stack

### Contracts:

- **Foundry** — build, test, deploy
- **Solady** — gas-optimized ERC20 and math libraries
- **OpenZeppelin Contracts** — ReentrancyGuard, SafeERC20

### Frontend:

- **React + Vite** — UI framework and bundler
- **Tailwind CSS v4** — Utility-first styling with neo-brutalist aesthetic
- **Wagmi v2 & Viem** — Ethereum React hooks for wallet connection and contract interactions

## Build Status

| Component | Status |
| :--- | :--- |
| DexFactory | ✅ Complete |
| DexPair (mint/burn/swap/TWAP) | ✅ Complete |
| DexRouter | ✅ Complete |
| DexOracle | ✅ Complete |
| DexLibrary | ✅ Complete |
| Unit + Fuzz + Invariant Tests | ✅ 65/65 passing |
| NatSpec Documentation | ✅ Complete |
| Frontend — Swap UI | ✅ Complete |
| Frontend — Liquidity UI | ✅ Complete |
| Testnet Deployment | ✅ Complete (Sepolia) |

## References

- [Uniswap V2 Whitepaper](https://uniswap.org/whitepaper.pdf)
- [RareSkills Uniswap V2 Build Checklist](https://rareskills.io/post/build-your-own-uniswap)
- [Uniswap V2 Core Source](https://github.com/Uniswap/v2-core)
- [Uniswap V2 Periphery Source](https://github.com/Uniswap/v2-periphery)

Built with Foundry.

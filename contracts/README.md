# DexProtocol — A Uniswap V2-Style DEX

A fully functional decentralized exchange built from scratch in modern Solidity (0.8.20+), following Uniswap V2's battle-tested constant product AMM architecture with significant implementation improvements.
Built as part of a focused DeFi engineering portfolio targeting smart contract security roles.

## Architecture

The protocol follows Uniswap V2's core/periphery separation — the most security-critical logic lives in minimal core contracts, while user-facing safety features live in periphery contracts.

```text
contracts/
├── src/
│   ├── Core/
│   │   ├── DexFactory.sol          # Deploys and tracks trading pairs via CREATE2
│   │   ├── DexPair.sol             # AMM logic, LP tokens, TWAP accumulators
│   │   └── interfaces/
│   │       ├── IDexFactory.sol
│   │       └── IDexPair.sol
│   └── Periphery/
│       ├── DexRouter.sol           # User-facing entry point — slippage, deadlines, multi-hop
│       ├── DexOracle.sol           # TWAP oracle consumer
│       └── libraries/
│           ├── DexLibrary.sol      # Pure AMM math — getAmountOut, getAmountIn, pairFor
│           ├── Math.sol            # sqrt wrapper (Solady) + min helper
│           ├── UQ112x112.sol       # Fixed-point math for price accumulators
│           └── OracleLibrary.sol   # Current cumulative price helper
├── test/
│   ├── DexFactory.t.sol
│   ├── DexPair.t.sol
│   ├── DexLibrary.t.sol
│   ├── DexOracle.t.sol
│   ├── DexRouter.t.sol
│   └── invariants/
│       ├── DexPairInvariant.t.sol
│       └── Handler.sol
└── script/
    └── Deploy.s.sol
```

### Contract Relationships

```text
User
 └── DexRouter (periphery — slippage, deadline, multi-hop routing)
      ├── DexFactory (deploys pairs via CREATE2, manages protocol fee admin)
      └── DexPair (holds reserves, issues LP tokens, executes swaps)
           └── DexOracle (reads price accumulators for TWAP)
```

Every token pair gets its own `DexPair` contract deployed by `DexFactory` using `CREATE2`. The deterministic address means `DexRouter` and `DexLibrary` can compute pair addresses offline without external calls — just from `(tokenA, tokenB, factory)`.

## Core Contracts

### DexFactory

Permissionlessly deploys trading pairs. Key design decisions:
- Uses native Solidity `new DexPair{salt: salt}()` syntax instead of assembly-based `CREATE2` — available since Solidity 0.8.x, cleaner and auditable
- `feeToSetter` is immutable — the protocol fee admin is locked at deploy time, cannot be transferred
- Custom errors throughout instead of require strings — cheaper deployment and clearer reverts
- Protocol fee starts disabled (`feeTo = address(0)`) — LPs keep 100% of the 0.3% swap fee until governance enables it

### DexPair

The core AMM contract. Each pair is also an ERC20 (the LP token). Key internals:
- Constant Product AMM — enforces `x * y = k` after every swap. Implemented via a K-invariant check on fee-adjusted balances:
  `balance0Adjusted * balance1Adjusted >= reserve0 * reserve1 * 1000²`
- `_update` — called after every mint/burn/swap to sync reserves and advance the TWAP accumulators. The accumulator additions use `unchecked` intentionally — overflow is load-bearing for the TWAP math.
- `mint` — first deposit receives `sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY` LP tokens. `MINIMUM_LIQUIDITY` (1000 wei) is permanently burned to `address(0)` to prevent the totalSupply from ever reaching zero, which would break the LP share math.
- `burn` — redeems LP tokens for a proportional share of reserves. Always rounds in the pool's favor.
- `swap` — uses the optimistic transfer pattern: tokens go out first, callback fires (enabling flash swaps), then the K-invariant check enforces repayment. `amountIn` is computed from balance deltas rather than trusted parameters — this defends against fee-on-transfer and rebasing tokens.
- `mintFee` — the protocol fee mechanism. Instead of taking a cut on every swap (expensive), it snapshots `sqrt(k)` as `kLast` after mint/burn events. On the next mint/burn, it compares current `sqrt(reserve0 * reserve1)` against `kLast`. If `k` grew (meaning swap fees accumulated), it mints new LP tokens to `feeTo` as the protocol's 1/6th cut:
  `liquidity = totalSupply * (rootK - rootKLast) / (rootK * 5 + rootKLast)`

### DexOracle (TWAP)

Spot price (`reserve1/reserve0`) is trivially manipulable via flash loans in a single transaction. The TWAP oracle solves this by integrating price over time.
On every `_update` call, `DexPair` adds `currentPrice * timeElapsed` to running cumulative sums (`price0CumulativeLast`, `price1CumulativeLast`). `DexOracle` snapshots these accumulators at two points in time and divides the difference by elapsed time to get a time-weighted average price. Sustaining a price manipulation across multiple blocks requires holding a large position for extended time — economically infeasible.

### DexRouter

User-facing entry point. Never holds funds. Responsibilities:
- `addLiquidity` — calculates optimal deposit amounts to match current pool ratio, creates pair if it doesn't exist
- `removeLiquidity` — burns LP tokens, returns proportional reserves
- `swapExactTokensForTokens` / `swapTokensForExactTokens` — routes swaps with slippage and deadline protection
- Multi-hop swaps — chains swaps across multiple pairs in a single transaction via `path[]`

### DexLibrary

Pure/view math functions used by the Router. The critical `pairFor` function computes pair addresses deterministically via `CREATE2` without any external calls — enabling gas-efficient routing.

## Key Design Decisions vs Uniswap V2

| Area | Uniswap V2 | This Implementation |
| --- | --- | --- |
| Solidity version | 0.5.x | 0.8.20+ |
| Safe transfer | Hand-rolled assembly `_safeTransfer` | OpenZeppelin `SafeERC20` |
| Reentrancy guard | Custom `uint private unlocked` flag | OpenZeppelin `ReentrancyGuard` |
| Factory deployment | Assembly-based `CREATE2` | Native `new Contract{salt: salt}()` |
| Error handling | `require` with strings | Custom errors |
| `feeToSetter` | Transferable | immutable — locked at deploy |
| LP token | Custom ERC20 | Solady ERC20 (gas optimized) |
| sqrt | Hand-rolled Babylonian | Solady `FixedPointMathLib.sqrt` |
| Flash swap callback | `uniswapV2Call` | `dexV2Call` via `IDexCallee` |
| K-invariant math | `uint112` intermediates | Explicit `uint256` casting |

The economic model and security architecture are identical to Uniswap V2. The improvements are implementation-level — safer, cheaper, more readable.

## Testing

```bash
cd contracts
forge test -vv
```

65 tests, 0 failures

| Suite | Tests | Coverage |
| --- | --- | --- |
| DexFactory | 11 | 100% lines, 100% branches |
| DexPair | 17 (incl. 2 fuzz) | — |
| DexLibrary | 17 | — |
| DexOracle | 9 | — |
| DexRouter | 10 | — |
| Invariant (K never decreases) | 1 (128,000 calls, 0 reverts) | — |

Invariant tested: `reserve0 * reserve1` after any sequence of mint/burn/swap operations never decreases. Verified across 128,000 randomized calls with zero reverts.
Fuzz tested:
- `mint` — arbitrary deposit amounts maintain correct LP share math
- `swap` — arbitrary input amounts never violate the K-invariant

## Installation & Setup

```bash
git clone https://github.com/L00p-h0le/DEX
cd DEX/contracts

# Install dependencies
forge install

# Run tests
forge test -vv

# Run invariant tests
forge test --match-path test/invariants/* -vv

# Check coverage
forge coverage
```

Dependencies:
- Foundry — testing and deployment
- Solady — gas-optimized ERC20 and math
- OpenZeppelin Contracts — ReentrancyGuard, SafeERC20

## Security Considerations

What this implementation defends against:
- Reentrancy — OpenZeppelin `nonReentrant` on all state-changing pair functions
- Fee-on-transfer tokens — `amountIn` computed from balance deltas, not trusted parameters
- Flash loan price manipulation — TWAP oracle requires sustained manipulation across multiple blocks
- LP token supply reaching zero — `MINIMUM_LIQUIDITY` permanently burned at first deposit
- Unsafe ERC20 transfers — `SafeERC20` handles tokens that return no bool or return false
- Integer overflow in K-invariant check — explicit `uint256` casting before multiplication

Known limitations:
- No ETH/WETH support — token-to-token pairs only
- No permit (EIP-2612) support on LP tokens
- TWAP oracle susceptible to manipulation on low-liquidity pairs with infrequent updates
- Init code hash in `DexLibrary.pairFor` must be updated if `DexPair` bytecode changes
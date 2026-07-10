export const CONTRACTS = {
    31337: {
        name: 'Anvil Local',
        factory: '0x9A676e781A523b5d0C0e43731313A708CB607508',
        router: '0x0B306BF915C4d645ff596e518fAf3F9669b97016',
    },
    11155111: {  // Sepolia
        factory: "0x3A29Ca36F40E020A8D83bAe456C4C245f34e1268",
        router: "0x98AA8097af68d3364C17a32fd999458f30ED7d8D",
    },
} as const;

export const TEST_TOKENS = {
    31337: [
        { name: "USD Coin", symbol: "USDC", address: "0x610178dA211FEF7D417bC0e6FeD39F05609AD788" },
        { name: "Wrapped Bitcoin", symbol: "WBTC", address: "0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e" }
    ],
    11155111: [
        { name: "USD Coin", symbol: "USDC", address: "0x978a11892ea33c8AdAA23C80ADE56a444fbbd2Ea" },
        { name: "Wrapped Bitcoin", symbol: "WBTC", address: "0xAd8267fc865D766163b1B238618ecb98bc915EB0" }
    ]
};

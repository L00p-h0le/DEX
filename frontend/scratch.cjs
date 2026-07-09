const fs = require('fs');
const content = fs.readFileSync('src/constants/abi.ts', 'utf8').split('\n');
const factory = JSON.parse(content[0]).abi;
const router = JSON.parse(content[2]).abi;
const out = `export const FACTORY_ABI = ${JSON.stringify(factory, null, 2)} as const;\n\nexport const ROUTER_ABI = ${JSON.stringify(router, null, 2)} as const;\n`;
fs.writeFileSync('src/constants/abi.ts', out);

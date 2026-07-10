import { formatUnits } from 'viem';

export function formatDisplayBalance(balance: bigint | undefined, decimals: number = 18): string {
  if (balance === undefined) return '0.0000';
  if (balance === 0n) return '0.0000';
  
  const formatted = formatUnits(balance, decimals);
  const parts = formatted.split('.');
  
  const integerPart = parts[0];
  let decimalPart = parts[1] || '0000';
  
  // If the integer part is massive, we can use suffixes to keep it short
  if (integerPart.length > 15) {
    return '>999T';
  } else if (integerPart.length > 12) {
    return (Number(integerPart) / 1e12).toFixed(2) + 'T';
  } else if (integerPart.length > 9) {
    return (Number(integerPart) / 1e9).toFixed(2) + 'B';
  } else if (integerPart.length > 6) {
    return (Number(integerPart) / 1e6).toFixed(2) + 'M';
  }
  
  // Pad decimal part to 4 digits if it's too short
  decimalPart = decimalPart.padEnd(4, '0');
  
  // Truncate decimal part to 4 digits
  decimalPart = decimalPart.slice(0, 4);
  
  return `${integerPart}.${decimalPart}`;
}

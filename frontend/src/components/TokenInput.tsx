import { Card } from './Card';
import { AddressInput } from './AddressInput';

interface TokenInputProps {
  label: string;
  amount: string;
  address: string;
  onAmountChange: (val: string) => void;
  onAddressChange: (val: string) => void;
  disabled?: boolean;
  balance?: string;
}

export function TokenInput({
  label,
  amount,
  address,
  onAmountChange,
  onAddressChange,
  disabled = false,
  balance,
}: TokenInputProps) {
  return (
    <Card className="flex flex-col gap-2 mb-4 bg-[#f3f3f3]">
      <div className="flex justify-between items-center">
        <label className="text-sm font-bold uppercase tracking-widest text-gray-500">
          {label}
        </label>
        {balance && (
          <span className="text-xs font-bold text-gray-500 uppercase">
            Bal: {balance}
          </span>
        )}
      </div>
      <div className="flex gap-4 items-center">
        <input
          type="number"
          min="0"
          placeholder="0.0"
          value={amount}
          onChange={(e) => onAmountChange(e.target.value)}
          disabled={disabled}
          className="neo-input flex-1 text-2xl font-bold bg-white"
        />
        <div className="flex-1">
          <AddressInput
            value={address}
            onChange={onAddressChange}
            placeholder="Token Address (0x...)"
          />
        </div>
      </div>
    </Card>
  );
}

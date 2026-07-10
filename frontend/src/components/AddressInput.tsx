import { useState, useRef } from 'react';
import { isAddress } from 'viem';
import { toast } from 'react-hot-toast';

interface AddressInputProps {
  value: string;
  onChange: (val: string) => void;
  placeholder?: string;
  disabled?: boolean;
}

export function AddressInput({ value, onChange, placeholder = "0x...", disabled = false }: AddressInputProps) {
  const [isFocused, setIsFocused] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);

  const shortAddress = value && isAddress(value) ? `${value.slice(0, 6)}...${value.slice(-4)}` : value;

  const handleCopy = (e: React.MouseEvent) => {
    e.stopPropagation();
    navigator.clipboard.writeText(value);
    toast.success("Address copied!");
  };

  const handleClick = () => {
    if (disabled) return;
    setIsFocused(true);
    setTimeout(() => inputRef.current?.focus(), 0);
  };

  if (value && isAddress(value) && !isFocused) {
    return (
      <div 
        className={`neo-input w-full text-sm font-bold bg-white flex justify-between items-center ${disabled ? 'opacity-50 cursor-not-allowed' : 'cursor-text'}`}
        onClick={handleClick}
      >
        <span>{shortAddress}</span>
        <button onClick={handleCopy} className="hover:scale-110 active:scale-95 transition-transform" title="Copy Address">
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <rect width="14" height="14" x="8" y="8" rx="2" ry="2"/>
            <path d="M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2"/>
          </svg>
        </button>
      </div>
    );
  }

  return (
    <input
      ref={inputRef}
      type="text"
      placeholder={placeholder}
      value={value}
      onChange={(e) => onChange(e.target.value)}
      onFocus={() => setIsFocused(true)}
      onBlur={() => setIsFocused(false)}
      disabled={disabled}
      className={`neo-input w-full text-sm font-bold bg-white ${disabled ? 'opacity-50 cursor-not-allowed' : ''}`}
    />
  );
}

import React from 'react';

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'outline';
  fullWidth?: boolean;
}

export function Button({ 
  children, 
  variant = 'primary', 
  fullWidth = false, 
  className = '', 
  ...props 
}: ButtonProps) {
  const baseClass = 'neo-button';
  const widthClass = fullWidth ? 'w-full' : '';
  
  let variantClass = '';
  if (variant === 'primary') {
    variantClass = 'neo-button-primary';
  } else if (variant === 'secondary') {
    variantClass = 'neo-button-secondary';
  } else {
    variantClass = 'bg-white hover:bg-gray-50';
  }

  return (
    <button 
      className={`${baseClass} ${variantClass} ${widthClass} ${className} disabled:opacity-50 disabled:cursor-not-allowed`}
      {...props}
    >
      {children}
    </button>
  );
}

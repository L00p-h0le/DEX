import React from 'react';

interface CardProps {
  children: React.ReactNode;
  className?: string;
  heavyShadow?: boolean;
}

export function Card({ children, className = '', heavyShadow = false }: CardProps) {
  const shadowClass = heavyShadow ? 'neo-shadow-heavy' : 'neo-shadow';
  return (
    <div className={`neo-box ${shadowClass} p-6 ${className}`}>
      {children}
    </div>
  );
}

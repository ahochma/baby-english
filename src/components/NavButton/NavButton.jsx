import React from 'react';
import './NavButton.css';

export function NavButton({ direction, onClick, disabled }) {
  return (
    <button
      className={`nav-button nav-button--${direction} ${disabled ? 'nav-button--disabled' : ''}`}
      onClick={disabled ? undefined : onClick}
      aria-label={direction === 'prev' ? 'Previous word' : 'Next word'}
      aria-disabled={disabled}
    >
      {direction === 'prev' ? '◀' : '▶'}
    </button>
  );
}

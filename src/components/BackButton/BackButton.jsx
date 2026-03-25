import React from 'react';
import './BackButton.css';

export function BackButton({ onClick }) {
  return (
    <button className="back-button" onClick={onClick} aria-label="Back to home">
      🏠
    </button>
  );
}

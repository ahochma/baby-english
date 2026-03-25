import React from 'react';
import './WordCard.css';

export function WordCard({ word, categoryId, onTap, animKey }) {
  const textColor = word.textColor || '#333';
  const showBorder = word.border;

  return (
    <div
      key={animKey}
      className="word-card"
      style={{
        background: word.bg,
        boxShadow: showBorder
          ? '0 0 0 4px #ccc, 0 12px 40px rgba(0,0,0,0.12)'
          : '0 12px 40px rgba(0,0,0,0.12)',
      }}
      onClick={onTap}
    >
      <div className="word-card__emoji" style={{ '--anim-delay': '0ms' }}>
        {word.emoji}
      </div>
      <div
        className="word-card__label"
        style={{ color: textColor }}
      >
        {word.label}
      </div>
      <div className="word-card__tap-hint">
        <span className="tap-hint__icon">🔊</span>
        <span className="tap-hint__text" style={{ color: textColor, opacity: 0.5 }}>
          Tap to hear!
        </span>
      </div>
    </div>
  );
}

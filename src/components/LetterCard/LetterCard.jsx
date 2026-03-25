import React from 'react';
import './LetterCard.css';

export function LetterCard({ word, onTap }) {
  const textColor = word.textColor || '#fff';

  return (
    <div
      className="letter-card"
      style={{ background: word.bg, boxShadow: '0 12px 40px rgba(0,0,0,0.12)' }}
      onClick={onTap}
    >
      <div className="letter-card__letters" style={{ color: textColor }}>
        <span className="letter-card__upper">{word.letter}</span>
        <span className="letter-card__lower">{word.lowercase}</span>
      </div>

      <div className="letter-card__example">
        <span className="letter-card__emoji">{word.emoji}</span>
        <span className="letter-card__word" style={{ color: textColor }}>
          {word.word}
        </span>
      </div>

      <div className="letter-card__tap-hint">
        <span>🔊</span>
        <span className="letter-card__hint-text" style={{ color: textColor, opacity: 0.6 }}>
          Tap to hear!
        </span>
      </div>
    </div>
  );
}

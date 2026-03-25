import React from 'react';
import './ProgressDots.css';

export function ProgressDots({ total, current }) {
  // For large sets (ABC = 26), show a letter/number badge instead of dots
  if (total > 12) {
    return (
      <div className="progress-dots progress-dots--badge">
        <span className="progress-badge">{current + 1} / {total}</span>
      </div>
    );
  }

  return (
    <div className="progress-dots">
      {Array.from({ length: total }).map((_, i) => (
        <div
          key={i}
          className={`progress-dot ${i === current ? 'progress-dot--active' : ''} ${i < current ? 'progress-dot--done' : ''}`}
        />
      ))}
    </div>
  );
}

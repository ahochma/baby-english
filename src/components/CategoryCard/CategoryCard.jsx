import React, { useRef } from 'react';
import './CategoryCard.css';

export function CategoryCard({ category, onSelect }) {
  const cardRef = useRef(null);

  const handleTap = () => {
    const el = cardRef.current;
    if (el) {
      el.style.animation = 'none';
      el.offsetHeight; // reflow
      el.style.animation = 'categoryPop 0.25s ease forwards';
    }
    setTimeout(onSelect, 120);
  };

  return (
    <button
      ref={cardRef}
      className="category-card"
      style={{ background: category.gradient }}
      onClick={handleTap}
      aria-label={`Learn ${category.label}`}
    >
      <span className="category-card__emoji">{category.emoji}</span>
      <span className="category-card__label">{category.label}</span>
      <span className="category-card__count">{category.words.length} words</span>
    </button>
  );
}

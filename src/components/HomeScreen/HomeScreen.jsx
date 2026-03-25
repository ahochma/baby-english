import React from 'react';
import { CategoryCard } from '../CategoryCard/CategoryCard';
import { CATEGORIES } from '../../data/words';
import './HomeScreen.css';

export function HomeScreen({ onSelectCategory }) {
  return (
    <div className="home-screen">
      <div className="home-title">
        <span className="home-title__star">⭐</span>
        <span className="home-title__text">Let&apos;s Learn!</span>
        <span className="home-title__star">⭐</span>
      </div>
      <div className="home-categories">
        {Object.values(CATEGORIES).map((cat) => (
          <CategoryCard
            key={cat.id}
            category={cat}
            onSelect={() => onSelectCategory(cat.id)}
          />
        ))}
      </div>
    </div>
  );
}

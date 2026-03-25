import React, { useState, useRef, useCallback } from 'react';
import { WordCard } from '../WordCard/WordCard';
import { LetterCard } from '../LetterCard/LetterCard';
import { NavButton } from '../NavButton/NavButton';
import { BackButton } from '../BackButton/BackButton';
import { ProgressDots } from '../ProgressDots/ProgressDots';
import { useCardAudio } from '../../hooks/useCardAudio';
import { useSwipe } from '../../hooks/useSwipe';
import { CATEGORIES } from '../../data/words';
import './FlashcardScreen.css';

export function FlashcardScreen({ categoryId, onBack }) {
  const category = CATEGORIES[categoryId];
  const words = category.words;
  const [currentIndex, setCurrentIndex] = useState(0);
  const { playAudio } = useCardAudio();
  const screenRef = useRef(null);
  const hasInteracted = useRef(false);

  const currentWord = words[currentIndex];

  const goNext = useCallback(() => {
    if (currentIndex < words.length - 1) {
      setCurrentIndex(i => i + 1);
    }
  }, [currentIndex, words.length]);

  const goPrev = useCallback(() => {
    if (currentIndex > 0) {
      setCurrentIndex(i => i - 1);
    }
  }, [currentIndex]);

  // Swipe support
  useSwipe(screenRef, {
    onSwipeLeft: goNext,
    onSwipeRight: goPrev,
  });

  const handleCardTap = () => {
    hasInteracted.current = true;
    playAudio(currentWord, categoryId);
  };

  return (
    <div
      ref={screenRef}
      className="flashcard-screen"
      style={{ background: currentWord.bg }}
    >
      <BackButton onClick={onBack} />

      <div className="flashcard-screen__card-wrapper">
        {category.type === 'letter' ? (
          <LetterCard
            key={currentIndex}
            word={currentWord}
            onTap={handleCardTap}
          />
        ) : (
          <WordCard
            key={currentIndex}
            word={currentWord}
            categoryId={categoryId}
            onTap={handleCardTap}
            animKey={currentIndex}
          />
        )}
      </div>

      <NavButton
        direction="prev"
        onClick={goPrev}
        disabled={currentIndex === 0}
      />
      <NavButton
        direction="next"
        onClick={goNext}
        disabled={currentIndex === words.length - 1}
      />

      <ProgressDots total={words.length} current={currentIndex} />
    </div>
  );
}

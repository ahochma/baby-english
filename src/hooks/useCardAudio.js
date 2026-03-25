import { useRef } from 'react';
import { useSpeech } from './useSpeech';

export function useCardAudio() {
  const { speak, cancel } = useSpeech();
  const wordAudioRef = useRef(null);
  const animalAudioRef = useRef(null);

  const playAudio = (word, categoryId) => {
    cancel();

    // Stop any in-progress audio
    if (wordAudioRef.current) {
      wordAudioRef.current.pause();
      wordAudioRef.current.currentTime = 0;
    }
    if (animalAudioRef.current) {
      animalAudioRef.current.pause();
      animalAudioRef.current.currentTime = 0;
    }

    // Pick audio file: letters use letter_a.m4a, words use dog.m4a etc.
    const audioFile = categoryId === 'abc'
      ? `/sounds/words/letter_${word.id}.m4a`
      : `/sounds/words/${word.id}.m4a`;

    const wordAudio = new Audio(audioFile);
    wordAudio.preload = 'auto';
    wordAudioRef.current = wordAudio;

    wordAudio.play().then(() => {
      // After word audio ends, play animal sound if applicable
      if (categoryId === 'animals' && word.soundFile) {
        wordAudio.onended = () => {
          const animalAudio = new Audio(word.soundFile);
          animalAudioRef.current = animalAudio;
          animalAudio.play().catch(() => {});
        };
      }
    }).catch(() => {
      // Fallback to Web Speech API if audio file not available
      if (categoryId === 'animals' && word.soundFile) {
        speak(word.label, () => {
          const animalAudio = new Audio(word.soundFile);
          animalAudioRef.current = animalAudio;
          animalAudio.play().catch(() => {});
        });
      } else {
        speak(word.label);
      }
    });
  };

  return { playAudio };
}

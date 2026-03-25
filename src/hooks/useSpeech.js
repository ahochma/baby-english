import { useRef, useEffect } from 'react';

export function useSpeech() {
  const voiceRef = useRef(null);

  useEffect(() => {
    const pickVoice = () => {
      const voices = window.speechSynthesis.getVoices();
      if (!voices.length) return;

      // Prefer warm, friendly female voices
      const preferred = voices.find(v =>
        /samantha|karen|moira|fiona/i.test(v.name)
      );
      const enUS = voices.find(v => v.lang === 'en-US');
      const enAny = voices.find(v => v.lang.startsWith('en'));
      voiceRef.current = preferred || enUS || enAny || voices[0];
    };

    pickVoice();
    window.speechSynthesis.onvoiceschanged = pickVoice;

    return () => {
      window.speechSynthesis.onvoiceschanged = null;
    };
  }, []);

  const speak = (text, onEnd) => {
    window.speechSynthesis.cancel();

    const utterance = new SpeechSynthesisUtterance(text);
    utterance.lang = 'en-US';
    utterance.rate = 0.8;
    utterance.pitch = 1.2;
    utterance.volume = 1;
    if (voiceRef.current) utterance.voice = voiceRef.current;
    if (onEnd) utterance.onend = onEnd;

    try {
      window.speechSynthesis.speak(utterance);
    } catch (e) {
      // Silently fail if speech is blocked (requires user gesture on some browsers)
    }

    return utterance;
  };

  const cancel = () => {
    window.speechSynthesis.cancel();
  };

  return { speak, cancel };
}

// 26 background colors, one per letter — cycling rainbow
const LETTER_BG = [
  { bg: '#FF5252', textColor: '#fff' }, // A
  { bg: '#FF7043', textColor: '#fff' }, // B
  { bg: '#FFA726', textColor: '#fff' }, // C
  { bg: '#FFCA28', textColor: '#333' }, // D
  { bg: '#D4E157', textColor: '#333' }, // E
  { bg: '#66BB6A', textColor: '#fff' }, // F
  { bg: '#26A69A', textColor: '#fff' }, // G
  { bg: '#42A5F5', textColor: '#fff' }, // H
  { bg: '#5C6BC0', textColor: '#fff' }, // I
  { bg: '#AB47BC', textColor: '#fff' }, // J
  { bg: '#EC407A', textColor: '#fff' }, // K
  { bg: '#EF5350', textColor: '#fff' }, // L
  { bg: '#FF8A65', textColor: '#fff' }, // M
  { bg: '#FFF176', textColor: '#333' }, // N
  { bg: '#AED581', textColor: '#333' }, // O
  { bg: '#4DB6AC', textColor: '#fff' }, // P
  { bg: '#4FC3F7', textColor: '#fff' }, // Q
  { bg: '#7986CB', textColor: '#fff' }, // R
  { bg: '#CE93D8', textColor: '#333' }, // S
  { bg: '#F48FB1', textColor: '#333' }, // T
  { bg: '#FFAB91', textColor: '#333' }, // U
  { bg: '#A5D6A7', textColor: '#333' }, // V
  { bg: '#80DEEA', textColor: '#333' }, // W
  { bg: '#9FA8DA', textColor: '#fff' }, // X
  { bg: '#FFF59D', textColor: '#333' }, // Y
  { bg: '#80CBC4', textColor: '#333' }, // Z
];

const ABC_DATA = [
  { letter: 'A', word: 'Apple',      emoji: '🍎' },
  { letter: 'B', word: 'Ball',       emoji: '🏀' },
  { letter: 'C', word: 'Cat',        emoji: '🐱' },
  { letter: 'D', word: 'Dog',        emoji: '🐶' },
  { letter: 'E', word: 'Egg',        emoji: '🥚' },
  { letter: 'F', word: 'Fish',       emoji: '🐟' },
  { letter: 'G', word: 'Grapes',     emoji: '🍇' },
  { letter: 'H', word: 'Hat',        emoji: '🎩' },
  { letter: 'I', word: 'Ice Cream',  emoji: '🍦' },
  { letter: 'J', word: 'Juice',      emoji: '🧃' },
  { letter: 'K', word: 'Kite',       emoji: '🪁' },
  { letter: 'L', word: 'Lion',       emoji: '🦁' },
  { letter: 'M', word: 'Moon',       emoji: '🌙' },
  { letter: 'N', word: 'Nest',       emoji: '🪺' },
  { letter: 'O', word: 'Orange',     emoji: '🍊' },
  { letter: 'P', word: 'Pig',        emoji: '🐷' },
  { letter: 'Q', word: 'Queen',      emoji: '👸' },
  { letter: 'R', word: 'Rabbit',     emoji: '🐰' },
  { letter: 'S', word: 'Star',       emoji: '⭐' },
  { letter: 'T', word: 'Tiger',      emoji: '🐯' },
  { letter: 'U', word: 'Umbrella',   emoji: '☂️' },
  { letter: 'V', word: 'Violin',     emoji: '🎻' },
  { letter: 'W', word: 'Watermelon', emoji: '🍉' },
  { letter: 'X', word: 'X-ray',      emoji: '🩻' },
  { letter: 'Y', word: 'Yo-yo',      emoji: '🪀' },
  { letter: 'Z', word: 'Zebra',      emoji: '🦓' },
];

export const CATEGORIES = {
  abc: {
    id: 'abc',
    label: 'ABC',
    emoji: '🔤',
    color: '#1565C0',
    gradient: 'linear-gradient(135deg, #42A5F5, #0D47A1)',
    type: 'letter',
    words: ABC_DATA.map((d, i) => ({
      id: d.letter.toLowerCase(),
      letter: d.letter,
      lowercase: d.letter.toLowerCase(),
      label: d.letter,
      word: d.word,
      emoji: d.emoji,
      bg: LETTER_BG[i].bg,
      textColor: LETTER_BG[i].textColor,
    })),
  },
  animals: {
    id: 'animals',
    label: 'Animals',
    emoji: '🐾',
    color: '#4CAF50',
    gradient: 'linear-gradient(135deg, #66BB6A, #2E7D32)',
    words: [
      { id: 'dog',      label: 'Dog',      emoji: '🐶', bg: '#FFF8E1', soundFile: '/sounds/animals/dog.mp3' },
      { id: 'cat',      label: 'Cat',      emoji: '🐱', bg: '#FCE4EC', soundFile: '/sounds/animals/cat.mp3' },
      { id: 'bird',     label: 'Bird',     emoji: '🐦', bg: '#E3F2FD', soundFile: '/sounds/animals/bird.mp3' },
      { id: 'fish',     label: 'Fish',     emoji: '🐟', bg: '#E0F7FA', soundFile: '/sounds/animals/fish.mp3' },
      { id: 'cow',      label: 'Cow',      emoji: '🐮', bg: '#F3E5F5', soundFile: '/sounds/animals/cow.mp3' },
      { id: 'duck',     label: 'Duck',     emoji: '🦆', bg: '#FFFDE7', soundFile: '/sounds/animals/duck.mp3' },
      { id: 'elephant', label: 'Elephant', emoji: '🐘', bg: '#EDE7F6', soundFile: '/sounds/animals/elephant.mp3' },
      { id: 'lion',     label: 'Lion',     emoji: '🦁', bg: '#FFF3E0', soundFile: '/sounds/animals/lion.mp3' },
      { id: 'frog',     label: 'Frog',     emoji: '🐸', bg: '#E8F5E9', soundFile: '/sounds/animals/frog.mp3' },
      { id: 'rabbit',   label: 'Rabbit',   emoji: '🐰', bg: '#FCE4EC', soundFile: '/sounds/animals/rabbit.mp3' },
    ],
  },
  colors: {
    id: 'colors',
    label: 'Colors',
    emoji: '🎨',
    color: '#9C27B0',
    gradient: 'linear-gradient(135deg, #BA68C8, #6A1B9A)',
    words: [
      { id: 'red',    label: 'Red',    emoji: '🔴', bg: '#EF5350', textColor: '#fff' },
      { id: 'blue',   label: 'Blue',   emoji: '🔵', bg: '#42A5F5', textColor: '#fff' },
      { id: 'green',  label: 'Green',  emoji: '🟢', bg: '#66BB6A', textColor: '#fff' },
      { id: 'yellow', label: 'Yellow', emoji: '🟡', bg: '#FFEE58', textColor: '#333' },
      { id: 'orange', label: 'Orange', emoji: '🟠', bg: '#FFA726', textColor: '#fff' },
      { id: 'purple', label: 'Purple', emoji: '🟣', bg: '#AB47BC', textColor: '#fff' },
      { id: 'pink',   label: 'Pink',   emoji: '🩷', bg: '#F48FB1', textColor: '#fff' },
      { id: 'white',  label: 'White',  emoji: '⬜', bg: '#F5F5F5', textColor: '#333', border: true },
      { id: 'black',  label: 'Black',  emoji: '⬛', bg: '#424242', textColor: '#fff' },
      { id: 'brown',  label: 'Brown',  emoji: '🟤', bg: '#8D6E63', textColor: '#fff' },
    ],
  },
  food: {
    id: 'food',
    label: 'Food',
    emoji: '🍎',
    color: '#FF5722',
    gradient: 'linear-gradient(135deg, #FF7043, #BF360C)',
    words: [
      { id: 'apple',      label: 'Apple',      emoji: '🍎', bg: '#FFEBEE' },
      { id: 'banana',     label: 'Banana',     emoji: '🍌', bg: '#FFFDE7' },
      { id: 'milk',       label: 'Milk',       emoji: '🥛', bg: '#F5F5F5', border: true },
      { id: 'bread',      label: 'Bread',      emoji: '🍞', bg: '#FFF8E1' },
      { id: 'egg',        label: 'Egg',        emoji: '🥚', bg: '#FFF9C4', border: true },
      { id: 'orange',     label: 'Orange',     emoji: '🍊', bg: '#FFF3E0' },
      { id: 'strawberry', label: 'Strawberry', emoji: '🍓', bg: '#FCE4EC' },
      { id: 'carrot',     label: 'Carrot',     emoji: '🥕', bg: '#FFF3E0' },
      { id: 'cake',       label: 'Cake',       emoji: '🎂', bg: '#F8BBD0' },
      { id: 'grapes',     label: 'Grapes',     emoji: '🍇', bg: '#EDE7F6' },
    ],
  },
};

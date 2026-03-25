import { useState } from 'react';
import { HomeScreen } from './components/HomeScreen/HomeScreen';
import { FlashcardScreen } from './components/FlashcardScreen/FlashcardScreen';

function App() {
  const [view, setView] = useState('home');
  const [category, setCategory] = useState(null);

  const handleSelectCategory = (categoryId) => {
    setCategory(categoryId);
    setView('flashcard');
  };

  const handleBack = () => {
    setView('home');
    setCategory(null);
  };

  if (view === 'flashcard' && category) {
    return (
      <FlashcardScreen
        categoryId={category}
        onBack={handleBack}
      />
    );
  }

  return <HomeScreen onSelectCategory={handleSelectCategory} />;
}

export default App;

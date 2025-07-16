// commons.ts
export type Language = 'en' | 'es';

// Simple key-value translations
export const i18n: Record<Language, Record<string, string>> = {
  en: {
    // Header
    'header.title': 'MY AI JOURNEY',
    'header.subtitle': 'Documentation of my exploration into Artificial Intelligence',
    
    // Navigation
    'nav.english': 'English',
    'nav.spanish': 'Español',
    
    // Sections
    'section.welcome': 'Welcome',
    'section.recentUpdates': 'Recent Updates',
    'section.currentFocus': 'Current Focus',
    
    // Welcome content
    'welcome.paragraph1': 'This page serves as a simple chronicle of my journey into the fascinating world of Artificial Intelligence. Here you\'ll find updates on projects, learnings, and milestones as I explore machine learning, deep learning, and various AI applications.',
    'welcome.paragraph2': 'Started in January 2024, this documentation tracks my progress from basic concepts to more advanced implementations and real-world applications.',
    
    // Current focus items
    'focus.item1': '→ Exploring Large Language Models and their applications',
    'focus.item2': '→ Building end-to-end ML pipelines with MLOps practices',
    'focus.item3': '→ Studying reinforcement learning algorithms',
    
    // Footer
    'footer.lastUpdated': 'Last updated:',
    'footer.quote': '"The journey of a thousand miles begins with a single step." - Lao Tzu',
    
    // Journey entries
    'entry.title1': 'Getting Started with Machine Learning',
    'entry.desc1': 'Began exploring the fundamentals of ML algorithms and data preprocessing techniques.',
    'entry.title2': 'Deep Learning Foundations',
    'entry.desc2': 'Dove into neural networks, backpropagation, and implemented my first neural network from scratch.',
    'entry.title3': 'Natural Language Processing',
    'entry.desc3': 'Explored text processing, sentiment analysis, and built a simple chatbot.',
    'entry.title4': 'Computer Vision Projects',
    'entry.desc4': 'Implemented image classification and object detection models for real-world applications.',
    
    // Common
    'common.technologies': 'Technologies:'
  },
  es: {
    // Header
    'header.title': 'MI VIAJE EN IA',
    'header.subtitle': 'Documentación de mi exploración en Inteligencia Artificial',
    
    // Navigation
    'nav.english': 'English',
    'nav.spanish': 'Español',
    
    // Sections
    'section.welcome': 'Bienvenido',
    'section.recentUpdates': 'Actualizaciones Recientes',
    'section.currentFocus': 'Enfoque Actual',
    
    // Welcome content
    'welcome.paragraph1': 'Esta página sirve como una crónica simple de mi viaje hacia el fascinante mundo de la Inteligencia Artificial. Aquí encontrarás actualizaciones sobre proyectos, aprendizajes e hitos mientras exploro el aprendizaje automático, aprendizaje profundo y varias aplicaciones de IA.',
    'welcome.paragraph2': 'Comenzado en enero de 2024, esta documentación rastrea mi progreso desde conceptos básicos hasta implementaciones más avanzadas y aplicaciones del mundo real.',
    
    // Current focus items
    'focus.item1': '→ Explorando Modelos de Lenguaje Grande y sus aplicaciones',
    'focus.item2': '→ Construyendo pipelines de ML completos con prácticas MLOps',
    'focus.item3': '→ Estudiando algoritmos de aprendizaje por refuerzo',
    
    // Footer
    'footer.lastUpdated': 'Última actualización:',
    'footer.quote': '"Un viaje de mil millas comienza con un solo paso." - Lao Tzu',
    
    // Journey entries
    'entry.title1': 'Comenzando con Aprendizaje Automático',
    'entry.desc1': 'Comencé a explorar los fundamentos de algoritmos de ML y técnicas de preprocesamiento de datos.',
    'entry.title2': 'Fundamentos de Aprendizaje Profundo',
    'entry.desc2': 'Me sumergí en redes neuronales, retropropagación e implementé mi primera red neuronal desde cero.',
    'entry.title3': 'Procesamiento de Lenguaje Natural',
    'entry.desc3': 'Exploré el procesamiento de texto, análisis de sentimientos y construí un chatbot simple.',
    'entry.title4': 'Proyectos de Visión por Computadora',
    'entry.desc4': 'Implementé modelos de clasificación de imágenes y detección de objetos para aplicaciones del mundo real.',
    
    // Common
    'common.technologies': 'Tecnologías:'
  }
};

// Translation function
export const t = (key: string, language: Language): string => {
  return i18n[language][key] || key;
};

// Journey entries data
export interface JourneyEntry {
  id: string;
  date: string;
  technologies?: string[];
}

export const journeyEntries: JourneyEntry[] = [
  {
    id: '1',
    date: '2025-07-16',
    technologies: ['Python', 'Scikit-learn', 'Pandas']
  },
  {
    id: '2', 
    date: '2024-02-03',
    technologies: ['TensorFlow', 'Keras', 'NumPy']
  },
  {
    id: '3',
    date: '2024-03-12',
    technologies: ['NLTK', 'spaCy', 'Transformers']
  },
  {
    id: '4',
    date: '2024-04-20',
    technologies: ['OpenCV', 'PyTorch', 'YOLO']
  }
];
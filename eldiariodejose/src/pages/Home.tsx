import { useState } from 'react';
import { t, journeyEntries, type Language } from '../translations/commons';

const styles = {
  container: {
    fontFamily: 'Georgia, "Times New Roman", serif',
    maxWidth: '800px',
    margin: '0 auto',
    padding: '20px',
    backgroundColor: '#f8f8f8',
    minHeight: '100vh',
    color: '#333'
  },
  topBar: {
    position: 'absolute' as const,
    top: '20px',
    display: 'flex',
    gap: '15px',
    alignItems: 'center',
  },
  languageSwitch: {
    display: 'flex',
    gap: '10px'
  },
  languageButton: {
    background: 'none',
    border: '1px solid #333',
    padding: '5px 10px',
    fontFamily: 'Georgia, "Times New Roman", serif',
    fontSize: '0.9rem',
    cursor: 'pointer',
    color: '#333'
  },
  languageButtonActive: {
    background: '#333',
    color: '#f8f8f8'
  },
  topBarButton: {
    background: 'none',
    border: '1px solid #333',
    padding: '8px 15px',
    fontFamily: 'Georgia, "Times New Roman", serif',
    fontSize: '0.9rem',
    cursor: 'pointer',
    color: '#333',
    textDecoration: 'none'
  },
  header: {
    textAlign: 'center' as const,
    borderBottom: '2px solid #333',
    paddingBottom: '20px',
    marginBottom: '30px',
    marginTop: '60px'
  },
  title: {
    fontSize: '2.5rem',
    margin: '0',
    fontWeight: 'normal' as const,
    letterSpacing: '2px'
  },
  subtitle: {
    fontSize: '1.1rem',
    margin: '10px 0 0 0',
    fontStyle: 'italic' as const,
    color: '#666'
  },
  section: {
    marginBottom: '40px'
  },
  sectionTitle: {
    fontSize: '1.5rem',
    borderBottom: '1px solid #666',
    paddingBottom: '5px',
    marginBottom: '15px'
  },
  paragraph: {
    lineHeight: '1.6',
    fontSize: '1rem',
    textAlign: 'justify' as const,
    marginBottom: '15px'
  },
  paragraphLast: {
    lineHeight: '1.6',
    fontSize: '1rem',
    textAlign: 'justify' as const
  },
  sectionTitleUpdates: {
    fontSize: '1.5rem',
    borderBottom: '1px solid #666',
    paddingBottom: '5px',
    marginBottom: '20px'
  },
  entryCard: {
    marginBottom: '25px',
    padding: '15px',
    backgroundColor: '#fff',
    border: '1px solid #ddd',
    borderRadius: '0'
  },
  entryTitle: {
    fontSize: '1.2rem',
    margin: '0 0 5px 0',
    color: '#2c3e50'
  },
  entryDate: {
    fontSize: '0.9rem',
    color: '#666',
    margin: '0 0 10px 0',
    fontStyle: 'italic' as const
  },
  entryDescription: {
    lineHeight: '1.5',
    margin: '0 0 10px 0'
  },
  entryTechnologies: {
    fontSize: '0.85rem',
    color: '#555'
  },
  focusList: {
    listStyle: 'none',
    padding: '0',
    margin: '0'
  },
  focusItem: {
    marginBottom: '10px',
    padding: '10px',
    backgroundColor: '#fff',
    border: '1px solid #ddd'
  },
  footer: {
    textAlign: 'center' as const,
    borderTop: '1px solid #666',
    paddingTop: '20px',
    fontSize: '0.9rem',
    color: '#666'
  },
  footerQuote: {
    margin: '5px 0'
  }
};

const HomePage = () => {
  const [currentLanguage, setCurrentLanguage] = useState<Language>('en');

  const handleLanguageChange = (language: Language) => {
    setCurrentLanguage(language);
  };

  const handleTopBarButtonClick = () => {
    // Add your custom functionality here
    console.log('Top bar button clicked!');
    // Example: navigate to projects page, open modal, etc.
  };

  const focusItems = ['focus.item1', 'focus.item2', 'focus.item3'];

  return (
    <div style={styles.container}>
      {/* Top Bar */}
      <div style={styles.topBar}>
        <button
          style={styles.topBarButton}
          onClick={handleTopBarButtonClick}
        >
          {t('nav.projects', currentLanguage)}
        </button>
        
        <div style={styles.languageSwitch}>
          <button
            style={{
              ...styles.languageButton,
              ...(currentLanguage === 'en' ? styles.languageButtonActive : {})
            }}
            onClick={() => handleLanguageChange('en')}
          >
            {t('nav.english', currentLanguage)}
          </button>
          <button
            style={{
              ...styles.languageButton,
              ...(currentLanguage === 'es' ? styles.languageButtonActive : {})
            }}
            onClick={() => handleLanguageChange('es')}
          >
            {t('nav.spanish', currentLanguage)}
          </button>
        </div>
      </div>

      {/* Header */}
      <header style={styles.header}>
        <h1 style={styles.title}>
          {t('header.title', currentLanguage)}
        </h1>
        <p style={styles.subtitle}>
          {t('header.subtitle', currentLanguage)}
        </p>
      </header>

      {/* Introduction */}
      <section style={styles.section}>
        <h2 style={styles.sectionTitle}>
          {t('section.welcome', currentLanguage)}
        </h2>
        <p style={styles.paragraph}>
          {t('welcome.paragraph1', currentLanguage)}
        </p>
        <p style={styles.paragraphLast}>
          {t('welcome.paragraph2', currentLanguage)}
        </p>
      </section>

      {/* Recent Updates */}
      <section style={styles.section}>
        <h2 style={styles.sectionTitleUpdates}>
          {t('section.recentUpdates', currentLanguage)}
        </h2>
        
        {journeyEntries.map((entry, _) => (
          <div key={entry.id} style={styles.entryCard}>
            <h3 style={styles.entryTitle}>
              {t(`entry.title${entry.id}`, currentLanguage)}
            </h3>
            <p style={styles.entryDate}>
              {new Date(entry.date).toLocaleDateString(currentLanguage === 'es' ? 'es-ES' : 'en-US', {
                year: 'numeric',
                month: 'long',
                day: 'numeric'
              })}
            </p>
            <p style={styles.entryDescription}>
              {t(`entry.desc${entry.id}`, currentLanguage)}
            </p>
            {entry.technologies && (
              <div style={styles.entryTechnologies}>
                <strong>{t('common.technologies', currentLanguage)}</strong> {entry.technologies.join(', ')}
              </div>
            )}
          </div>
        ))}
      </section>

      {/* Current Focus */}
      <section style={styles.section}>
        <h2 style={styles.sectionTitle}>
          {t('section.currentFocus', currentLanguage)}
        </h2>
        <ul style={styles.focusList}>
          {focusItems.map((itemKey, index) => (
            <li key={index} style={styles.focusItem}>
              {t(itemKey, currentLanguage)}
            </li>
          ))}
        </ul>
      </section>

      {/* Footer */}
      <footer style={styles.footer}>
        <p>
          {t('footer.lastUpdated', currentLanguage)} {new Date().toLocaleDateString(currentLanguage === 'es' ? 'es-ES' : 'en-US')}
        </p>
        <p style={styles.footerQuote}>
          {t('footer.quote', currentLanguage)}
        </p>
      </footer>
    </div>
  );
};

export default HomePage;
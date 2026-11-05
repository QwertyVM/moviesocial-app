/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        cinema: {
          bg: '#0B0C0E',         // Fondo negro OLED profundo
          surface: '#121418',    // Superficie elevada
          card: '#161920',       // Tarjetas y paneles
          cardHover: '#1D212A',  // Hover en tarjetas
          border: '#232733',     // Bordes sutiles
          borderHover: '#383E4E',// Bordes en focus/hover
          gold: '#E5A93C',       // Puntuación MovieScore
          goldDark: '#B87A1E',
          red: '#FA320A',        // Rotten Tomatoes Tomatometer
          green: '#57E389',      // Rotten Tomatoes Popcorn / Éxito
          imdb: '#F5C518',       // IMDb Dorado
          textPrimary: '#F3F4F6',
          textSecondary: '#9CA3AF',
          textMuted: '#6B7280',
        }
      },
      fontFamily: {
        sans: [
          'Inter',
          '-apple-system',
          'BlinkMacSystemFont',
          'Segoe UI',
          'Roboto',
          'sans-serif',
        ],
      },
    },
  },
  plugins: [],
}


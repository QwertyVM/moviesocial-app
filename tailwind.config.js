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
          bg: '#08090B',         // Fondo negro OLED cinematográfico ultra profundo
          surface: '#0F1116',    // Superficie elevada
          card: '#14171E',       // Tarjetas y paneles
          cardHover: '#1B1F2A',  // Hover en tarjetas
          border: '#202532',     // Bordes sutiles
          borderHover: '#374154',// Bordes en focus/hover
          gold: '#E5A93C',       // Puntuación MovieScore
          goldLight: '#F5C66C',  // Brillo dorado cinéfilo
          goldDark: '#B87A1E',
          red: '#FA320A',        // Rotten Tomatoes Tomatometer
          green: '#57E389',      // Rotten Tomatoes Popcorn / Éxito
          imdb: '#F5C518',       // IMDb Dorado
          textPrimary: '#F3F4F6',
          textSecondary: '#9CA3AF',
          textMuted: '#6B7280',
        }
      },
      boxShadow: {
        'cinema-glow': '0 0 50px -12px rgba(229, 169, 60, 0.25)',
        'poster-glow': '0 10px 30px -10px rgba(0, 0, 0, 0.8)',
        'projector': '0 20px 40px -15px rgba(229, 169, 60, 0.15)',
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


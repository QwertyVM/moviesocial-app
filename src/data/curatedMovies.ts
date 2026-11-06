import { Movie, UserLocation, CinemaShowtime, User, Friend, MovieGroup, Review, calculateCompositeScore } from '../types';

export const AVAILABLE_CITIES: UserLocation[] = [
  { city: 'Lima', country: 'Perú', countryCode: 'PE', flagEmoji: '🇵🇪', isLocal: true, area: 'Lima Metropolitana' },
  { city: 'Ciudad de México', country: 'México', countryCode: 'MX', flagEmoji: '🇲🇽', isLocal: true, area: 'CDMX / Valle de México' },
  { city: 'Madrid', country: 'España', countryCode: 'ES', flagEmoji: '🇪🇸', isLocal: true, area: 'Comunidad de Madrid' },
  { city: 'Barcelona', country: 'España', countryCode: 'ES', flagEmoji: '🇪🇸', isLocal: true, area: 'Cataluña' },
  { city: 'Bogotá', country: 'Colombia', countryCode: 'CO', flagEmoji: '🇨🇴', isLocal: true, area: 'Bogotá D.C.' },
  { city: 'Buenos Aires', country: 'Argentina', countryCode: 'AR', flagEmoji: '🇦🇷', isLocal: true, area: 'CABA / AMBA' },
  { city: 'Santiago', country: 'Chile', countryCode: 'CL', flagEmoji: '🇨🇱', isLocal: true, area: 'Región Metropolitana' },
  { city: 'Los Ángeles', country: 'Estados Unidos', countryCode: 'US', flagEmoji: '🇺🇸', isLocal: true, area: 'California' },
  { city: 'Nueva York', country: 'Estados Unidos', countryCode: 'US', flagEmoji: '🇺🇸', isLocal: true, area: 'New York' },
  { city: 'París', country: 'Francia', countryCode: 'FR', flagEmoji: '🇫🇷', isLocal: true, area: 'Île-de-France' },
  { city: 'Tokio', country: 'Japón', countryCode: 'JP', flagEmoji: '🇯🇵', isLocal: true, area: 'Kanto' },
];

export const CITY_SHOWTIMES: Record<string, Record<string, CinemaShowtime[]>> = {
  'lima': {
    'ekeko_pe_2026': [
      { cinemaName: 'Cineplanet Alcázar Prime', city: 'Lima', roomFormat: 'Sala 1 Prime', times: ['17:30', '20:15', '22:45'] },
      { cinemaName: 'Cinemark Jockey Plaza XD', city: 'Lima', roomFormat: 'Sala XD Dolby Atmos', times: ['19:00', '21:30'] },
      { cinemaName: 'CCPUCP San Isidro', city: 'Lima', roomFormat: 'Sala Azul Cine de Autor', times: ['18:00', '20:30'] },
    ],
    'obsesion_2026': [
      { cinemaName: 'Cineplanet San Miguel', city: 'Lima', roomFormat: 'Sala 4 (Subtitulada)', times: ['18:40', '21:10'] },
      { cinemaName: 'Cinemark Angamos', city: 'Lima', roomFormat: 'Sala 2 2D', times: ['17:00', '19:40', '22:15'] },
    ],
    'dune_part_two': [
      { cinemaName: 'Cinemark Jockey Plaza XD', city: 'Lima', roomFormat: 'Sala XD IMAX', times: ['16:00', '19:45'] },
      { cinemaName: 'Cineplanet Mall del Sur', city: 'Lima', roomFormat: 'Sala Xtreme', times: ['18:30', '21:40'] },
    ],
    'deadpool_wolverine': [
      { cinemaName: 'Cineplanet Alcázar', city: 'Lima', roomFormat: 'Sala 3', times: ['16:15', '19:00', '21:45'] },
      { cinemaName: 'Cinemark San Miguel', city: 'Lima', roomFormat: 'Sala XD', times: ['18:15', '21:00'] },
    ]
  },
  'ciudad de méxico': {
    'obsesion_2026': [
      { cinemaName: 'Cineteca Nacional México', city: 'Ciudad de México', roomFormat: 'Sala 1 Gabriel Figueroa', times: ['16:30', '19:00', '21:15'] },
      { cinemaName: 'Cinépolis Diana Reforma', city: 'Ciudad de México', roomFormat: 'Sala 4 Macro XE', times: ['17:45', '20:20', '22:50'] },
      { cinemaName: 'Cine Tonalá Roma Sur', city: 'Ciudad de México', roomFormat: 'Sala Cineclub', times: ['18:00', '20:45'] },
    ],
    'dune_part_two': [
      { cinemaName: 'Cinépolis Universidad IMAX', city: 'Ciudad de México', roomFormat: 'IMAX con Láser', times: ['16:00', '19:30', '22:45'] },
      { cinemaName: 'Cinemex Reforma 222', city: 'Ciudad de México', roomFormat: 'Sala Platino', times: ['18:15', '21:30'] },
    ],
    'furiosa_mad_max': [
      { cinemaName: 'Cinépolis Perisur', city: 'Ciudad de México', roomFormat: 'Sala 4DX 3D', times: ['17:00', '20:15'] },
      { cinemaName: 'Cineteca de las Artes', city: 'Ciudad de México', roomFormat: 'Sala 3', times: ['18:45', '21:20'] },
    ],
  },
  'madrid': {
    'obsesion_2026': [
      { cinemaName: 'Cine Yelmo Ideal', city: 'Madrid', roomFormat: 'Sala 3 (VOSE)', times: ['18:15', '20:45', '22:50'] },
      { cinemaName: 'Cinesa Proyecciones', city: 'Madrid', roomFormat: 'Sala iSense', times: ['17:30', '20:00', '22:30'] },
      { cinemaName: 'Cineteca Matadero', city: 'Madrid', roomFormat: 'Sala Azcona', times: ['19:15', '21:30'] },
    ],
    'dune_part_two': [
      { cinemaName: 'Kinépolis Madrid Ciudad de la Imagen', city: 'Madrid', roomFormat: 'Sala IMAX 70mm Laser', times: ['17:00', '20:30'] },
      { cinemaName: 'Phenomena Madrid', city: 'Madrid', roomFormat: 'Gran Sala VOSE', times: ['19:00', '22:00'] },
    ],
  },
  'bogotá': {
    'obsesion_2026': [
      { cinemaName: 'Cinemateca de Bogotá', city: 'Bogotá', roomFormat: 'Sala Capital', times: ['17:00', '19:30'] },
      { cinemaName: 'Cine Colombia Andino', city: 'Bogotá', roomFormat: 'Sala Múltiplex Diners', times: ['18:30', '21:00'] },
    ],
    'dune_part_two': [
      { cinemaName: 'Cine Colombia Centro Mayor MegaSala', city: 'Bogotá', roomFormat: 'MegaSala Onyx', times: ['16:15', '19:45'] },
    ]
  },
  'buenos aires': {
    'obsesion_2026': [
      { cinemaName: 'Malba Cine', city: 'Buenos Aires', roomFormat: 'Sala Auditorio', times: ['19:00', '21:30'] },
      { cinemaName: 'Cine Gaumont Espacio INCAA', city: 'Buenos Aires', roomFormat: 'Sala Leonardo Favio', times: ['18:00', '20:30'] },
    ],
    'dune_part_two': [
      { cinemaName: 'Showcase IMAX Norcenter', city: 'Buenos Aires', roomFormat: 'IMAX 3D', times: ['17:15', '20:45'] },
      { cinemaName: 'Cinemark Palermo', city: 'Buenos Aires', roomFormat: 'Sala XD Atmos', times: ['18:30', '21:50'] },
    ]
  },
  'santiago': {
    'obsesion_2026': [
      { cinemaName: 'Cineteca Nacional de Chile', city: 'Santiago', roomFormat: 'Sala Microcine', times: ['18:15', '20:45'] },
      { cinemaName: 'Cineplanet Costanera Center', city: 'Santiago', roomFormat: 'Sala Prime', times: ['17:30', '20:10', '22:40'] },
    ],
    'dune_part_two': [
      { cinemaName: 'Cinemark Mallplaza Egaña', city: 'Santiago', roomFormat: 'Sala IMAX', times: ['16:45', '20:15'] },
    ]
  }
};

export const RAW_MOVIES: Movie[] = [
  // --- ESTRENOS ACTUALES EN CINES (Según país) ---
  {
    id: 'obsesion_2026',
    title: 'Obsesión (Obsession)',
    overview: 'Bear pide un deseo al enigmático Sauce de los Deseos para que Nikki, su amor platónico de la infancia, se enamore de él. Pronto, su afecto se transforma en una asfixiante, violenta y aterradora pesadilla de posesión sobrenatural en este aclamado filme de terror psicológico.',
    releaseYear: 2026,
    releaseDate: '2026-10-25',
    posterURL: 'https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=500&auto=format&fit=crop&q=80',
    backdropURL: 'https://images.unsplash.com/photo-1518676599649-f000e527c7f4?w=1280&auto=format&fit=crop&q=80',
    genres: ['Terror', 'Suspenso', 'Misterio'],
    runtimeMinutes: 98,
    imdbId: 'tt3355026',
    director: 'Curry Barker',
    countryOfOrigin: 'US',
    originCountryName: 'Estados Unidos',
    theatricalCountries: ['PE', 'MX', 'ES', 'CO', 'AR', 'CL', 'US', 'FR'],
    ratings: {
      rottenTomatoesCritics: 92,
      rottenTomatoesAudience: 88,
      imdbScore: 8.4,
      imdbVotes: '14.2K',
      compositeScore: 8.6
    }
  },
  {
    id: 'ekeko_pe_2026',
    title: 'Ekeko: El Dios de la Abundancia',
    overview: 'Un thriller andino donde un comerciante desesperado invoca a una deidad precolombina para salvar a su familia de la ruina, pero cada deseo concedido exige un tributo cada vez más siniestro en las alturas de los Andes peruanos.',
    releaseYear: 2026,
    releaseDate: '2026-10-23',
    posterURL: 'https://images.unsplash.com/photo-1509281373149-e957c6296406?w=500&auto=format&fit=crop&q=80',
    backdropURL: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=1280&auto=format&fit=crop&q=80',
    genres: ['Terror Folclórico', 'Misterio', 'Drama'],
    runtimeMinutes: 104,
    imdbId: 'tt3344011',
    director: 'Marco Panéz',
    countryOfOrigin: 'PE',
    originCountryName: 'Perú',
    theatricalCountries: ['PE'], // Estreno exclusivo en cines de Perú
    ratings: {
      rottenTomatoesCritics: 89,
      rottenTomatoesAudience: 91,
      imdbScore: 8.5,
      imdbVotes: '8.7K',
      compositeScore: 8.7
    }
  },
  {
    id: 'gladiator_two',
    title: 'Gladiador II (Gladiator II)',
    overview: 'Años después de presenciar la muerte del admirado héroe Máximo a manos de su tío, Lucio debe entrar en el Coliseo tras ser conquistado su hogar por los tiránicos emperadores que ahora lideran Roma.',
    releaseYear: 2026,
    releaseDate: '2026-11-02',
    posterURL: 'https://image.tmdb.org/t/p/w500/2cxhvwyEwRlysAmRHbtVIQI98D.jpg',
    backdropURL: 'https://image.tmdb.org/t/p/w1280/euYIwmwkmz95mnExrPy4vAeaQdU.jpg',
    genres: ['Acción', 'Aventura', 'Drama'],
    runtimeMinutes: 148,
    imdbId: 'tt9218128',
    director: 'Ridley Scott',
    countryOfOrigin: 'US',
    originCountryName: 'Estados Unidos',
    theatricalCountries: ['PE', 'MX', 'ES', 'CO', 'AR', 'CL', 'US', 'FR'],
    ratings: {
      rottenTomatoesCritics: 76,
      rottenTomatoesAudience: 87,
      imdbScore: 7.2,
      imdbVotes: '180K',
      compositeScore: 7.8
    }
  },
  {
    id: 'wicked_2024',
    title: 'Wicked',
    overview: 'Elphaba, una joven incomprendida debido a su inusual piel verde, y Glinda, una joven popular dorada por el privilegio, forjan una amistad improbable pero profunda en la Universidad de Shiz.',
    releaseYear: 2026,
    releaseDate: '2026-11-04',
    posterURL: 'https://image.tmdb.org/t/p/w500/2E1x1qcHqGZc99j0z7mUeIeeCj7.jpg',
    backdropURL: 'https://image.tmdb.org/t/p/w1280/tElnmtQ6yz1PjN1kePNl8yMSb59.jpg',
    genres: ['Fantasía', 'Drama', 'Romance'],
    runtimeMinutes: 160,
    imdbId: 'tt1787884',
    director: 'Jon M. Chu',
    countryOfOrigin: 'US',
    originCountryName: 'Estados Unidos',
    theatricalCountries: ['PE', 'MX', 'ES', 'CO', 'AR', 'CL', 'US', 'FR'],
    ratings: {
      rottenTomatoesCritics: 90,
      rottenTomatoesAudience: 95,
      imdbScore: 8.0,
      imdbVotes: '135K',
      compositeScore: 8.6
    }
  },

  // --- CATÁLOGO GENERAL (FUERA DE ESTRENO / STREAMING Y FORMATOS DOMÉSTICOS) ---
  // Ordenados naturalmente por fecha descendente
  {
    id: 'deadpool_wolverine',
    title: 'Deadpool & Wolverine',
    overview: 'Un apático Wade Wilson lucha en la vida civil con sus días como el mercenario moralmente flexible Deadpool a sus espaldas. Pero cuando su mundo natal enfrenta una amenaza existencial, Wade debe volver a ponerse el traje.',
    releaseYear: 2026,
    releaseDate: '2026-10-28',
    posterURL: 'https://image.tmdb.org/t/p/w500/8cdWjvZQUExUUTzyp4t6EDMubfO.jpg',
    backdropURL: 'https://image.tmdb.org/t/p/w1280/dvBCWXtTxftVkkiIauU2980Z0Q9.jpg',
    genres: ['Acción', 'Comedia', 'Ciencia Ficción'],
    runtimeMinutes: 128,
    imdbId: 'tt6263850',
    director: 'Shawn Levy',
    countryOfOrigin: 'US',
    originCountryName: 'Estados Unidos',
    theatricalCountries: ['PE', 'MX', 'ES', 'CO', 'AR', 'CL', 'US', 'FR'],
    ratings: {
      rottenTomatoesCritics: 78,
      rottenTomatoesAudience: 94,
      imdbScore: 7.7,
      imdbVotes: '360K',
      compositeScore: 8.0
    }
  },
  {
    id: 'furiosa_mad_max',
    title: 'Furiosa: De la Saga Mad Max',
    overview: 'Al caer el mundo, la joven Furiosa es arrebatada del Lugar Verde de Muchas Madres y cae en manos de una gran Horda de Motoristas liderada por el Señor de la Guerra Dementus.',
    releaseYear: 2026,
    releaseDate: '2026-10-26',
    posterURL: 'https://image.tmdb.org/t/p/w500/iADOJ8Zymht2JPMoy3R7xUMZ51.jpg',
    backdropURL: 'https://image.tmdb.org/t/p/w1280/wNAhuOZ3Zf84jCI5TeTV5Y8JJR9.jpg',
    genres: ['Acción', 'Aventura', 'Ciencia Ficción'],
    runtimeMinutes: 148,
    imdbId: 'tt12037194',
    director: 'George Miller',
    countryOfOrigin: 'AU',
    originCountryName: 'Australia',
    theatricalCountries: ['PE', 'MX', 'ES', 'CO', 'AR', 'CL', 'US', 'FR'],
    ratings: {
      rottenTomatoesCritics: 90,
      rottenTomatoesAudience: 89,
      imdbScore: 7.6,
      imdbVotes: '210K',
      compositeScore: 8.1
    }
  },
  {
    id: 'dune_part_two',
    title: 'Dune: Parte Dos (Dune: Part Two)',
    overview: 'Paul Atreides se une a Chani y a los Fremen mientras busca venganza contra los conspiradores que destruyeron a su familia. Ante una elección entre el amor de su vida y el destino del universo, debe prevenir un futuro terrible que solo él puede prever.',
    releaseYear: 2026,
    releaseDate: '2026-10-31',
    posterURL: 'https://image.tmdb.org/t/p/w500/8b8R8l88Qje9dn9OE8PY05Nxl1X.jpg',
    backdropURL: 'https://image.tmdb.org/t/p/w1280/xOMo8BRK7PfcJv9JCnx7s5200bm.jpg',
    genres: ['Ciencia Ficción', 'Aventura', 'Drama'],
    runtimeMinutes: 166,
    imdbId: 'tt15239678',
    director: 'Denis Villeneuve',
    countryOfOrigin: 'US',
    originCountryName: 'Estados Unidos',
    theatricalCountries: ['PE', 'MX', 'ES', 'CO', 'AR', 'CL', 'US', 'FR'],
    ratings: {
      rottenTomatoesCritics: 92,
      rottenTomatoesAudience: 95,
      imdbScore: 8.5,
      imdbVotes: '540K',
      compositeScore: 8.8
    }
  },
  {
    id: 'oppenheimer',
    title: 'Oppenheimer',
    overview: 'La historia del científico estadounidense J. Robert Oppenheimer y su papel fundamental en el desarrollo y creación de la bomba atómica durante el Proyecto Manhattan.',
    releaseYear: 2023,
    releaseDate: '2023-07-21',
    posterURL: 'https://image.tmdb.org/t/p/w500/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg',
    backdropURL: 'https://image.tmdb.org/t/p/w1280/rLb2cwF3Pazuxaj0sRXQ037tGI1.jpg',
    genres: ['Drama', 'Historia', 'Biografía'],
    runtimeMinutes: 180,
    imdbId: 'tt15398776',
    director: 'Christopher Nolan',
    countryOfOrigin: 'US',
    originCountryName: 'Estados Unidos',
    theatricalCountries: [],
    ratings: {
      rottenTomatoesCritics: 93,
      rottenTomatoesAudience: 91,
      imdbScore: 8.9,
      imdbVotes: '820K',
      compositeScore: 9.1
    }
  },
  {
    id: 'the_batman',
    title: 'The Batman',
    overview: 'En su segundo año luchando contra el crimen, Batman explora la corrupción existente en Gotham City y el vínculo de esta con su propia familia mientras persigue a El Acertijo.',
    releaseYear: 2022,
    releaseDate: '2022-03-04',
    posterURL: 'https://image.tmdb.org/t/p/w500/74xTEgt7R36Fpooo50r9T25onhq.jpg',
    backdropURL: 'https://image.tmdb.org/t/p/w1280/b0PlSFdDwbyK0cf5RxwDpaOJQvQ.jpg',
    genres: ['Acción', 'Crimen', 'Drama'],
    runtimeMinutes: 176,
    imdbId: 'tt1877830',
    director: 'Matt Reeves',
    countryOfOrigin: 'US',
    originCountryName: 'Estados Unidos',
    theatricalCountries: [],
    ratings: {
      rottenTomatoesCritics: 85,
      rottenTomatoesAudience: 87,
      imdbScore: 7.8,
      imdbVotes: '780K',
      compositeScore: 8.2
    }
  },
  {
    id: 'parasite',
    title: 'Parásitos (Parasite)',
    overview: 'Tanto Gi-taek como su familia están sin trabajo. Cuando su hijo mayor empieza a dar clases particulares en la adinerada casa de los Park, las dos familias se involucran en una serie de eventos inesperados.',
    releaseYear: 2019,
    releaseDate: '2019-05-30',
    posterURL: 'https://image.tmdb.org/t/p/w500/7IiTTgloJzvGI1TAYymCfbfl3vT.jpg',
    backdropURL: 'https://image.tmdb.org/t/p/w1280/hiKmpZMGZsrkA3cdce8a7Dpos1j.jpg',
    genres: ['Comedia Negra', 'Drama', 'Suspenso'],
    runtimeMinutes: 132,
    imdbId: 'tt6751668',
    director: 'Bong Joon-ho',
    countryOfOrigin: 'KR',
    originCountryName: 'Corea del Sur',
    theatricalCountries: [],
    ratings: {
      rottenTomatoesCritics: 99,
      rottenTomatoesAudience: 95,
      imdbScore: 8.5,
      imdbVotes: '950K',
      compositeScore: 9.2
    }
  },
  {
    id: 'interstellar',
    title: 'Interestelar (Interstellar)',
    overview: 'Un equipo de exploradores viaja a través de un agujero de gusano en el espacio en un intento por asegurar la supervivencia de la humanidad.',
    releaseYear: 2014,
    releaseDate: '2014-11-07',
    posterURL: 'https://image.tmdb.org/t/p/w500/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg',
    backdropURL: 'https://image.tmdb.org/t/p/w1280/xJHokMbljvjADYdit5fK5VQsXEG.jpg',
    genres: ['Ciencia Ficción', 'Drama', 'Aventura'],
    runtimeMinutes: 169,
    imdbId: 'tt0816692',
    director: 'Christopher Nolan',
    countryOfOrigin: 'US',
    originCountryName: 'Estados Unidos',
    theatricalCountries: [],
    ratings: {
      rottenTomatoesCritics: 73,
      rottenTomatoesAudience: 86,
      imdbScore: 8.7,
      imdbVotes: '2.1M',
      compositeScore: 8.3
    }
  },
  {
    id: 'fast_five_2011',
    title: 'Rápidos y Furiosos 5in Control (Fast Five)',
    overview: 'Dominic Toretto y Brian O\'Conner reúnen a su legendario equipo en Río de Janeiro para un último atraco de 100 millones de dólares.',
    releaseYear: 2011,
    releaseDate: '2011-04-29',
    posterURL: 'https://m.media-amazon.com/images/M/MV5BMTUxNTk5MTE0OF5BMl5BanBnXkFtZTcwMjA2NzY3NA@@._V1_QL75_UX380_CR0,0,380,562_.jpg',
    backdropURL: 'https://image.tmdb.org/t/p/w1280/lGDeo2NlTz6N1H8F1N6H9Tf6iXF.jpg',
    genres: ['Acción', 'Crimen', 'Suspenso'],
    runtimeMinutes: 130,
    imdbId: 'tt1596343',
    director: 'Justin Lin',
    countryOfOrigin: 'US',
    originCountryName: 'Estados Unidos',
    theatricalCountries: [],
    ratings: {
      rottenTomatoesCritics: 78,
      rottenTomatoesAudience: 83,
      imdbScore: 7.3,
      imdbVotes: '430K',
      compositeScore: 7.5
    }
  },
  {
    id: 'the_dark_knight',
    title: 'El Caballero de la Noche (The Dark Knight)',
    overview: 'Cuando la amenaza conocida como el Joker causa estragos y caos en Gotham, Batman debe aceptar una de las mayores pruebas psicológicas y físicas de su capacidad para combatir la injusticia.',
    releaseYear: 2008,
    releaseDate: '2008-07-18',
    posterURL: 'https://image.tmdb.org/t/p/w500/qJ2tW6WMUDux911r6m7haRef0WH.jpg',
    backdropURL: 'https://image.tmdb.org/t/p/w1280/oKa4iyqC4f7H9sF61C0K2B64t.jpg',
    genres: ['Acción', 'Crimen', 'Drama'],
    runtimeMinutes: 152,
    imdbId: 'tt0468569',
    director: 'Christopher Nolan',
    countryOfOrigin: 'US',
    originCountryName: 'Estados Unidos',
    theatricalCountries: [],
    ratings: {
      rottenTomatoesCritics: 94,
      rottenTomatoesAudience: 94,
      imdbScore: 9.0,
      imdbVotes: '2.9M',
      compositeScore: 9.2
    }
  },
  {
    id: 'spirited_away',
    title: 'El Viaje de Chihiro (Spirited Away)',
    overview: 'Chihiro, una niña de 10 años caprichosa, se adentra en un mundo gobernado por dioses, brujas y espíritus donde los humanos son transformados en bestias.',
    releaseYear: 2001,
    releaseDate: '2001-07-20',
    posterURL: 'https://image.tmdb.org/t/p/w500/39wmItIWsg5sZMyRUHLkWBcuVCM.jpg',
    backdropURL: 'https://image.tmdb.org/t/p/w1280/Ab8mkHmkYADjU7wQiOkia99GQI.jpg',
    genres: ['Animación', 'Fantasía', 'Aventura'],
    runtimeMinutes: 125,
    imdbId: 'tt0245429',
    director: 'Hayao Miyazaki',
    countryOfOrigin: 'JP',
    originCountryName: 'Japón',
    theatricalCountries: [],
    ratings: {
      rottenTomatoesCritics: 96,
      rottenTomatoesAudience: 96,
      imdbScore: 8.6,
      imdbVotes: '840K',
      compositeScore: 9.1
    }
  },
  {
    id: 'fast_furious_1',
    title: 'Rápidos y Furiosos (The Fast and the Furious)',
    overview: 'El oficial encubierto Brian O\'Conner se infiltra en las carreras clandestinas de Los Ángeles lideradas por Dominic Toretto.',
    releaseYear: 2001,
    releaseDate: '2001-06-22',
    posterURL: 'https://m.media-amazon.com/images/M/MV5BZGRiMDE1NTMtMThmZS00YjE4LWI1ODQtNjRkZGZlOTg2MGE1XkEyXkFqcGc@._V1_QL75_UX380_CR0,1,380,562_.jpg',
    backdropURL: 'https://image.tmdb.org/t/p/w1280/yF1EbAnkhUp1DEt5kWZ15Tgmhbt.jpg',
    genres: ['Acción', 'Crimen', 'Suspenso'],
    runtimeMinutes: 106,
    imdbId: 'tt0232500',
    director: 'Rob Cohen',
    countryOfOrigin: 'US',
    originCountryName: 'Estados Unidos',
    theatricalCountries: [],
    ratings: {
      rottenTomatoesCritics: 56,
      rottenTomatoesAudience: 74,
      imdbScore: 6.8,
      imdbVotes: '468K',
      compositeScore: 6.6
    }
  },
  {
    id: 'the_matrix',
    title: 'Matrix (The Matrix)',
    overview: 'Un hacker aprende de misteriosos rebeldes sobre la verdadera naturaleza de su realidad y su papel en la guerra contra sus controladores.',
    releaseYear: 1999,
    releaseDate: '1999-03-31',
    posterURL: 'https://image.tmdb.org/t/p/w500/f89U3ADr1oiB1s9GkdPOEpXUk5H.jpg',
    backdropURL: 'https://image.tmdb.org/t/p/w1280/7u3fhRw1Ns2qj5I5m4bS1W162D6.jpg',
    genres: ['Ciencia Ficción', 'Acción'],
    runtimeMinutes: 136,
    imdbId: 'tt0133093',
    director: 'Lilly & Lana Wachowski',
    countryOfOrigin: 'US',
    originCountryName: 'Estados Unidos',
    theatricalCountries: [],
    ratings: {
      rottenTomatoesCritics: 83,
      rottenTomatoesAudience: 85,
      imdbScore: 8.7,
      imdbVotes: '2.0M',
      compositeScore: 8.5
    }
  },
  {
    id: 'pulp_fiction',
    title: 'Pulp Fiction (Tiempos Violentos)',
    overview: 'Las vidas de dos matones de la mafia, un boxeador, la esposa de un gángster y dos bandidos se entrelazan en cuatro historias de violencia y redención en Los Ángeles.',
    releaseYear: 1994,
    releaseDate: '1994-10-14',
    posterURL: 'https://image.tmdb.org/t/p/w500/d5iIlFn5s0ImszYzBPb8JPIfbXD.jpg',
    backdropURL: 'https://image.tmdb.org/t/p/w1280/suaEOtk1N1sgg2MTM7oZd2cfVp3.jpg',
    genres: ['Crimen', 'Comedia Negra', 'Drama'],
    runtimeMinutes: 154,
    imdbId: 'tt0110912',
    director: 'Quentin Tarantino',
    countryOfOrigin: 'US',
    originCountryName: 'Estados Unidos',
    theatricalCountries: [],
    ratings: {
      rottenTomatoesCritics: 92,
      rottenTomatoesAudience: 96,
      imdbScore: 8.9,
      imdbVotes: '2.2M',
      compositeScore: 9.1
    }
  },
  {
    id: 'cinema_paradiso',
    title: 'Cinema Paradiso',
    overview: 'Un cineasta recuerda su infancia cuando se enamoró de las imágenes en el cine de su pueblo y entabló una profunda amistad con el proyeccionista Alfredo.',
    releaseYear: 1988,
    releaseDate: '1988-11-17',
    posterURL: 'https://image.tmdb.org/t/p/w500/8SRUuvvH5yTbw584w54ZJ4w.jpg',
    backdropURL: 'https://image.tmdb.org/t/p/w1280/6xKzbqcY3k8J3WbVv.jpg',
    genres: ['Drama', 'Romance'],
    runtimeMinutes: 155,
    imdbId: 'tt0095765',
    director: 'Giuseppe Tornatore',
    countryOfOrigin: 'IT',
    originCountryName: 'Italia',
    theatricalCountries: [],
    ratings: {
      rottenTomatoesCritics: 90,
      rottenTomatoesAudience: 97,
      imdbScore: 8.5,
      imdbVotes: '290K',
      compositeScore: 8.9
    }
  },
  {
    id: 'alien_1979',
    title: 'Alien: El Octavo Pasajero',
    overview: 'La tripulación de una nave espacial comercial entra en contacto con una forma de vida misteriosa y letal tras investigar una llamada de socorro en una luna lejana.',
    releaseYear: 1979,
    releaseDate: '1979-05-25',
    posterURL: 'https://image.tmdb.org/t/p/w500/vfrQk5IPloGg1v9Rzbh2Eg3VGyM.jpg',
    backdropURL: 'https://image.tmdb.org/t/p/w1280/AmR3JG1DYz52Wp5L9P6vV3B4.jpg',
    genres: ['Terror', 'Ciencia Ficción'],
    runtimeMinutes: 117,
    imdbId: 'tt0078748',
    director: 'Ridley Scott',
    countryOfOrigin: 'GB',
    originCountryName: 'Reino Unido',
    theatricalCountries: [],
    ratings: {
      rottenTomatoesCritics: 93,
      rottenTomatoesAudience: 94,
      imdbScore: 8.5,
      imdbVotes: '940K',
      compositeScore: 9.0
    }
  },
  {
    id: 'the_godfather_part_ii',
    title: 'El Padrino Parte II (The Godfather Part II)',
    overview: 'Se retratan los primeros pasos en el crimen del joven Vito Corleone en la Nueva York de los años 20 mientras en los 50 su hijo Michael expande el sindicato a Las Vegas, Hollywood y Cuba.',
    releaseYear: 1974,
    releaseDate: '1974-12-20',
    posterURL: 'https://image.tmdb.org/t/p/w500/nitJxV5GfaOB44VVOpVx2fOxnuT.jpg',
    backdropURL: 'https://image.tmdb.org/t/p/w1280/kGzFbGhp99zva6vdZ2yoVI5usnS.jpg',
    genres: ['Crimen', 'Drama'],
    runtimeMinutes: 202,
    imdbId: 'tt0071562',
    director: 'Francis Ford Coppola',
    countryOfOrigin: 'US',
    originCountryName: 'Estados Unidos',
    theatricalCountries: [],
    ratings: {
      rottenTomatoesCritics: 96,
      rottenTomatoesAudience: 97,
      imdbScore: 9.0,
      imdbVotes: '1.4M',
      compositeScore: 9.3
    }
  },
  {
    id: 'the_godfather',
    title: 'El Padrino (The Godfather)',
    overview: 'El envejecido patriarca de una dinastía del crimen organizado en Nueva York transfiere el control de su imperio clandestino a su reacio hijo menor.',
    releaseYear: 1972,
    releaseDate: '1972-03-24',
    posterURL: 'https://image.tmdb.org/t/p/w500/3bhkrj58Vtu7enYsRolD1fZdja1.jpg',
    backdropURL: 'https://image.tmdb.org/t/p/w1280/tmU7GeKVybMWFButWEGl2M4GeiP.jpg',
    genres: ['Crimen', 'Drama'],
    runtimeMinutes: 175,
    imdbId: 'tt0068646',
    director: 'Francis Ford Coppola',
    countryOfOrigin: 'US',
    originCountryName: 'Estados Unidos',
    theatricalCountries: [],
    ratings: {
      rottenTomatoesCritics: 97,
      rottenTomatoesAudience: 98,
      imdbScore: 9.2,
      imdbVotes: '2.0M',
      compositeScore: 9.5
    }
  },
  {
    id: '12_angry_men',
    title: '12 Hombres en Pugna (12 Angry Men)',
    overview: 'Un miembro de un jurado intenta evitar un error judicial convenciendo a los otros once colegas de que reconsideren las pruebas en un juicio por asesinato.',
    releaseYear: 1957,
    releaseDate: '1957-04-10',
    posterURL: 'https://image.tmdb.org/t/p/w500/ow3wq89wM8qd5X7hWKxiRfsFf9C.jpg',
    backdropURL: 'https://image.tmdb.org/t/p/w1280/qqHQsStV6exghCM7zbR8477w7H.jpg',
    genres: ['Drama', 'Misterio'],
    runtimeMinutes: 96,
    imdbId: 'tt0050083',
    director: 'Sidney Lumet',
    countryOfOrigin: 'US',
    originCountryName: 'Estados Unidos',
    theatricalCountries: [],
    ratings: {
      rottenTomatoesCritics: 100,
      rottenTomatoesAudience: 97,
      imdbScore: 9.0,
      imdbVotes: '870K',
      compositeScore: 9.4
    }
  },
  {
    id: 'latam_25376',
    title: 'El secreto de sus ojos',
    overview: 'Un consejero legal jubilado escribe una novela con la esperanza de encontrar cierre para uno de sus casos de homicidio no resueltos y para su amor no correspondido hacia su superior, recuerdos que aún le acechan décadas más tarde.',
    releaseYear: 2009,
    releaseDate: '2009-08-13',
    posterURL: 'https://image.tmdb.org/t/p/w500/5HshC8zHRk9JxGAuUHC8Q667c0l.jpg',
    backdropURL: 'https://image.tmdb.org/t/p/w1280/zaANf06OtqDJr5saqp5ymEkDPsi.jpg',
    genres: ['Drama', 'Misterio', 'Crimen'],
    runtimeMinutes: 129,
    imdbId: 'tt1305806',
    director: 'Juan José Campanella',
    countryOfOrigin: 'AR',
    originCountryName: 'Argentina',
    theatricalCountries: [],
    ratings: {
      rottenTomatoesCritics: 89,
      rottenTomatoesAudience: 93,
      imdbScore: 8.2,
      imdbVotes: '230K',
      compositeScore: 8.7
    }
  },
  {
    id: 'latam_55',
    title: 'Amores perros',
    overview: 'Un trágico accidente automovilístico en Ciudad de México entrelaza las vidas de tres personas de diferentes estratos sociales con algo en común: el amor, la pérdida y sus perros.',
    releaseYear: 2000,
    releaseDate: '2000-06-16',
    posterURL: 'https://image.tmdb.org/t/p/w500/uoObXx53SjSLLtAavMSIe02zizs.jpg',
    backdropURL: 'https://image.tmdb.org/t/p/w1280/iTkxwBriD9YKg4Q35qWEIlLXd6e.jpg',
    genres: ['Drama', 'Crimen', 'Suspenso'],
    runtimeMinutes: 154,
    imdbId: 'tt0245712',
    director: 'Alejandro González Iñárritu',
    countryOfOrigin: 'MX',
    originCountryName: 'México',
    theatricalCountries: [],
    ratings: {
      rottenTomatoesCritics: 93,
      rottenTomatoesAudience: 94,
      imdbScore: 8.1,
      imdbVotes: '260K',
      compositeScore: 8.8
    }
  },
  {
    id: 'latam_265195',
    title: 'Relatos salvajes',
    overview: 'Seis historias autoconclusivas que combinan comedia negra, intriga y violencia, llevando a sus personajes al límite absoluto cuando cruzan la línea entre la civilización y la barbarie.',
    releaseYear: 2014,
    releaseDate: '2014-08-21',
    posterURL: 'https://image.tmdb.org/t/p/w500/vimbRR5XdkMj7CqnzVN92Cla8jN.jpg',
    backdropURL: 'https://image.tmdb.org/t/p/w1280/dHnki2Dh6lbOtfksrh8H5lg08f5.jpg',
    genres: ['Comedia Negra', 'Drama', 'Suspenso'],
    runtimeMinutes: 122,
    imdbId: 'tt3011894',
    director: 'Damián Szifron',
    countryOfOrigin: 'AR',
    originCountryName: 'Argentina',
    theatricalCountries: [],
    ratings: {
      rottenTomatoesCritics: 94,
      rottenTomatoesAudience: 92,
      imdbScore: 8.1,
      imdbVotes: '210K',
      compositeScore: 8.8
    }
  },
  {
    id: 'latam_1417',
    title: 'El laberinto del fauno',
    overview: 'En la España de la posguerra, la joven Ofelia viaja con su madre al campamento de su padrastro militar. Allí descubre un misterioso laberinto custodiado por un fauno que le encomienda tres peligrosas misiones.',
    releaseYear: 2006,
    releaseDate: '2006-10-11',
    posterURL: 'https://image.tmdb.org/t/p/w500/cxVlgYbn1GAdVhuBjM2jFiavfRp.jpg',
    backdropURL: 'https://image.tmdb.org/t/p/w1280/6G6nqSW9S7EHA9HrYl0Z8uo2H7f.jpg',
    genres: ['Fantasía Oscura', 'Drama', 'Guerra'],
    runtimeMinutes: 118,
    imdbId: 'tt0457430',
    director: 'Guillermo del Toro',
    countryOfOrigin: 'MX',
    originCountryName: 'México',
    theatricalCountries: [],
    ratings: {
      rottenTomatoesCritics: 95,
      rottenTomatoesAudience: 91,
      imdbScore: 8.2,
      imdbVotes: '710K',
      compositeScore: 8.9
    }
  },
  {
    id: 'latam_598',
    title: 'Ciudad de Dios (Cidade de Deus)',
    overview: 'En las favelas de Río de Janeiro durante los años 60 a 80, dos jóvenes eligen caminos opuestos: uno sueña con ser fotógrafo mientras el otro se convierte en un implacable jefe narco.',
    releaseYear: 2002,
    releaseDate: '2002-08-30',
    posterURL: 'https://image.tmdb.org/t/p/w500/zYjngc6yGUO1IEuAwk0yAhg8CKh.jpg',
    backdropURL: 'https://image.tmdb.org/t/p/w1280/uvitbjFU4JqvMwIkMWHp69bmUzG.jpg',
    genres: ['Crimen', 'Drama'],
    runtimeMinutes: 130,
    imdbId: 'tt0317248',
    director: 'Fernando Meirelles',
    countryOfOrigin: 'BR',
    originCountryName: 'Brasil',
    theatricalCountries: [],
    ratings: {
      rottenTomatoesCritics: 91,
      rottenTomatoesAudience: 97,
      imdbScore: 8.6,
      imdbVotes: '820K',
      compositeScore: 9.1
    }
  },
  {
    id: 'latam_426426',
    title: 'Roma',
    overview: 'Una emotiva carta de amor a las mujeres que criaron al director, ambientada en el barrio Roma de la Ciudad de México a inicios de los 70, narrando la vida de Cleo, empleada doméstica de una familia acomodada.',
    releaseYear: 2018,
    releaseDate: '2018-11-21',
    posterURL: 'https://image.tmdb.org/t/p/w500/veWGVw33lnifG10fpkz3QmimVaI.jpg',
    backdropURL: 'https://image.tmdb.org/t/p/w1280/zl9uqCl5iUSb50sTk2BPzw6bJnU.jpg',
    genres: ['Drama'],
    runtimeMinutes: 135,
    imdbId: 'tt6155172',
    director: 'Alfonso Cuarón',
    countryOfOrigin: 'MX',
    originCountryName: 'México',
    theatricalCountries: [],
    ratings: {
      rottenTomatoesCritics: 96,
      rottenTomatoesAudience: 72,
      imdbScore: 7.7,
      imdbVotes: '170K',
      compositeScore: 8.2
    }
  },
  {
    id: 'latam_28644',
    title: 'La teta asustada',
    overview: 'Fausta sufre una condición transmitida por la leche materna de mujeres violentadas durante el conflicto armado en Perú. Tras la muerte de su madre, debe enfrentar sus temores más profundos en Lima.',
    releaseYear: 2009,
    releaseDate: '2009-02-13',
    posterURL: 'https://image.tmdb.org/t/p/w500/pjlfAZXBIZLrBK4dcYtX0WWatoo.jpg',
    backdropURL: 'https://image.tmdb.org/t/p/w1280/u1N34argMlLDuS7zUIekPVk9Imz.jpg',
    genres: ['Drama', 'Misterio'],
    runtimeMinutes: 95,
    imdbId: 'tt1347077',
    director: 'Claudia Llosa',
    countryOfOrigin: 'PE',
    originCountryName: 'Perú',
    theatricalCountries: [],
    ratings: {
      rottenTomatoesCritics: 82,
      rottenTomatoesAudience: 76,
      imdbScore: 7.3,
      imdbVotes: '15K',
      compositeScore: 7.7
    }
  },
  {
    id: 'latam_511425',
    title: 'Wiñaypacha',
    overview: 'Willka y Phaxsi, una anciana pareja aimara de más de 80 años, viven en el aislamiento del altiplano andino a más de cinco mil metros de altura, esperando el regreso de su único hijo.',
    releaseYear: 2018,
    releaseDate: '2018-04-19',
    posterURL: 'https://image.tmdb.org/t/p/w500/ceYrImnaGNr4hv6srr5silgfYHz.jpg',
    backdropURL: 'https://image.tmdb.org/t/p/w1280/wlYPCnqZswU8uueilnpq39lWVap.jpg',
    genres: ['Drama'],
    runtimeMinutes: 86,
    imdbId: 'tt7241838',
    director: 'Óscar Catacora',
    countryOfOrigin: 'PE',
    originCountryName: 'Perú',
    theatricalCountries: [],
    ratings: {
      rottenTomatoesCritics: 90,
      rottenTomatoesAudience: 88,
      imdbScore: 7.6,
      imdbVotes: '4K',
      compositeScore: 8.2
    }
  },
  {
    id: 'latam_336808',
    title: 'El abrazo de la serpiente',
    overview: 'A lo largo de cuatro décadas, Karamakate, el último chamán superviviente de su pueblo amazónico, guía a dos científicos occidentales en la búsqueda de la sagrada y curativa planta yakruna.',
    releaseYear: 2015,
    releaseDate: '2015-05-25',
    posterURL: 'https://image.tmdb.org/t/p/w500/iLcCVKuePGh7mgUndk59VUyctKJ.jpg',
    backdropURL: 'https://image.tmdb.org/t/p/w1280/zhXmJnPIoncBQ2TY8IEWc4s9vbh.jpg',
    genres: ['Aventura', 'Drama', 'Historia'],
    runtimeMinutes: 125,
    imdbId: 'tt4285496',
    director: 'Ciro Guerra',
    countryOfOrigin: 'CO',
    originCountryName: 'Colombia',
    theatricalCountries: [],
    ratings: {
      rottenTomatoesCritics: 96,
      rottenTomatoesAudience: 84,
      imdbScore: 7.8,
      imdbVotes: '40K',
      compositeScore: 8.4
    }
  },
  {
    id: 'latam_12086',
    title: 'Machuca',
    overview: 'En el convulsionado Santiago de Chile de 1973, dos niños de clases sociales opuestas forjan una amistad inolvidable en un colegio privado experimental justo antes del golpe de estado.',
    releaseYear: 2004,
    releaseDate: '2004-02-24',
    posterURL: 'https://image.tmdb.org/t/p/w500/oBDAEhTLWwflrqRZMsrOisqkVSb.jpg',
    backdropURL: 'https://image.tmdb.org/t/p/w1280/xPt9uunKOZ8EC2xukQbkSDh45oq.jpg',
    genres: ['Drama', 'Historia'],
    runtimeMinutes: 121,
    imdbId: 'tt0378284',
    director: 'Andrés Wood',
    countryOfOrigin: 'CL',
    originCountryName: 'Chile',
    theatricalCountries: [],
    ratings: {
      rottenTomatoesCritics: 89,
      rottenTomatoesAudience: 90,
      imdbScore: 7.7,
      imdbVotes: '18K',
      compositeScore: 8.1
    }
  },
  {
    id: 'latam_99',
    title: 'Todo sobre mi madre',
    overview: 'Tras la trágica muerte de su hijo en Madrid, Manuela viaja a Barcelona en busca del padre que nunca supo de la existencia del muchacho, encontrando una comunidad de mujeres resilientes.',
    releaseYear: 1999,
    releaseDate: '1999-04-16',
    posterURL: 'https://image.tmdb.org/t/p/w500/evvT3HUwoQYoPQXWFO10R6AvhxG.jpg',
    backdropURL: 'https://image.tmdb.org/t/p/w1280/tilClWjFZeUTGJu0pxgF72fvUmN.jpg',
    genres: ['Drama', 'Comedia'],
    runtimeMinutes: 101,
    imdbId: 'tt0185125',
    director: 'Pedro Almodóvar',
    countryOfOrigin: 'ES',
    originCountryName: 'España',
    theatricalCountries: [],
    ratings: {
      rottenTomatoesCritics: 98,
      rottenTomatoesAudience: 90,
      imdbScore: 7.8,
      imdbVotes: '105K',
      compositeScore: 8.5
    }
  }
];

export const CURATED_MOVIES: Movie[] = RAW_MOVIES.map(movie => {
  const comp = calculateCompositeScore(movie.ratings);
  return {
    ...movie,
    ratings: {
      ...movie.ratings,
      compositeScore: comp
    }
  };
});

export const DEFAULT_USER: User = {
  id: 'user_alex_101',
  email: 'cinefilo@apple.com',
  displayName: 'Alex Rivera',
  username: '@alexrivera',
  bio: 'Crítico entusiasta de cine de autor, sci-fi y experiencias en gran pantalla 🎬 70mm lover.',
  avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop&q=80',
  isPremium: false,
  subscriptionPlan: 'base',
  subscriptionPrice: 'S/ 14.90 / mes',
  location: AVAILABLE_CITIES[0], // Lima por defecto
  createdAt: '2024-01-15T08:00:00Z'
};

export const INITIAL_FRIENDS: Friend[] = [
  {
    id: 'friend_valeria',
    displayName: 'Valeria Gómez',
    username: '@valeriacine',
    avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&auto=format&fit=crop&q=80',
    isMutual: true,
    mutualMoviesCount: 14,
    bio: 'Devoradora de festivales (Cannes, Sundance). Amante del cine asiático y terror andino.'
  },
  {
    id: 'friend_lucas',
    displayName: 'Lucas Romero',
    username: '@lucasromero',
    avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200&auto=format&fit=crop&q=80',
    isMutual: true,
    mutualMoviesCount: 18,
    bio: 'Fotografía cinematográfica y ciencia ficción dura. Denis Villeneuve y Kubrick siempre.'
  },
  {
    id: 'friend_marcos',
    displayName: 'Marcos Silva',
    username: '@marcoss',
    avatarUrl: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=200&auto=format&fit=crop&q=80',
    isMutual: true,
    mutualMoviesCount: 9,
    bio: 'Guionista aficionado. Fanático de Coppola, Scorsese y el cine noir de los 70s.'
  },
  {
    id: 'friend_sofia',
    displayName: 'Sofía Alarcón',
    username: '@sofia_film',
    avatarUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=200&auto=format&fit=crop&q=80',
    isMutual: true,
    mutualMoviesCount: 11,
    bio: 'Montajista y documentalista en formación. Cine latinoamericano contemporáneo.'
  }
];

export const INITIAL_REVIEWS: Review[] = [
  {
    id: 'rev_ekeko_1',
    movieId: 'ekeko_pe_2026',
    movieTitle: 'Ekeko: El Dios de la Abundancia',
    moviePosterUrl: 'https://images.unsplash.com/photo-1509281373149-e957c6296406?w=500&auto=format&fit=crop&q=80',
    movieReleaseYear: 2026,
    userId: 'friend_valeria',
    userName: 'Valeria Gómez',
    userAvatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&auto=format&fit=crop&q=80',
    rating: 4.5,
    comment: '¡Extraordinario terror folclórico andino! El diseño sonoro en salas con Dolby Atmos te eriza la piel. La tensión ancestral está construida con maestría.',
    likesCount: 12,
    helpfulCount: 8,
    isCommunity: false,
    createdAt: '2026-10-28T19:30:00Z',
    comments: [
      {
        id: 'c1',
        reviewId: 'rev_ekeko_1',
        userId: 'user_alex_101',
        userName: 'Alex Rivera',
        text: 'Totalmente de acuerdo, la escena en las minas es de lo mejor del cine latinoamericano este año.',
        createdAt: '2026-10-28T20:15:00Z'
      }
    ]
  },
  {
    id: 'rev_dune_1',
    movieId: 'dune_part_two',
    movieTitle: 'Dune: Parte Dos',
    moviePosterUrl: 'https://image.tmdb.org/t/p/w500/8b8R8l88Qje9dn9OE8PY05Nxl1X.jpg',
    movieReleaseYear: 2024,
    userId: 'friend_lucas',
    userName: 'Lucas Romero',
    userAvatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200&auto=format&fit=crop&q=80',
    rating: 5.0,
    comment: 'Una obra cumbre de la ciencia ficción contemporánea. La secuencia en Giedi Prime en blanco y negro infrarrojo es pura poesía visual. Austin Butler inolvidable.',
    likesCount: 24,
    helpfulCount: 15,
    isCommunity: false,
    createdAt: '2026-10-26T14:10:00Z',
    comments: []
  },
  {
    id: 'rev_godfather_1',
    movieId: 'the_godfather',
    movieTitle: 'El Padrino',
    moviePosterUrl: 'https://image.tmdb.org/t/p/w500/3bhkrj58Vtu7enYsRolD1fZdja1.jpg',
    movieReleaseYear: 1972,
    userId: 'friend_marcos',
    userName: 'Marcos Silva',
    userAvatarUrl: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=200&auto=format&fit=crop&q=80',
    rating: 5.0,
    comment: 'No envejece ni un solo segundo. Cada plano de Gordon Willis en penumbra y cada silencio de Marlon Brando dictan cátedra de cómo hacer historia en el cine.',
    likesCount: 31,
    helpfulCount: 22,
    isCommunity: false,
    createdAt: '2026-10-22T11:00:00Z',
    comments: []
  }
];

export const INITIAL_GROUPS: MovieGroup[] = [
  {
    id: 'grp_cine_peruano',
    name: 'Cine Peruano & Latinoamericano',
    description: 'Debates de estrenos, cine de autor, retrospectivas y cartelera regional.',
    iconEmoji: '🇵🇪',
    creatorId: 'user_alex_101',
    creatorName: 'Alex Rivera',
    inviteCode: 'CINE-PERU',
    messagesCount: 42,
    membersCount: 8,
    createdAt: '2026-09-01T10:00:00Z'
  },
  {
    id: 'grp_clasicos_70mm',
    name: 'Clásicos Ocultos & 70mm',
    description: 'Joyas restauradas, cine en celuloide y reestrenos en salas especiales.',
    iconEmoji: '🎞️',
    creatorId: 'friend_lucas',
    creatorName: 'Lucas Romero',
    inviteCode: '70MM-CLUB',
    messagesCount: 68,
    membersCount: 12,
    createdAt: '2026-08-15T14:30:00Z'
  },
  {
    id: 'grp_scifi_future',
    name: 'Horizontes Sci-Fi',
    description: 'Todo sobre ciencia ficción dura, distopías y mundos especulativos.',
    iconEmoji: '🚀',
    creatorId: 'friend_valeria',
    creatorName: 'Valeria Gómez',
    inviteCode: 'SCIFI-NOW',
    messagesCount: 51,
    membersCount: 9,
    createdAt: '2026-09-10T18:00:00Z'
  }
];


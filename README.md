# MovieSocial: Aplicación iOS de Cine & Amigos

Aplicación nativa para **iOS (iOS 17+)** construida con **Swift 6** y **SwiftUI**, diseñada con una filosofía **minimalista**, enfocada exclusivamente en el descubrimiento de películas (estrenos y clásicos de cualquier época), la agregación de calificaciones oficiales de **Rotten Tomatoes** (Tomatometer y Audiencia) e **IMDb**, y la conexión con amigos para compartir puntuaciones y micro-reseñas sin ruido, anuncios ni secciones de noticias.

---

## 🌟 Características Principales

1. **Autenticación Nativa y Segura:**
   - **Sign in with Apple** (utilizando `AuthenticationServices`, compatible con los estándares de la App Store Review Guideline 4.8).
   - **Sign in with Google** (integración lista para producción y mock para entorno de pruebas).
2. **Catálogo Cinematográfico Completo:**
   - **Cartelera Local por Ciudad:** Filtro y selector interactivo de ciudad activa (Madrid, Barcelona, CDMX, Bogotá, Buenos Aires, Santiago, Lima) con indicador de disponibilidad en cines físicos locales, salas y horarios.
   - **Clásicos Históricos por Cruce de Ratings:** Obras maestras de toda la historia del cine ordenadas por cruce ponderado de puntuaciones y filtro por décadas (`≤ 60s`, `70s`, `80s`, `90s`, `2000s`, `2010s`, `Todas`).
   - **Búsqueda Instantánea:** Filtrado ágil por título, género o año.
3. **Puntuaciones Críticas Unificadas:**
   - ✨ **MovieScore (Score Cruce Ponderado):** Cruce normalizado en base 10 (50% IMDb + 30% Rotten Tomatoes Críticos + 20% Audiencia).
   - 🍅 **Rotten Tomatoes:** Puntuación de críticos (*Tomatometer %*) y de audiencia (*Popcorn %*).
   - ⭐ **IMDb:** Calificación numérica sobre 10 (ej. `9.2/10`) y volumen de votos.
   - 👥 **Círculo de Amigos:** Promedio ponderado exclusivo de las personas que sigues.
4. **Capa Social Limpia (Sin Noticias):**
   - Feed de actividad cronológico de reseñas escritas por tus amigos.
   - Detalle de película con sección destacada *"Qué opinan tus amigos"*.
   - Modal minimalista para registrar puntuación (1 a 5 estrellas con medios puntos) y opinión personal.
   - Búsqueda y adición de amigos mediante nombre de usuario (`@usuario`).
5. **Mensajería y Chats Directos (One-to-One) & Cineclubs:**
   - Sección dedicada de **Chats 1 a 1** entre cinéfilos al estilo WhatsApp Dark.
   - Selector segmentado unificado para alternar entre **Chats 1 a 1** y **Cineclubs (Grupos)**.
   - Recomendación y compartición de películas en directo dentro del chat privado con póster, sinopsis, año y acceso a ficha.
   - Botón directo para iniciar chat 1 a 1 desde el perfil y lista de amigos.
6. **Diseño Visual Minimalista (Cinema Dark):**
   - Paleta monocromática OLED (`#0B0C0E`), tipografía limpia y foco absoluto en los pósters y opiniones.
   - Cero secciones de noticias, publicidad o algoritmos invasivos.

---

## 🏗 Arquitectura de Software

La aplicación sigue los principios de **Clean Architecture + MVVM** con **Swift Concurrency (Swift 6)**:

```text
MovieSocialApp/
├── Package.swift               # Manifiesto Swift Package multi-plataforma
├── test.sh                     # Script para ejecutar suite de pruebas
├── Sources/
│   ├── App/
│   │   ├── MovieSocialApp.swift # Punto de entrada principal
│   │   ├── RootTabView.swift    # Navegación por pestañas (Cine, Amigos, Perfil)
│   │   └── AppEnvironment.swift # Contenedor de Inyección de Dependencias
│   ├── Core/
│   │   └── DesignSystem/
│   │       ├── Theme.swift      # Tokens de color, espaciado y bordes
│   │       └── Components/
│   │           ├── RatingBadgesView.swift      # Badge unificado RT + IMDb + Amigos
│   │           ├── MoviePosterCard.swift       # Tarjeta de póster minimalista
│   │           └── MinimalistRatingPicker.swift# Selector de estrellas y medios puntos
│   └── Features/
│       ├── Auth/
│       │   ├── Domain/ (User, AuthServiceProtocol)
│       │   ├── Services/ (AppleAuthService, GoogleAuthService, MockAuthService)
│       │   └── Presentation/ (LoginView, AuthViewModel)
│       ├── Movies/
│       │   ├── Domain/ (Movie, ExternalRatings, MovieRepositoryProtocol, UseCases)
│       │   ├── Data/ (MovieRepositoryImpl actor, TMDBMovieDTO, OMDbRatingDTO)
│       │   └── Presentation/ (MovieCatalogView, MovieDetailView, ViewModels)
│       ├── Social/
│       │   ├── Domain/ (Friend, Review, SocialRepositoryProtocol, UseCases)
│       │   ├── Data/ (SocialRepositoryImpl actor)
│       │   └── Presentation/ (FriendsFeedView, FriendsListView, AddReviewSheetView, SocialViewModel)
│       ├── DirectChat/
│       │   ├── Domain/ (DirectConversation, DirectMessage, DirectChatRepositoryProtocol, UseCases)
│       │   ├── Data/ (DirectChatRepositoryImpl actor)
│       │   └── Presentation/ (ChatsMainView, DirectChatListView, DirectChatDetailView, DirectChatViewModel)
│       ├── Groups/
│       │   ├── Domain/ (MovieGroup, GroupMessage, GroupRepositoryProtocol, UseCases)
│       │   ├── Data/ (GroupRepositoryImpl actor)
│       │   └── Presentation/ (GroupsListView, GroupDetailView, GroupsViewModel)
│       └── Profile/
│           └── Presentation/ (ProfileView, ProfileViewModel)
└── Tests/
    └── MovieSocialAppTests/
        ├── TMDBMappingTests.swift
        ├── OMDbMappingTests.swift
        ├── MovieRepositoryTests.swift
        ├── SocialUseCasesTests.swift
        └── AuthViewModelTests.swift
```

---

## 🚀 Cómo Abrir y Ejecutar el Proyecto

### Opción 1: Abrir en Xcode (Recomendado para Simulador iOS)
1. Abre Xcode en tu Mac.
2. Selecciona **File > Open...** y elige la carpeta `/Users/vctormnzn/.gemini/antigravity/scratch/MovieSocialApp`.
3. Xcode detectará automáticamente `Package.swift`.
4. Selecciona el esquema `MovieSocialApp` y cualquier simulador de iOS (ej. **iPhone 16 Pro** o **iOS Simulator**).
5. Pulsa **Cmd + R** para compilar y ejecutar, o **Cmd + U** para ejecutar las pruebas.

### Opción 2: Ejecutar Pruebas Automatizadas desde Terminal
El proyecto incluye un script de prueba que ejecuta las 13 pruebas automatizadas:
```bash
cd /Users/vctormnzn/.gemini/antigravity/scratch/MovieSocialApp
./test.sh
```

---

## 🔑 Configuración de APIs de TMDB y OMDb

Por defecto, la aplicación incluye un catálogo curado offline con datos reales (estrenos como *Dune 2*, *Inside Out 2*, *Deadpool & Wolverine*, y clásicos como *El Padrino*, *Pulp Fiction*, *12 Angry Men* y *El Viaje de Chihiro*) con puntuaciones auténticas de Rotten Tomatoes e IMDb.

Para conectar tus propias claves de API de producción:
1. En `AppEnvironment.swift`, instancia el repositorio proporcionando tus claves:
   ```swift
   let movieRepository = MovieRepositoryImpl(
       tmdbApiKey: "TU_TMDB_API_KEY",
       omdbApiKey: "TU_OMDB_API_KEY"
   )
   ```
2. El repositorio llamará a TMDB para obtener el catálogo y los pósters, extraerá el identificador `imdb_id` y consultará a OMDb para cargar dinámicamente los porcentajes de Rotten Tomatoes y la puntuación de IMDb.


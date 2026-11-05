# MovieSocial: Plataforma Cinéfila & Red Social

Plataforma Web moderna y responsive construida con la misma arquitectura de **gestion-3d-app** y **gestion-bg-app**:
- **Framework:** **Next.js 15 (App Router)**
- **ORM & Base de Datos:** **Prisma ORM** conectado directamente a **Neon DB (PostgreSQL Serverless)** mediante `DATABASE_URL` en `.env`
- **Server Actions & Lógica:** `src/actions/` con `"use server"` para consultas y mutaciones directas de datos
- **Estilos:** **Tailwind CSS + shadcn/ui** con paleta **Cinema Dark OLED** (`#0B0C0E`), tipografía limpia y acentos dorados (`#E5A93C`)
- **Iconos:** **Lucide React**

---

## 🌟 Características

1. **Cartelera Local por Ciudad:**
   - Selector interactivo de ciudad (Madrid, Barcelona, Ciudad de México, Bogotá, Buenos Aires, Santiago, Lima) con salas y horarios reales (IMAX, VOSE, Dolby Atmos).
2. **Clásicos Históricos por MovieScore:**
   - Obras maestras de toda la historia ordenadas por cruce ponderado (50% IMDb + 30% Rotten Tomatoes Críticos + 20% Audiencia) con filtro por décadas (`≤ 60s`, `70s`, `80s`, `90s`, `2000s`, `2010s`, `Todas`).
3. **Ficha de Película & Reseñas:**
   - Desglose de calificaciones oficiales (**Tomatometer**, **Popcornmeter**, **IMDb** y **MovieScore**), salas de proyección y opiniones de amigos.
   - Calificador interactivo con estrellas de 1 a 5 con **medios puntos** (0.5 a 5.0).
4. **Feed Social & Conexiones:**
   - Feed cronológico de reseñas escritas por tu círculo de amigos con comentarios interactivos y likes.
   - Directorio de amigos y buscador por `@usuario`.
5. **Chats 1 a 1 & Cineclubs:**
   - Mensajería estilo WhatsApp Dark con soporte para compartir tarjetas de películas recomendadas dentro de la conversación.
   - Cineclubs comunitarios con código de invitación (`CINE-XXXXXX`).
6. **Perfil & Cinéfilo Pro:**
   - Estadísticas, edición de datos/ciudad y membresía Pro.

---

## 🏗 Arquitectura del Proyecto (Igual a gestion-3d-app / gestion-bg-app)

```text
MovieSocialApp/
├── .env                      # Variables de entorno (DATABASE_URL para Neon DB PostgreSQL)
├── components.json           # Configuración de shadcn/ui
├── next.config.ts            # Configuración de Next.js
├── tailwind.config.js        # Tokens de tema Cinema Dark
├── postcss.config.mjs        # Configuración PostCSS
├── prisma/
│   └── schema.prisma         # Modelos de Prisma conectados a PostgreSQL (Neon DB)
├── src/
│   ├── app/
│   │   ├── layout.tsx        # RootLayout con viewport, metadatos y fuente
│   │   ├── page.tsx          # Página principal interactiva con navegación por pestañas
│   │   └── globals.css       # Estilos globales y scrollbars oscuros
│   ├── actions/              # Server Actions (Prisma ORM)
│   │   ├── movies.ts         # Consultas de cartelera y clásicos
│   │   ├── reviews.ts        # Consultas y creación de reseñas
│   │   ├── friends.ts        # Amigos y conexiones
│   │   ├── chats.ts          # Chats 1 a 1 y cineclubs
│   │   └── users.ts          # Datos de usuario y perfil
│   ├── lib/
│   │   ├── prisma.ts         # Singleton de PrismaClient
│   │   └── utils.ts          # Helper 'cn' (clsx + tailwind-merge) y formateadores
│   ├── components/           # Componentes modulares
│   │   ├── common/           # Navbar, RatingBadges, StarRatingPicker
│   │   └── movies/           # MovieCard, MovieDetailModal, AddReviewModal
│   ├── views/                # Vistas principales
│   │   ├── CatalogView.tsx   # Cartelera y Clásicos
│   │   ├── FriendsFeedView.tsx # Feed de reseñas
│   │   ├── ChatsView.tsx     # Mensajería y Cineclubs
│   │   └── ProfileView.tsx   # Perfil y membresía Pro
│   └── types/                # Interfaces TypeScript y cálculo de MovieScore
├── dev.sh                    # Iniciar servidor de desarrollo (puerto 3000)
├── start.sh                  # Compilar y arrancar producción local
└── Dockerfile                # Despliegue en contenedor Docker
```

---

## 🚀 Cómo Ejecutar la Aplicación

### Modo Desarrollo (Puerto 3000)
```bash
npm run dev
# o usando el script:
./dev.sh
```
Abre en tu navegador: **[http://localhost:3000](http://localhost:3000)**

### Modo Producción
```bash
npm run build
npm run start
# o usando el script:
./start.sh
```

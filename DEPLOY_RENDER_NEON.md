# 🚀 Guía de Despliegue: Render + Neon DB (Gratis)

Esta guía explica cómo poner en marcha tu Base de Datos en **Neon DB** y la API REST en **Render** sin costo y en menos de 5 minutos.

---

## Paso 1: Crear tu Base de Datos en Neon DB (PostgreSQL)

1. Ve a [https://console.neon.tech](https://console.neon.tech) e inicia sesión con tu cuenta de GitHub o Google.
2. Haz clic en **Create Project**:
   - **Project name**: `moviesocial-db`
   - **Region**: Selecciona la más cercana (ej. `US East (Ohio)`).
   - **Postgres version**: 16 o 17 (por defecto).
3. Haz clic en **Create Project**.
4. En el dashboard verás la sección **Connection Details**:
   - Asegúrate de que esté seleccionado `Postgres` y `Pooled connection` (o `Direct`).
   - Copia la **Connection string** (ejemplo):
     ```text
     postgresql://usuario:password@ep-ejemplo.us-east-2.aws.neon.tech/moviesocial?sslmode=require
     ```
   *(Guarda este enlace para el Paso 3).*

---

## Paso 2: Crear las Tablas en Neon DB (1 solo clic)

1. En el menú lateral izquierdo de tu proyecto en Neon, haz clic en **SQL Editor**.
2. Abre el archivo [`backend/neon_schema.sql`](backend/neon_schema.sql) de este repositorio.
3. Copia todo su contenido, pégalo en el editor de Neon y haz clic en el botón verde **Run**.
4. ¡Listo! En la pestaña **Tables** de Neon verás creadas:
   - `users`
   - `friends`
   - `reviews`
   - `review_comments`
   - `movie_groups`
   - `group_messages`
   - `direct_conversations`
   - `direct_messages`

---

## Paso 3: Desplegar la API en Render (100% Gratis)

1. Ve a [https://render.com](https://render.com) e inicia sesión con GitHub.
2. Haz clic en **New +** y selecciona **Web Service**.
3. Conecta tu repositorio de GitHub donde está este proyecto (`MovieSocialApp`).
4. Configura el servicio:
   - **Name**: `moviesocial-api`
   - **Region**: `Ohio (US East)` (la misma que elegiste en Neon para menor latencia).
   - **Root Directory**: `backend`
   - **Runtime**: `Python 3`
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `python server.py`
   - **Instance Type**: `Free` ($0/mes)
5. En la sección **Environment Variables**, agrega:
   - **Key**: `DATABASE_URL`
   - **Value**: *(Pega aquí la Connection string de Neon que copiaste en el Paso 1)*.
   - **Key**: `PORT`
   - **Value**: `8080`
6. Haz clic en **Create Web Service**.
7. Render compilará tu aplicación y en unos minutos te entregará tu URL segura con HTTPS:
   ```text
   https://moviesocial-api.onrender.com
   ```

---

## Paso 4: Conectar tu Aplicación iOS

Una vez que Render te dé tu URL (ej. `https://moviesocial-api.onrender.com`), solo tienes que actualizar la URL en la app:

### Opción A (Por código en Swift):
En `MovieSocialAPIClient.swift`:
```swift
// Cambiar el entorno a Render Cloud:
MovieSocialAPIClient.shared.setRenderURLString("https://moviesocial-api.onrender.com")
```

### Opción B (Visual desde la app en el Simulador):
En la pantalla **Mi Perfil**, dentro de la sección **SERVICIOS REST Y BASE DE DATOS**, la app detecta automáticamente el estado y puedes configurar la URL de Render.

---

## 🛠️ Endpoints Disponibles en tu API Desplegada

| Método | Endpoint | Descripción |
| :--- | :--- | :--- |
| **GET** | `/api/health` | Estado del servidor y recuentos de Neon DB |
| **GET** | `/api/reviews` | Lista de reseñas filtrables por `movieId` o `userId` |
| **GET** | `/api/friends` | Lista de amigos sincronizados |
| **GET** | `/api/groups` | Cineclubs activos |
| **GET** | `/api/groups/:id/messages` | Mensajes del cineclub |
| **POST** | `/api/reviews` | Crear nueva reseña (1 por usuario/película) |
| **POST** | `/api/friends` | Agregar amigo |
| **POST** | `/api/groups` | Crear nuevo cineclub con código |
| **POST** | `/api/groups/:id/messages` | Enviar mensaje al cineclub |
| **PUT** | `/api/reviews/:id` | Editar reseña existente |
| **PUT** | `/api/users/:id` | Actualizar perfil de usuario |
| **DELETE** | `/api/reviews/:id` | Eliminar reseña |
| **DELETE** | `/api/friends/:id` | Eliminar amigo |

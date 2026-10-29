-- ==========================================================
-- MovieSocialApp - Schema para Neon DB (PostgreSQL)
-- Ejecutar en el SQL Editor de tu proyecto en https://console.neon.tech
-- ==========================================================

-- 1. Tabla de Usuarios
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(100) PRIMARY KEY,
    email VARCHAR(255),
    display_name VARCHAR(255) NOT NULL,
    username VARCHAR(100) NOT NULL,
    bio TEXT,
    avatar_url TEXT,
    auth_provider VARCHAR(50) DEFAULT 'apple',
    is_premium BOOLEAN DEFAULT FALSE,
    city VARCHAR(100),
    country VARCHAR(100),
    country_code VARCHAR(10),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Tabla de Amigos / Relaciones Sociales
CREATE TABLE IF NOT EXISTS friends (
    id VARCHAR(100) PRIMARY KEY,
    display_name VARCHAR(255) NOT NULL,
    username VARCHAR(100) NOT NULL,
    avatar_url TEXT,
    is_mutual BOOLEAN DEFAULT TRUE,
    mutual_movies_count INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. Tabla de Reseñas y Críticas Cinéfilas
CREATE TABLE IF NOT EXISTS reviews (
    id VARCHAR(100) PRIMARY KEY,
    movie_id VARCHAR(100) NOT NULL,
    movie_title VARCHAR(255) NOT NULL,
    movie_poster_url TEXT,
    movie_release_year INT,
    user_id VARCHAR(100) NOT NULL,
    user_name VARCHAR(255) NOT NULL,
    user_avatar_url TEXT,
    rating NUMERIC(3, 1) NOT NULL,
    comment TEXT,
    likes_count INT DEFAULT 0,
    helpful_count INT DEFAULT 0,
    is_community BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_reviews_movie_id ON reviews(movie_id);
CREATE INDEX IF NOT EXISTS idx_reviews_user_id ON reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_reviews_created_at ON reviews(created_at DESC);

-- 4. Comentarios en Reseñas
CREATE TABLE IF NOT EXISTS review_comments (
    id VARCHAR(100) PRIMARY KEY,
    review_id VARCHAR(100) NOT NULL REFERENCES reviews(id) ON DELETE CASCADE,
    user_id VARCHAR(100) NOT NULL,
    user_name VARCHAR(255) NOT NULL,
    user_avatar_url TEXT,
    text TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_comments_review_id ON review_comments(review_id);

-- 5. Cineclubs / Grupos de Debate
CREATE TABLE IF NOT EXISTS movie_groups (
    id VARCHAR(100) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    icon_emoji VARCHAR(20) DEFAULT '🎬',
    creator_id VARCHAR(100) NOT NULL,
    creator_name VARCHAR(255) NOT NULL,
    invite_code VARCHAR(50) UNIQUE,
    messages_count INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_groups_invite_code ON movie_groups(invite_code);

-- 6. Mensajes de Cineclubs (Estilo WhatsApp)
CREATE TABLE IF NOT EXISTS group_messages (
    id VARCHAR(100) PRIMARY KEY,
    group_id VARCHAR(100) NOT NULL REFERENCES movie_groups(id) ON DELETE CASCADE,
    user_id VARCHAR(100) NOT NULL,
    user_name VARCHAR(255) NOT NULL,
    text TEXT NOT NULL,
    message_type VARCHAR(50) DEFAULT 'text',
    shared_movie_id VARCHAR(100),
    shared_movie_title VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_group_messages_group ON group_messages(group_id, created_at ASC);

-- 7. Conversaciones y Mensajes Directos (1 a 1)
CREATE TABLE IF NOT EXISTS direct_conversations (
    id VARCHAR(100) PRIMARY KEY,
    participant_id VARCHAR(100) NOT NULL,
    unread_count INT DEFAULT 0,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS direct_messages (
    id VARCHAR(100) PRIMARY KEY,
    conversation_id VARCHAR(100) NOT NULL REFERENCES direct_conversations(id) ON DELETE CASCADE,
    sender_id VARCHAR(100) NOT NULL,
    sender_name VARCHAR(255) NOT NULL,
    sender_avatar_url TEXT,
    recipient_id VARCHAR(100) NOT NULL,
    text TEXT NOT NULL,
    message_type VARCHAR(50) DEFAULT 'text',
    shared_movie_id VARCHAR(100),
    shared_movie_title VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_direct_messages_conv ON direct_messages(conversation_id, created_at ASC);

-- ==========================================================
-- Datos Semilla Iniciales (Estrenos, Cine Peruano y Amigos)
-- ==========================================================

INSERT INTO users (id, email, display_name, username, bio, auth_provider, is_premium, city, country, country_code)
VALUES ('user_alex_101', 'cinefilo@apple.com', 'Alex Rivera', '@alexrivera', 'Crítico entusiasta de cine de autor y estrenos', 'apple', true, 'Lima', 'Perú', 'PE')
ON CONFLICT (id) DO NOTHING;

INSERT INTO friends (id, display_name, username, avatar_url, is_mutual, mutual_movies_count)
VALUES 
    ('friend_lucas', 'Lucas Romero', '@lucasromero', 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200', true, 4),
    ('friend_valeria', 'Valeria Gómez', '@valeriacine', 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200', true, 3),
    ('friend_marcos', 'Marcos Silva', '@marcoss', 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=200', true, 2)
ON CONFLICT (id) DO NOTHING;

INSERT INTO reviews (id, movie_id, movie_title, movie_poster_url, movie_release_year, user_id, user_name, rating, comment, likes_count, helpful_count, is_community)
VALUES 
    ('rev_ekeko_1', 'ekeko_pe_2026', 'Ekeko', 'https://images.unsplash.com/photo-1509281373149-e957c6296406?w=500', 2026, 'friend_valeria', 'Valeria Gómez', 9.0, '¡Extraordinario terror folclórico andino en cines peruanos!', 5, 8, false),
    ('rev_interstellar_1', 'tt0816692', 'Interstellar', 'https://m.media-amazon.com/images/M/MV5BYzdjMDAxZGItMjI2My00ODA1LTlkNzItOWFjMDU5ZDJlYWY3XkEyXkFqcGc@._V1_SX300.jpg', 2014, 'user_alex_101', 'Alex Rivera', 9.5, 'Obra maestra de la ciencia ficción contemporánea.', 12, 14, false)
ON CONFLICT (id) DO NOTHING;

INSERT INTO movie_groups (id, name, description, icon_emoji, creator_id, creator_name, invite_code, messages_count)
VALUES ('grp_cine_peruano', 'Cine Peruano y Latinoamericano', 'Debates de estrenos y clásicos locales', '🇵🇪', 'user_alex_101', 'Alex Rivera', 'CINE-PERU', 1)
ON CONFLICT (id) DO NOTHING;
-- ==========================================================
-- Películas en Cartelera y Horarios de Cines Reales
-- ==========================================================

CREATE TABLE IF NOT EXISTS theatrical_movies (
    id VARCHAR(100) PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    synopsis TEXT,
    poster_url TEXT NOT NULL,
    backdrop_url TEXT,
    release_date DATE NOT NULL,
    origin_country VARCHAR(10) NOT NULL DEFAULT 'US',
    origin_country_name VARCHAR(100) DEFAULT 'Estados Unidos',
    genres VARCHAR(255) DEFAULT 'Drama',
    director VARCHAR(255),
    cast_members TEXT,
    duration_minutes INT DEFAULT 120,
    age_rating VARCHAR(50) DEFAULT '+14',
    rotten_critics INT,
    rotten_audience INT,
    imdb_rating NUMERIC(3, 1),
    composite_score NUMERIC(3, 1),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS cinema_showtimes (
    id VARCHAR(100) PRIMARY KEY,
    movie_id VARCHAR(100) NOT NULL REFERENCES theatrical_movies(id) ON DELETE CASCADE,
    cinema_chain VARCHAR(100) NOT NULL,
    cinema_name VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    country_code VARCHAR(10) NOT NULL,
    address TEXT,
    screen_type VARCHAR(50) DEFAULT '2D Digital',
    language_version VARCHAR(50) DEFAULT 'Subtitulada',
    showtimes TEXT NOT NULL,
    ticket_booking_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_theatrical_release ON theatrical_movies(release_date DESC);
CREATE INDEX IF NOT EXISTS idx_cinema_showtimes_city ON cinema_showtimes(city, movie_id);



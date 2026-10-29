#!/usr/bin/env python3
"""
MovieSocialApp - Backend REST API Server
Soporte dual:
  1. Neon DB (PostgreSQL Serverless en la nube) vía DATABASE_URL
  2. SQLite local (database.sqlite) como respaldo sin conexión
Endpoints soportados: GET, POST, PUT, DELETE
"""

import sys
import os
import json
import sqlite3
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
from datetime import datetime

# Cargar automáticamente variables de backend/.env si existe
env_file_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".env")
if os.path.exists(env_file_path):
    with open(env_file_path, "r") as ef:
        for line in ef:
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, v = line.split("=", 1)
                k = k.strip()
                v = v.strip().strip('"').strip("'")
                if k not in os.environ:
                    os.environ[k] = v

DATABASE_URL = os.getenv("DATABASE_URL")
DB_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "database.sqlite")
HOST = os.getenv("HOST", "0.0.0.0")
PORT = int(os.getenv("PORT", "8080"))

# Intentar importar psycopg2 si DATABASE_URL es PostgreSQL
HAS_POSTGRES = False
if DATABASE_URL and (DATABASE_URL.startswith("postgres://") or DATABASE_URL.startswith("postgresql://")):
    try:
        import psycopg2
        import psycopg2.extras
        HAS_POSTGRES = True
        masked_host = DATABASE_URL.split('@')[-1].split('?')[0] if '@' in DATABASE_URL else 'Neon Cloud'
        print(f"🐘 Conectando a Neon DB (PostgreSQL): {masked_host}")
    except ImportError:
        print("⚠️ DATABASE_URL detectada pero psycopg2 no está instalado. Instalalo con: pip install psycopg2-binary")
        HAS_POSTGRES = False


class DatabaseConnection:
    """Manejador unificado para Neon PostgreSQL o SQLite local"""
    def __init__(self):
        self.is_postgres = HAS_POSTGRES and DATABASE_URL is not None
        if self.is_postgres:
            self.conn = psycopg2.connect(DATABASE_URL)
            self.conn.autocommit = True
            self.cursor = self.conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        else:
            self.conn = sqlite3.connect(DB_FILE)
            self.conn.row_factory = sqlite3.Row
            self.cursor = self.conn.cursor()

    def execute(self, query, params=None):
        params = params or ()
        if self.is_postgres:
            pg_query = query.replace("?", "%s")
            self.cursor.execute(pg_query, params)
        else:
            self.cursor.execute(query, params)
        return self.cursor

    def fetchall(self):
        rows = self.cursor.fetchall()
        return [dict(r) for r in rows]

    def fetchone(self):
        row = self.cursor.fetchone()
        return dict(row) if row else None

    def commit(self):
        if not self.is_postgres:
            self.conn.commit()

    def close(self):
        self.cursor.close()
        self.conn.close()


def init_database():
    """Inicializa tablas en SQLite si se usa localmente sin Neon"""
    if HAS_POSTGRES and DATABASE_URL:
        print("🐘 Neon DB ya conectado y gestionado en la nube.")
        return
        
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.executescript("""
    PRAGMA journal_mode = WAL;
    CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY, email TEXT, display_name TEXT, username TEXT, bio TEXT,
        avatar_url TEXT, auth_provider TEXT, is_premium INTEGER DEFAULT 0,
        city TEXT, country TEXT, country_code TEXT, created_at TEXT
    );
    CREATE TABLE IF NOT EXISTS friends (
        id TEXT PRIMARY KEY, display_name TEXT, username TEXT, avatar_url TEXT,
        is_mutual INTEGER DEFAULT 1, mutual_movies_count INTEGER DEFAULT 0, created_at TEXT
    );
    CREATE TABLE IF NOT EXISTS reviews (
        id TEXT PRIMARY KEY, movie_id TEXT, movie_title TEXT, movie_poster_url TEXT,
        movie_release_year INTEGER, user_id TEXT, user_name TEXT, user_avatar_url TEXT,
        rating REAL, comment TEXT, likes_count INTEGER DEFAULT 0, helpful_count INTEGER DEFAULT 0,
        is_community INTEGER DEFAULT 0, created_at TEXT, updated_at TEXT
    );
    CREATE TABLE IF NOT EXISTS review_comments (
        id TEXT PRIMARY KEY, review_id TEXT, user_id TEXT, user_name TEXT,
        user_avatar_url TEXT, text TEXT, created_at TEXT
    );
    CREATE TABLE IF NOT EXISTS movie_groups (
        id TEXT PRIMARY KEY, name TEXT, description TEXT, icon_emoji TEXT,
        creator_id TEXT, creator_name TEXT, invite_code TEXT UNIQUE, messages_count INTEGER DEFAULT 0, created_at TEXT
    );
    CREATE TABLE IF NOT EXISTS group_messages (
        id TEXT PRIMARY KEY, group_id TEXT, user_id TEXT, user_name TEXT, text TEXT,
        message_type TEXT, shared_movie_id TEXT, shared_movie_title TEXT, created_at TEXT
    );
    CREATE TABLE IF NOT EXISTS direct_conversations (
        id TEXT PRIMARY KEY, participant_id TEXT, unread_count INTEGER DEFAULT 0, updated_at TEXT
    );
    CREATE TABLE IF NOT EXISTS direct_messages (
        id TEXT PRIMARY KEY, conversation_id TEXT, sender_id TEXT, sender_name TEXT,
        sender_avatar_url TEXT, recipient_id TEXT, text TEXT, message_type TEXT,
        shared_movie_id TEXT, shared_movie_title TEXT, created_at TEXT
    );
    """)
    cursor.execute("SELECT COUNT(*) FROM reviews")
    if cursor.fetchone()[0] == 0:
        seed_sqlite_data(cursor)
    conn.commit()
    conn.close()


def seed_sqlite_data(cursor):
    now = datetime.utcnow().isoformat()
    cursor.execute("""
    INSERT OR REPLACE INTO users (id, email, display_name, username, bio, auth_provider, is_premium, city, country, country_code, created_at)
    VALUES ('user_alex_101', 'cinefilo@apple.com', 'Alex Rivera', '@alexrivera', 'Crítico entusiasta de cine de autor y sci-fi', 'apple', 1, 'Lima', 'Perú', 'PE', ?)
    """, (now,))
    friends = [
        ('friend_lucas', 'Lucas Romero', '@lucasromero', 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200', 1, 4, now),
        ('friend_valeria', 'Valeria Gómez', '@valeriacine', 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200', 1, 3, now),
        ('friend_marcos', 'Marcos Silva', '@marcoss', 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=200', 1, 2, now)
    ]
    cursor.executemany("INSERT OR REPLACE INTO friends VALUES (?, ?, ?, ?, ?, ?, ?)", friends)
    cursor.execute("""
    INSERT OR REPLACE INTO reviews (id, movie_id, movie_title, movie_poster_url, movie_release_year, user_id, user_name, rating, comment, likes_count, helpful_count, is_community, created_at)
    VALUES ('rev_ekeko_1', 'ekeko_pe_2026', 'Ekeko', 'https://images.unsplash.com/photo-1509281373149-e957c6296406?w=500', 2026, 'friend_valeria', 'Valeria Gómez', 9.0, '¡Extraordinario terror folclórico andino! El sonido ambiental te sumerge completamente.', 5, 8, 0, ?)
    """, (now,))
    cursor.execute("""
    INSERT OR REPLACE INTO movie_groups (id, name, description, icon_emoji, creator_id, creator_name, invite_code, messages_count, created_at)
    VALUES ('grp_cine_peruano', 'Cine Peruano y Latinoamericano', 'Debates de estrenos y clásicos locales', '🇵🇪', 'user_alex_101', 'Alex Rivera', 'CINE-PERU', 1, ?)
    """, (now,))


class MovieSocialAPIHandler(BaseHTTPRequestHandler):
    def _set_headers(self, status=200):
        self.send_response(status)
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        self.end_headers()

    def do_OPTIONS(self):
        self._set_headers(200)
        self.wfile.write(b'{}')

    def _read_body(self):
        length = int(self.headers.get('Content-Length', 0))
        if length > 0:
            return json.loads(self.rfile.read(length).decode('utf-8'))
        return {}

    def _respond_json(self, data, status=200):
        self._set_headers(status)
        self.wfile.write(json.dumps(data, ensure_ascii=False, default=str).encode('utf-8'))

    # ==========================================
    # GET: Consultas
    # ==========================================
    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path
        query = parse_qs(parsed.query)
        db = DatabaseConnection()

        try:
            if path in ["/api/health", "/api/status"]:
                db.execute("SELECT COUNT(*) as c FROM reviews")
                rev_c = list(db.fetchall()[0].values())[0]
                db.execute("SELECT COUNT(*) as c FROM friends")
                fri_c = list(db.fetchall()[0].values())[0]
                db.execute("SELECT COUNT(*) as c FROM movie_groups")
                grp_c = list(db.fetchall()[0].values())[0]

                db_engine = "Neon DB (PostgreSQL Serverless)" if db.is_postgres else "SQLite Local (database.sqlite)"
                self._respond_json({
                    "status": "online",
                    "database": db_engine,
                    "server": "MovieSocialApp REST API",
                    "version": "2.1.0",
                    "stats": {"reviews": rev_c, "friends": fri_c, "groups": grp_c}
                })

            elif path == "/api/reviews":
                movie_id = query.get('movieId', [None])[0]
                user_id = query.get('userId', [None])[0]

                if movie_id:
                    db.execute("SELECT * FROM reviews WHERE movie_id = ? ORDER BY created_at DESC", (movie_id,))
                elif user_id:
                    db.execute("SELECT * FROM reviews WHERE user_id = ? ORDER BY created_at DESC", (user_id,))
                else:
                    db.execute("SELECT * FROM reviews ORDER BY created_at DESC")

                rows = db.fetchall()
                self._respond_json({"reviews": rows, "count": len(rows)})

            elif path == "/api/friends":
                db.execute("SELECT * FROM friends ORDER BY display_name ASC")
                rows = db.fetchall()
                self._respond_json({"friends": rows, "count": len(rows)})

            elif path == "/api/groups":
                db.execute("SELECT * FROM movie_groups ORDER BY created_at DESC")
                rows = db.fetchall()
                self._respond_json({"groups": rows, "count": len(rows)})

            elif path.startswith("/api/groups/") and path.endswith("/messages"):
                group_id = path.strip("/").split("/")[2]
                db.execute("SELECT * FROM group_messages WHERE group_id = ? ORDER BY created_at ASC", (group_id,))
                rows = db.fetchall()
                self._respond_json({"messages": rows, "count": len(rows)})

            elif path == "/api/chats":
                db.execute("SELECT * FROM direct_conversations ORDER BY updated_at DESC")
                rows = db.fetchall()
                self._respond_json({"conversations": rows, "count": len(rows)})

            elif path.startswith("/api/users/"):
                user_id = path.strip("/").split("/")[2]
                db.execute("SELECT * FROM users WHERE id = ? LIMIT 1", (user_id,))
                row = db.fetchone()
                if row:
                    self._respond_json(row)
                else:
                    self._respond_json({"error": "Usuario no encontrado"}, status=404)
            else:
                self._respond_json({"error": f"Endpoint GET {path} no encontrado"}, status=404)

        except Exception as e:
            self._respond_json({"error": str(e)}, status=500)
        finally:
            db.close()

    # ==========================================
    # POST: Inserciones
    # ==========================================
    def do_POST(self):
        parsed = urlparse(self.path)
        path = parsed.path
        body = self._read_body()
        db = DatabaseConnection()

        try:
            if path == "/api/reviews":
                rev_id = body.get("id") or f"rev_{int(datetime.utcnow().timestamp())}"
                movie_id = body.get("movieId")
                user_id = body.get("userId")

                db.execute("SELECT id FROM reviews WHERE movie_id = ? AND user_id = ?", (movie_id, user_id))
                if db.fetchone():
                    self._respond_json({"error": "El usuario ya publicó una reseña para esta película"}, status=409)
                    return

                now = datetime.utcnow().isoformat()
                is_comm = True if body.get("isCommunity") else False
                db.execute("""
                INSERT INTO reviews (id, movie_id, movie_title, movie_poster_url, movie_release_year, user_id, user_name, rating, comment, is_community, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, (
                    rev_id, movie_id, body.get("movieTitle", "Película"),
                    body.get("moviePosterURL"), body.get("movieReleaseYear"),
                    user_id, body.get("userName", "Usuario"),
                    float(body.get("rating", 5.0)), body.get("comment", ""),
                    is_comm, now
                ))
                db.commit()
                self._respond_json({"message": "Reseña creada con éxito", "id": rev_id}, status=201)

            elif path == "/api/friends":
                friend_id = body.get("id") or f"friend_{int(datetime.utcnow().timestamp())}"
                now = datetime.utcnow().isoformat()
                is_mut = True if body.get("isMutual", True) else False
                db.execute("""
                INSERT INTO friends (id, display_name, username, avatar_url, is_mutual, mutual_movies_count, created_at)
                VALUES (?, ?, ?, ?, ?, 1, ?)
                """, (friend_id, body.get("displayName", "Amigo"), body.get("username", "@amigo"), body.get("avatarURL"), is_mut, now))
                db.commit()
                self._respond_json({"message": "Amigo agregado", "id": friend_id}, status=201)

            elif path == "/api/groups":
                grp_id = body.get("id") or f"grp_{int(datetime.utcnow().timestamp())}"
                code = body.get("inviteCode") or f"CINE-{grp_id[-6:].upper()}"
                now = datetime.utcnow().isoformat()
                db.execute("""
                INSERT INTO movie_groups (id, name, description, icon_emoji, creator_id, creator_name, invite_code, messages_count, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?)
                """, (
                    grp_id, body.get("name", "Cineclub"), body.get("description", ""),
                    body.get("iconEmoji", "🎬"), body.get("creatorId", "user_1"),
                    body.get("creatorName", "Admin"), code, now
                ))
                db.commit()
                self._respond_json({"message": "Grupo creado", "id": grp_id, "inviteCode": code}, status=201)

            elif path.startswith("/api/groups/") and path.endswith("/messages"):
                group_id = path.strip("/").split("/")[2]
                msg_id = body.get("id") or f"gmsg_{int(datetime.utcnow().timestamp())}"
                now = datetime.utcnow().isoformat()
                db.execute("""
                INSERT INTO group_messages (id, group_id, user_id, user_name, text, message_type, shared_movie_id, shared_movie_title, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, (
                    msg_id, group_id, body.get("userId", "user"), body.get("userName", "Usuario"),
                    body.get("text", ""), body.get("messageType", "text"),
                    body.get("sharedMovieId"), body.get("sharedMovieTitle"), now
                ))
                db.execute("UPDATE movie_groups SET messages_count = messages_count + 1 WHERE id = ?", (group_id,))
                db.commit()
                self._respond_json({"message": "Mensaje enviado al grupo", "id": msg_id}, status=201)

            elif path == "/api/database/reset":
                if not db.is_postgres:
                    init_database()
                self._respond_json({"message": "Base de datos restaurada"})

            else:
                self._respond_json({"error": f"Endpoint POST {path} no encontrado"}, status=404)

        except Exception as e:
            self._respond_json({"error": str(e)}, status=500)
        finally:
            db.close()

    # ==========================================
    # PUT: Actualizaciones
    # ==========================================
    def do_PUT(self):
        parsed = urlparse(self.path)
        path = parsed.path
        body = self._read_body()
        db = DatabaseConnection()

        try:
            if path.startswith("/api/reviews/"):
                rev_id = path.strip("/").split("/")[2]
                now = datetime.utcnow().isoformat()
                db.execute("""
                UPDATE reviews 
                SET rating = COALESCE(?, rating), comment = COALESCE(?, comment), updated_at = ?
                WHERE id = ?
                """, (body.get("rating"), body.get("comment"), now, rev_id))
                db.commit()
                self._respond_json({"message": "Reseña actualizada con éxito", "id": rev_id})

            elif path.startswith("/api/users/"):
                user_id = path.strip("/").split("/")[2]
                db.execute("""
                UPDATE users
                SET display_name = COALESCE(?, display_name), username = COALESCE(?, username),
                    bio = COALESCE(?, bio), city = COALESCE(?, city), country = COALESCE(?, country)
                WHERE id = ?
                """, (body.get("displayName"), body.get("username"), body.get("bio"), body.get("city"), body.get("country"), user_id))
                db.commit()
                self._respond_json({"message": "Perfil actualizado", "id": user_id})

            else:
                self._respond_json({"error": f"Endpoint PUT {path} no encontrado"}, status=404)

        except Exception as e:
            self._respond_json({"error": str(e)}, status=500)
        finally:
            db.close()

    # ==========================================
    # DELETE: Eliminaciones
    # ==========================================
    def do_DELETE(self):
        parsed = urlparse(self.path)
        path = parsed.path
        db = DatabaseConnection()

        try:
            if path.startswith("/api/reviews/"):
                rev_id = path.strip("/").split("/")[2]
                db.execute("DELETE FROM reviews WHERE id = ?", (rev_id,))
                db.commit()
                self._respond_json({"message": "Reseña eliminada", "id": rev_id})

            elif path.startswith("/api/friends/"):
                friend_id = path.strip("/").split("/")[2]
                db.execute("DELETE FROM friends WHERE id = ?", (friend_id,))
                db.commit()
                self._respond_json({"message": "Amigo eliminado", "id": friend_id})

            else:
                self._respond_json({"error": f"Endpoint DELETE {path} no encontrado"}, status=404)

        except Exception as e:
            self._respond_json({"error": str(e)}, status=500)
        finally:
            db.close()


def run_server():
    init_database()
    server_address = (HOST, PORT)
    httpd = HTTPServer(server_address, MovieSocialAPIHandler)
    engine_name = f"Neon DB (PostgreSQL) -> {DATABASE_URL.split('@')[-1].split('?')[0]}" if (HAS_POSTGRES and DATABASE_URL) else f"SQLite ({DB_FILE})"
    print(f"📡 Servidor REST Activo en http://{HOST}:{PORT}")
    print(f"🗄️ Base de datos: {engine_name}")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n🛑 Servidor detenido.")
        httpd.server_close()


if __name__ == '__main__':
    run_server()

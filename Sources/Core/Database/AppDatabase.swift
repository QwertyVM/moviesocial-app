import Foundation
import SQLite3

/// Gestor centralizado de Base de Datos SQLite para MovieSocialApp
/// Provee persistencia ACID en disco, soporte para Swift Concurrency (Actor)
/// y almacenamiento relacional estructurado para Usuarios, Reseñas, Amigos, Chats y Grupos.
public actor AppDatabase {
    public static let shared = AppDatabase()
    
    private var db: OpaquePointer?
    private let dbPath: String
    
    public init(inMemory: Bool = false, customPath: String? = nil) {
        let path: String
        if inMemory {
            path = ":memory:"
        } else if let customPath {
            path = customPath
        } else {
            let fileManager = FileManager.default
            let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let appDir = appSupport.appendingPathComponent("MovieSocialApp", isDirectory: true)
            
            if !fileManager.fileExists(atPath: appDir.path) {
                try? fileManager.createDirectory(at: appDir, withIntermediateDirectories: true)
            }
            path = appDir.appendingPathComponent("moviesocial.sqlite").path
        }
        self.dbPath = path
        
        var pointer: OpaquePointer?
        let flags = SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX
        if sqlite3_open_v2(path, &pointer, flags, nil) == SQLITE_OK {
            self.db = pointer
            AppDatabase.executeSQL(db: pointer, sql: "PRAGMA journal_mode = WAL;")
            AppDatabase.executeSQL(db: pointer, sql: "PRAGMA synchronous = NORMAL;")
            AppDatabase.executeSQL(db: pointer, sql: "PRAGMA foreign_keys = ON;")
            AppDatabase.createTables(db: pointer)
        } else {
            print("⚠️ Error abriendo SQLite en ruta \(path)")
            self.db = nil
        }
    }
    
    // MARK: - Ejecución SQL estática y segura
    
    private static func executeSQL(db: OpaquePointer?, sql: String) {
        guard let db else { return }
        var errorMessage: UnsafeMutablePointer<CChar>?
        if sqlite3_exec(db, sql, nil, nil, &errorMessage) != SQLITE_OK {
            if let error = errorMessage {
                let message = String(cString: error)
                sqlite3_free(errorMessage)
                print("⚠️ SQLite Exec Error: \(message) en SQL: \(sql)")
            }
        }
    }
    
    private func executeSQL(_ sql: String) {
        AppDatabase.executeSQL(db: self.db, sql: sql)
    }
    
    // MARK: - Esquema Relacional de Tablas
    
    private static func createTables(db: OpaquePointer?) {
        let schema = """
        CREATE TABLE IF NOT EXISTS users (
            id TEXT PRIMARY KEY,
            email TEXT,
            display_name TEXT,
            data TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS friends (
            id TEXT PRIMARY KEY,
            data TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS reviews (
            id TEXT PRIMARY KEY,
            movie_id TEXT NOT NULL,
            user_id TEXT NOT NULL,
            is_community INTEGER NOT NULL DEFAULT 0,
            created_at REAL NOT NULL,
            data TEXT NOT NULL
        );
        CREATE INDEX IF NOT EXISTS idx_reviews_movie ON reviews(movie_id);
        CREATE INDEX IF NOT EXISTS idx_reviews_user ON reviews(user_id);

        CREATE TABLE IF NOT EXISTS review_comments (
            id TEXT PRIMARY KEY,
            review_id TEXT NOT NULL,
            created_at REAL NOT NULL,
            data TEXT NOT NULL
        );
        CREATE INDEX IF NOT EXISTS idx_comments_review ON review_comments(review_id);

        CREATE TABLE IF NOT EXISTS direct_conversations (
            id TEXT PRIMARY KEY,
            participant_id TEXT,
            updated_at REAL NOT NULL,
            data TEXT NOT NULL
        );
        CREATE INDEX IF NOT EXISTS idx_conversations_updated ON direct_conversations(updated_at DESC);

        CREATE TABLE IF NOT EXISTS direct_messages (
            id TEXT PRIMARY KEY,
            conversation_id TEXT NOT NULL,
            timestamp REAL NOT NULL,
            data TEXT NOT NULL
        );
        CREATE INDEX IF NOT EXISTS idx_messages_conv ON direct_messages(conversation_id, timestamp ASC);

        CREATE TABLE IF NOT EXISTS movie_groups (
            id TEXT PRIMARY KEY,
            invite_code TEXT,
            created_at REAL NOT NULL,
            data TEXT NOT NULL
        );
        CREATE INDEX IF NOT EXISTS idx_groups_code ON movie_groups(invite_code);

        CREATE TABLE IF NOT EXISTS group_messages (
            id TEXT PRIMARY KEY,
            group_id TEXT NOT NULL,
            timestamp REAL NOT NULL,
            data TEXT NOT NULL
        );
        CREATE INDEX IF NOT EXISTS idx_grp_messages ON group_messages(group_id, timestamp ASC);

        CREATE TABLE IF NOT EXISTS app_session (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
        );
        """
        executeSQL(db: db, sql: schema)
    }
    
    // MARK: - Session & User
    
    public func getCurrentSessionUserId() -> String? {
        guard let db else { return nil }
        let sql = "SELECT value FROM app_session WHERE key = 'current_user_id' LIMIT 1;"
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }
        
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                if let cStr = sqlite3_column_text(statement, 0) {
                    return String(cString: cStr)
                }
            }
        }
        return nil
    }
    
    public func saveCurrentSessionUserId(_ userId: String?) {
        guard let db else { return }
        if let userId {
            let sql = "INSERT OR REPLACE INTO app_session (key, value) VALUES ('current_user_id', ?);"
            var stmt: OpaquePointer?
            defer { sqlite3_finalize(stmt) }
            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_text(stmt, 1, (userId as NSString).utf8String, -1, nil)
                sqlite3_step(stmt)
            }
        } else {
            executeSQL("DELETE FROM app_session WHERE key = 'current_user_id';")
        }
    }
    
    public func saveUser(_ user: User) {
        guard let db, let encoded = try? JSONEncoder().encode(user),
              let jsonStr = String(data: encoded, encoding: .utf8) else { return }
        
        let sql = "INSERT OR REPLACE INTO users (id, email, display_name, data) VALUES (?, ?, ?, ?);"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (user.id as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 2, (user.email as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 3, (user.displayName as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 4, (jsonStr as NSString).utf8String, -1, nil)
            sqlite3_step(stmt)
        }
    }
    
    public func getUser(id: String) -> User? {
        guard let db else { return nil }
        let sql = "SELECT data FROM users WHERE id = ? LIMIT 1;"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (id as NSString).utf8String, -1, nil)
            if sqlite3_step(stmt) == SQLITE_ROW {
                if let cStr = sqlite3_column_text(stmt, 0) {
                    let json = String(cString: cStr)
                    if let data = json.data(using: .utf8) {
                        return try? JSONDecoder().decode(User.self, from: data)
                    }
                }
            }
        }
        return nil
    }
    
    // MARK: - Friends
    
    public func saveFriend(_ friend: Friend) {
        guard let db, let encoded = try? JSONEncoder().encode(friend),
              let jsonStr = String(data: encoded, encoding: .utf8) else { return }
        
        let sql = "INSERT OR REPLACE INTO friends (id, data) VALUES (?, ?);"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (friend.id as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 2, (jsonStr as NSString).utf8String, -1, nil)
            sqlite3_step(stmt)
        }
    }
    
    public func removeFriend(id: String) {
        guard let db else { return }
        let sql = "DELETE FROM friends WHERE id = ?;"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (id as NSString).utf8String, -1, nil)
            sqlite3_step(stmt)
        }
    }
    
    public func getAllFriends() -> [Friend] {
        guard let db else { return [] }
        let sql = "SELECT data FROM friends;"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        var result: [Friend] = []
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                if let cStr = sqlite3_column_text(stmt, 0) {
                    let json = String(cString: cStr)
                    if let data = json.data(using: .utf8),
                       let item = try? JSONDecoder().decode(Friend.self, from: data) {
                        result.append(item)
                    }
                }
            }
        }
        return result
    }
    
    // MARK: - Reviews
    
    public func saveReview(_ review: Review, isCommunity: Bool = false) {
        guard let db, let encoded = try? JSONEncoder().encode(review),
              let jsonStr = String(data: encoded, encoding: .utf8) else { return }
        
        let sql = "INSERT OR REPLACE INTO reviews (id, movie_id, user_id, is_community, created_at, data) VALUES (?, ?, ?, ?, ?, ?);"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (review.id as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 2, (review.movieId as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 3, (review.userId as NSString).utf8String, -1, nil)
            sqlite3_bind_int(stmt, 4, isCommunity ? 1 : 0)
            sqlite3_bind_double(stmt, 5, review.createdAt.timeIntervalSince1970)
            sqlite3_bind_text(stmt, 6, (jsonStr as NSString).utf8String, -1, nil)
            sqlite3_step(stmt)
        }
    }
    
    public func getAllReviews(includeCommunity: Bool = false) -> [Review] {
        guard let db else { return [] }
        let sql = includeCommunity
            ? "SELECT data FROM reviews ORDER BY created_at DESC;"
            : "SELECT data FROM reviews WHERE is_community = 0 ORDER BY created_at DESC;"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        var result: [Review] = []
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                if let cStr = sqlite3_column_text(stmt, 0) {
                    let json = String(cString: cStr)
                    if let data = json.data(using: .utf8),
                       let item = try? JSONDecoder().decode(Review.self, from: data) {
                        result.append(item)
                    }
                }
            }
        }
        return result
    }
    
    public func getReviewsForMovie(movieId: String, communityOnly: Bool = false) -> [Review] {
        guard let db else { return [] }
        let sql = communityOnly
            ? "SELECT data FROM reviews WHERE movie_id = ? AND is_community = 1 ORDER BY created_at DESC;"
            : "SELECT data FROM reviews WHERE movie_id = ? AND is_community = 0 ORDER BY created_at DESC;"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        var result: [Review] = []
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (movieId as NSString).utf8String, -1, nil)
            while sqlite3_step(stmt) == SQLITE_ROW {
                if let cStr = sqlite3_column_text(stmt, 0) {
                    let json = String(cString: cStr)
                    if let data = json.data(using: .utf8),
                       let item = try? JSONDecoder().decode(Review.self, from: data) {
                        result.append(item)
                    }
                }
            }
        }
        return result
    }
    
    public func getUserReviews(userId: String) -> [Review] {
        guard let db else { return [] }
        let sql = "SELECT data FROM reviews WHERE user_id = ? ORDER BY created_at DESC;"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        var result: [Review] = []
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (userId as NSString).utf8String, -1, nil)
            while sqlite3_step(stmt) == SQLITE_ROW {
                if let cStr = sqlite3_column_text(stmt, 0) {
                    let json = String(cString: cStr)
                    if let data = json.data(using: .utf8),
                       let item = try? JSONDecoder().decode(Review.self, from: data) {
                        result.append(item)
                    }
                }
            }
        }
        return result
    }
    
    // MARK: - Comments
    
    public func saveComment(_ comment: ReviewComment, reviewId: String) {
        guard let db, let encoded = try? JSONEncoder().encode(comment),
              let jsonStr = String(data: encoded, encoding: .utf8) else { return }
        
        let sql = "INSERT OR REPLACE INTO review_comments (id, review_id, created_at, data) VALUES (?, ?, ?, ?);"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (comment.id as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 2, (reviewId as NSString).utf8String, -1, nil)
            sqlite3_bind_double(stmt, 3, comment.createdAt.timeIntervalSince1970)
            sqlite3_bind_text(stmt, 4, (jsonStr as NSString).utf8String, -1, nil)
            sqlite3_step(stmt)
        }
    }
    
    // MARK: - Direct Conversations & Messages
    
    public func saveConversation(_ conversation: DirectConversation) {
        guard let db, let encoded = try? JSONEncoder().encode(conversation),
              let jsonStr = String(data: encoded, encoding: .utf8) else { return }
        
        let sql = "INSERT OR REPLACE INTO direct_conversations (id, participant_id, updated_at, data) VALUES (?, ?, ?, ?);"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (conversation.id as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 2, (conversation.participant.id as NSString).utf8String, -1, nil)
            sqlite3_bind_double(stmt, 3, conversation.updatedAt.timeIntervalSince1970)
            sqlite3_bind_text(stmt, 4, (jsonStr as NSString).utf8String, -1, nil)
            sqlite3_step(stmt)
        }
    }
    
    public func getAllConversations() -> [DirectConversation] {
        guard let db else { return [] }
        let sql = "SELECT data FROM direct_conversations ORDER BY updated_at DESC;"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        var result: [DirectConversation] = []
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                if let cStr = sqlite3_column_text(stmt, 0) {
                    let json = String(cString: cStr)
                    if let data = json.data(using: .utf8),
                       let item = try? JSONDecoder().decode(DirectConversation.self, from: data) {
                        result.append(item)
                    }
                }
            }
        }
        return result
    }
    
    public func saveDirectMessage(_ message: DirectMessage) {
        guard let db, let encoded = try? JSONEncoder().encode(message),
              let jsonStr = String(data: encoded, encoding: .utf8) else { return }
        
        let sql = "INSERT OR REPLACE INTO direct_messages (id, conversation_id, timestamp, data) VALUES (?, ?, ?, ?);"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (message.id as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 2, (message.conversationId as NSString).utf8String, -1, nil)
            sqlite3_bind_double(stmt, 3, message.createdAt.timeIntervalSince1970)
            sqlite3_bind_text(stmt, 4, (jsonStr as NSString).utf8String, -1, nil)
            sqlite3_step(stmt)
        }
    }
    
    public func getDirectMessages(conversationId: String) -> [DirectMessage] {
        guard let db else { return [] }
        let sql = "SELECT data FROM direct_messages WHERE conversation_id = ? ORDER BY timestamp ASC;"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        var result: [DirectMessage] = []
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (conversationId as NSString).utf8String, -1, nil)
            while sqlite3_step(stmt) == SQLITE_ROW {
                if let cStr = sqlite3_column_text(stmt, 0) {
                    let json = String(cString: cStr)
                    if let data = json.data(using: .utf8),
                       let item = try? JSONDecoder().decode(DirectMessage.self, from: data) {
                        result.append(item)
                    }
                }
            }
        }
        return result
    }
    
    // MARK: - Movie Groups & Group Messages
    
    public func saveGroup(_ group: MovieGroup) {
        guard let db, let encoded = try? JSONEncoder().encode(group),
              let jsonStr = String(data: encoded, encoding: .utf8) else { return }
        
        let sql = "INSERT OR REPLACE INTO movie_groups (id, invite_code, created_at, data) VALUES (?, ?, ?, ?);"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (group.id as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 2, (group.inviteCode as NSString).utf8String, -1, nil)
            sqlite3_bind_double(stmt, 3, group.createdAt.timeIntervalSince1970)
            sqlite3_bind_text(stmt, 4, (jsonStr as NSString).utf8String, -1, nil)
            sqlite3_step(stmt)
        }
    }
    
    public func getAllGroups() -> [MovieGroup] {
        guard let db else { return [] }
        let sql = "SELECT data FROM movie_groups ORDER BY created_at DESC;"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        var result: [MovieGroup] = []
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                if let cStr = sqlite3_column_text(stmt, 0) {
                    let json = String(cString: cStr)
                    if let data = json.data(using: .utf8),
                       let item = try? JSONDecoder().decode(MovieGroup.self, from: data) {
                        result.append(item)
                    }
                }
            }
        }
        return result
    }
    
    public func saveGroupMessage(_ message: GroupMessage) {
        guard let db, let encoded = try? JSONEncoder().encode(message),
              let jsonStr = String(data: encoded, encoding: .utf8) else { return }
        
        let sql = "INSERT OR REPLACE INTO group_messages (id, group_id, timestamp, data) VALUES (?, ?, ?, ?);"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (message.id as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 2, (message.groupId as NSString).utf8String, -1, nil)
            sqlite3_bind_double(stmt, 3, message.createdAt.timeIntervalSince1970)
            sqlite3_bind_text(stmt, 4, (jsonStr as NSString).utf8String, -1, nil)
            sqlite3_step(stmt)
        }
    }
    
    public func getGroupMessages(groupId: String) -> [GroupMessage] {
        guard let db else { return [] }
        let sql = "SELECT data FROM group_messages WHERE group_id = ? ORDER BY timestamp ASC;"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        var result: [GroupMessage] = []
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (groupId as NSString).utf8String, -1, nil)
            while sqlite3_step(stmt) == SQLITE_ROW {
                if let cStr = sqlite3_column_text(stmt, 0) {
                    let json = String(cString: cStr)
                    if let data = json.data(using: .utf8),
                       let item = try? JSONDecoder().decode(GroupMessage.self, from: data) {
                        result.append(item)
                    }
                }
            }
        }
        return result
    }
    
    // MARK: - Mantenimiento y Reinicio de Base de Datos
    
    /// Reinicia completamente las tablas y elimina todos los registros persistentes
    public func clearAllTables() {
        let sql = """
        DELETE FROM users;
        DELETE FROM friends;
        DELETE FROM reviews;
        DELETE FROM review_comments;
        DELETE FROM direct_conversations;
        DELETE FROM direct_messages;
        DELETE FROM movie_groups;
        DELETE FROM group_messages;
        DELETE FROM app_session;
        VACUUM;
        """
        executeSQL(sql)
    }
    
    /// Cuenta total de registros en la base de datos para diagnósticos
    public func getDatabaseStats() -> [String: Int] {
        guard let db else { return [:] }
        let tables = ["users", "friends", "reviews", "review_comments", "direct_conversations", "direct_messages", "movie_groups", "group_messages"]
        var stats: [String: Int] = [:]
        
        for table in tables {
            let sql = "SELECT COUNT(*) FROM \(table);"
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                if sqlite3_step(stmt) == SQLITE_ROW {
                    stats[table] = Int(sqlite3_column_int(stmt, 0))
                }
            }
            sqlite3_finalize(stmt)
        }
        return stats
    }
}

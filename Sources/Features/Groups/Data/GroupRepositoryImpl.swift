import Foundation

public actor GroupRepositoryImpl: GroupRepositoryProtocol {
    private var groups: [MovieGroup]
    private var messages: [String: [GroupMessage]]
    
    public init(
        groups: [MovieGroup] = defaultGroups,
        messages: [String: [GroupMessage]] = defaultMessages
    ) {
        self.groups = groups
        self.messages = messages
    }
    
    public func getGroups() async throws -> [MovieGroup] {
        return groups.sorted { $0.createdAt > $1.createdAt }
    }
    
    public func getGroup(id: String) async throws -> MovieGroup? {
        return groups.first { $0.id == id }
    }
    
    public func createGroup(
        name: String,
        description: String,
        iconEmoji: String,
        initialMembers: [Friend] = [],
        currentMovieId: String?,
        currentMovieTitle: String?,
        currentMoviePosterURL: URL?,
        currentMovieYear: Int?,
        creator: User
    ) async throws -> MovieGroup {
        let inviteCode = "CINE-\(UUID().uuidString.prefix(6).uppercased())"
        let newGroup = MovieGroup(
            id: UUID().uuidString,
            name: name,
            description: description,
            iconEmoji: iconEmoji,
            creatorId: creator.id,
            creatorName: creator.displayName,
            members: initialMembers,
            inviteCode: inviteCode,
            currentMovieId: currentMovieId,
            currentMovieTitle: currentMovieTitle,
            currentMoviePosterURL: currentMoviePosterURL,
            currentMovieYear: currentMovieYear,
            messagesCount: 1,
            createdAt: Date()
        )
        
        groups.insert(newGroup, at: 0)
        
        // Mensaje inicial de sistema estilo WhatsApp
        var systemNotice = "\(creator.displayName) creó el grupo «\(name)»"
        if !initialMembers.isEmpty {
            let names = initialMembers.map(\.displayName).joined(separator: ", ")
            systemNotice += " y añadió a \(names)"
        }
        
        let initialMsg = GroupMessage(
            id: UUID().uuidString,
            groupId: newGroup.id,
            userId: "system",
            userName: "Sistema",
            text: systemNotice,
            messageType: .system,
            createdAt: Date()
        )
        messages[newGroup.id] = [initialMsg]
        return newGroup
    }
    
    public func joinGroup(groupId: String, user: User) async throws -> MovieGroup {
        guard let index = groups.firstIndex(where: { $0.id == groupId }) else {
            throw NSError(domain: "Group", code: 404, userInfo: [NSLocalizedDescriptionKey: "Grupo no encontrado"])
        }
        
        let alreadyMember = groups[index].members.contains(where: { $0.id == user.id }) || groups[index].creatorId == user.id
        if !alreadyMember {
            let newMember = Friend(
                id: user.id,
                displayName: user.displayName,
                username: "@\(user.displayName.lowercased().replacingOccurrences(of: " ", with: ""))",
                avatarURL: user.avatarURL,
                isMutual: true,
                mutualMoviesCount: 0
            )
            groups[index].members.append(newMember)
            
            let joinMsg = GroupMessage(
                id: UUID().uuidString,
                groupId: groupId,
                userId: "system",
                userName: "Sistema",
                text: "\(user.displayName) se unió al grupo",
                messageType: .system,
                createdAt: Date()
            )
            if messages[groupId] == nil {
                messages[groupId] = []
            }
            messages[groupId]?.append(joinMsg)
            groups[index].messagesCount += 1
        }
        
        return groups[index]
    }
    
    public func joinGroupByInviteCode(code: String, user: User) async throws -> MovieGroup {
        let cleanCode = code
            .replacingOccurrences(of: "https://moviesocial.app/join/", with: "")
            .replacingOccurrences(of: "moviesocial://join/", with: "")
            .replacingOccurrences(of: "moviesocial://group/", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        
        guard let index = groups.firstIndex(where: {
            $0.inviteCode.uppercased() == cleanCode ||
            $0.id.uppercased() == cleanCode ||
            $0.inviteLink.uppercased().contains(cleanCode)
        }) else {
            throw NSError(domain: "Group", code: 404, userInfo: [NSLocalizedDescriptionKey: "No se encontró ningún cineclub con el enlace o código «\(code)»."])
        }
        
        let targetGroup = groups[index]
        let alreadyMember = targetGroup.members.contains(where: { $0.id == user.id }) || targetGroup.creatorId == user.id
        
        if !alreadyMember {
            let newMember = Friend(
                id: user.id,
                displayName: user.displayName,
                username: "@\(user.displayName.lowercased().replacingOccurrences(of: " ", with: ""))",
                avatarURL: user.avatarURL,
                isMutual: true,
                mutualMoviesCount: 0
            )
            groups[index].members.append(newMember)
            
            let joinMsg = GroupMessage(
                id: UUID().uuidString,
                groupId: targetGroup.id,
                userId: "system",
                userName: "Sistema",
                text: "\(user.displayName) se unió mediante el enlace de invitación",
                messageType: .system,
                createdAt: Date()
            )
            if messages[targetGroup.id] == nil {
                messages[targetGroup.id] = []
            }
            messages[targetGroup.id]?.append(joinMsg)
            groups[index].messagesCount += 1
        }
        
        return groups[index]
    }
    
    public func addMembersToGroup(groupId: String, friends: [Friend]) async throws -> MovieGroup {
        guard let index = groups.firstIndex(where: { $0.id == groupId }) else {
            throw NSError(domain: "Group", code: 404, userInfo: [NSLocalizedDescriptionKey: "Grupo no encontrado"])
        }
        
        var addedCount = 0
        var addedNames: [String] = []
        for friend in friends {
            if !groups[index].members.contains(where: { $0.id == friend.id }) && groups[index].creatorId != friend.id {
                groups[index].members.append(friend)
                addedCount += 1
                addedNames.append(friend.displayName)
            }
        }
        
        if addedCount > 0 {
            let addMsg = GroupMessage(
                id: UUID().uuidString,
                groupId: groupId,
                userId: "system",
                userName: "Sistema",
                text: "Se añadió a \(addedNames.joined(separator: ", ")) al grupo",
                messageType: .system,
                createdAt: Date()
            )
            if messages[groupId] == nil {
                messages[groupId] = []
            }
            messages[groupId]?.append(addMsg)
            groups[index].messagesCount += 1
        }
        
        return groups[index]
    }
    
    public func getGroupMessages(groupId: String) async throws -> [GroupMessage] {
        return messages[groupId] ?? []
    }
    
    public func sendGroupMessage(
        groupId: String,
        text: String,
        user: User,
        messageType: GroupMessageType = .text,
        sharedMovieId: String? = nil,
        sharedMovieTitle: String? = nil,
        sharedMoviePosterURL: URL? = nil,
        sharedMovieYear: Int? = nil
    ) async throws -> GroupMessage {
        guard let index = groups.firstIndex(where: { $0.id == groupId }) else {
            throw NSError(domain: "Group", code: 404, userInfo: [NSLocalizedDescriptionKey: "Grupo no encontrado"])
        }
        
        let newMessage = GroupMessage(
            id: UUID().uuidString,
            groupId: groupId,
            userId: user.id,
            userName: user.displayName,
            userAvatarURL: user.avatarURL,
            text: text,
            messageType: messageType,
            sharedMovieId: sharedMovieId,
            sharedMovieTitle: sharedMovieTitle,
            sharedMoviePosterURL: sharedMoviePosterURL,
            sharedMovieYear: sharedMovieYear,
            createdAt: Date()
        )
        
        if messages[groupId] == nil {
            messages[groupId] = []
        }
        messages[groupId]?.append(newMessage)
        groups[index].messagesCount += 1
        
        return newMessage
    }
    
    public func setGroupMovie(groupId: String, movie: Movie) async throws -> MovieGroup {
        guard let index = groups.firstIndex(where: { $0.id == groupId }) else {
            throw NSError(domain: "Group", code: 404, userInfo: [NSLocalizedDescriptionKey: "Grupo no encontrado"])
        }
        
        groups[index].currentMovieId = movie.id
        groups[index].currentMovieTitle = movie.title
        groups[index].currentMoviePosterURL = movie.posterURL
        groups[index].currentMovieYear = movie.releaseYear
        
        let movieMsg = GroupMessage(
            id: UUID().uuidString,
            groupId: groupId,
            userId: "system",
            userName: "Sistema",
            text: "Se fijó como película en debate: «\(movie.title)» (\(movie.releaseYear))",
            messageType: .system,
            sharedMovieId: movie.id,
            sharedMovieTitle: movie.title,
            sharedMoviePosterURL: movie.posterURL,
            sharedMovieYear: movie.releaseYear,
            createdAt: Date()
        )
        messages[groupId]?.append(movieMsg)
        groups[index].messagesCount += 1
        
        return groups[index]
    }
    
    public static let defaultGroups: [MovieGroup] = [
        MovieGroup(
            id: "group_1",
            name: "Cineclub Nolan & Sci-Fi",
            description: "Para apasionados de la ciencia ficción, viajes temporales, bandas sonoras colosales y debates de cine.",
            iconEmoji: "🚀",
            creatorId: "friend_1",
            creatorName: "Lucas Benítez",
            members: [
                Friend(id: "friend_2", displayName: "Camila Vega", username: "@camicine", avatarURL: nil, isMutual: true, mutualMoviesCount: 22),
                Friend(id: "friend_3", displayName: "Mateo Rossi", username: "@mrossi", avatarURL: nil, isMutual: true, mutualMoviesCount: 8)
            ],
            inviteCode: "CINE-NOLAN",
            currentMovieId: "693134",
            currentMovieTitle: "Dune: Parte Dos",
            currentMoviePosterURL: URL(string: "https://image.tmdb.org/t/p/w500/8b8R8l88Qje9dn9OE8PY05Nxl1X.jpg"),
            currentMovieYear: 2024,
            messagesCount: 4,
            createdAt: Date().addingTimeInterval(-86400 * 5)
        ),
        MovieGroup(
            id: "group_2",
            name: "Tertulia de Clásicos Inmortales",
            description: "Desde el Film Noir de los años 40 hasta las obras maestras del cine de autor y Hollywood clásico.",
            iconEmoji: "🎞️",
            creatorId: "friend_2",
            creatorName: "Camila Vega",
            members: [
                Friend(id: "friend_1", displayName: "Lucas Benítez", username: "@lucasfilm", avatarURL: nil, isMutual: true, mutualMoviesCount: 14)
            ],
            inviteCode: "CINE-CLASSIC",
            currentMovieId: "238",
            currentMovieTitle: "El Padrino",
            currentMoviePosterURL: URL(string: "https://image.tmdb.org/t/p/w500/3bhkrj58Vtu7enYsRolD1fZdja1.jpg"),
            currentMovieYear: 1972,
            messagesCount: 3,
            createdAt: Date().addingTimeInterval(-86400 * 12)
        ),
        MovieGroup(
            id: "group_3",
            name: "Viernes de Terror & Suspense",
            description: "Películas de miedo, thrillers psicológicos y quedadas de fin de semana con palomitas.",
            iconEmoji: "🔪",
            creatorId: "friend_3",
            creatorName: "Mateo Rossi",
            members: [
                Friend(id: "friend_1", displayName: "Lucas Benítez", username: "@lucasfilm", avatarURL: nil, isMutual: true, mutualMoviesCount: 14),
                Friend(id: "friend_2", displayName: "Camila Vega", username: "@camicine", avatarURL: nil, isMutual: true, mutualMoviesCount: 22)
            ],
            inviteCode: "CINE-TERROR",
            currentMovieId: "945961",
            currentMovieTitle: "Alien: Romulus",
            currentMoviePosterURL: URL(string: "https://image.tmdb.org/t/p/w500/b33nnKl1GSFbao8l3KiM69fZdrS.jpg"),
            currentMovieYear: 2024,
            messagesCount: 3,
            createdAt: Date().addingTimeInterval(-86400 * 2)
        )
    ]
    
    public static let defaultMessages: [String: [GroupMessage]] = [
        "group_1": [
            GroupMessage(
                id: "msg_1_0",
                groupId: "group_1",
                userId: "system",
                userName: "Sistema",
                text: "Lucas Benítez creó el grupo «Cineclub Nolan & Sci-Fi» con Camila Vega y Mateo Rossi",
                messageType: .system,
                createdAt: Date().addingTimeInterval(-86400 * 5)
            ),
            GroupMessage(
                id: "msg_1_1",
                groupId: "group_1",
                userId: "friend_1",
                userName: "Lucas Benítez",
                text: "¡Bienvenidos al grupo! Este finde hacemos sesión conjunta para comentar Dune: Parte Dos. ¿Quién confirma?",
                createdAt: Date().addingTimeInterval(-7200)
            ),
            GroupMessage(
                id: "msg_1_2",
                groupId: "group_1",
                userId: "friend_2",
                userName: "Camila Vega",
                text: "¡Yo me apunto sin dudarlo! Ya la vi una vez pero en pantalla grande merece segunda pasada.",
                createdAt: Date().addingTimeInterval(-5400)
            ),
            GroupMessage(
                id: "msg_1_3",
                groupId: "group_1",
                userId: "friend_3",
                userName: "Mateo Rossi",
                text: "Contad conmigo. Llevo nachos y refrescos. Al terminar abrimos debate aquí.",
                createdAt: Date().addingTimeInterval(-3600)
            )
        ],
        "group_2": [
            GroupMessage(
                id: "msg_2_0",
                groupId: "group_2",
                userId: "system",
                userName: "Sistema",
                text: "Camila Vega creó el grupo «Tertulia de Clásicos Inmortales»",
                messageType: .system,
                createdAt: Date().addingTimeInterval(-86400 * 12)
            ),
            GroupMessage(
                id: "msg_2_1",
                groupId: "group_2",
                userId: "friend_2",
                userName: "Camila Vega",
                text: "Película elegida de esta semana: El Padrino (1972). Fijaos especialmente en el uso de la luz de Gordon Willis.",
                createdAt: Date().addingTimeInterval(-20000)
            ),
            GroupMessage(
                id: "msg_2_2",
                groupId: "group_2",
                userId: "friend_1",
                userName: "Lucas Benítez",
                text: "¡Obra maestra total! La escena del bautizo sigue siendo insuperable.",
                createdAt: Date().addingTimeInterval(-14000)
            )
        ],
        "group_3": [
            GroupMessage(
                id: "msg_3_0",
                groupId: "group_3",
                userId: "system",
                userName: "Sistema",
                text: "Mateo Rossi creó el grupo «Viernes de Terror & Suspense»",
                messageType: .system,
                createdAt: Date().addingTimeInterval(-86400 * 2)
            ),
            GroupMessage(
                id: "msg_3_1",
                groupId: "group_3",
                userId: "friend_3",
                userName: "Mateo Rossi",
                text: "¿Listos para pasar miedo? Vamos a ver la nueva de Alien este viernes por la noche con las luces apagadas.",
                createdAt: Date().addingTimeInterval(-10000)
            ),
            GroupMessage(
                id: "msg_3_2",
                groupId: "group_3",
                userId: "friend_2",
                userName: "Camila Vega",
                text: "¡Me encanta la saga! Espero que los efectos prácticos estén a la altura de la original.",
                createdAt: Date().addingTimeInterval(-8000)
            )
        ]
    ]
}

import Testing
import Foundation
@testable import MovieSocialApp

@Suite("Group Use Cases Tests")
struct GroupUseCasesTests {
    let groupRepo: GroupRepositoryProtocol
    let getGroupsUseCase: GetGroupsUseCase
    let createGroupUseCase: CreateGroupUseCase
    let getGroupMessagesUseCase: GetGroupMessagesUseCase
    let sendGroupMessageUseCase: SendGroupMessageUseCase
    let joinGroupUseCase: JoinGroupUseCase
    let joinGroupByInviteCodeUseCase: JoinGroupByInviteCodeUseCase
    let addMembersToGroupUseCase: AddMembersToGroupUseCase
    
    init() {
        let repo = GroupRepositoryImpl()
        self.groupRepo = repo
        self.getGroupsUseCase = GetGroupsUseCase(repository: repo)
        self.createGroupUseCase = CreateGroupUseCase(repository: repo)
        self.getGroupMessagesUseCase = GetGroupMessagesUseCase(repository: repo)
        self.sendGroupMessageUseCase = SendGroupMessageUseCase(repository: repo)
        self.joinGroupUseCase = JoinGroupUseCase(repository: repo)
        self.joinGroupByInviteCodeUseCase = JoinGroupByInviteCodeUseCase(repository: repo)
        self.addMembersToGroupUseCase = AddMembersToGroupUseCase(repository: repo)
    }
    
    @Test("Get Groups Returns Initial Cineclubs")
    func getGroupsReturnsInitialCineclubs() async throws {
        let groups = try await getGroupsUseCase.execute()
        #expect(!groups.isEmpty)
        #expect(groups.contains(where: { $0.name == "Cineclub Nolan & Sci-Fi" }))
    }
    
    @Test("Create New Movie Group")
    func createNewMovieGroup() async throws {
        let testUser = User(
            id: "user_group_creator",
            email: "creator@cine.com",
            displayName: "Martin Scorsese Fan",
            authProvider: .apple
        )
        
        let newGroup = try await createGroupUseCase.execute(
            name: "Amantes del Cine de Gángsters",
            description: "Análisis de Goodfellas, Casino y El Irlandés.",
            iconEmoji: "🔫",
            currentMovieTitle: "Uno de los nuestros",
            creator: testUser
        )
        
        #expect(newGroup.name == "Amantes del Cine de Gángsters")
        #expect(newGroup.creatorName == "Martin Scorsese Fan")
        #expect(newGroup.iconEmoji == "🔫")
        #expect(newGroup.inviteCode.starts(with: "CINE-"))
        #expect(newGroup.inviteLink.contains(newGroup.inviteCode))
        
        let groups = try await getGroupsUseCase.execute()
        #expect(groups.contains(where: { $0.id == newGroup.id }))
    }
    
    @Test("Create Group With Added Friends")
    func createGroupWithAddedFriends() async throws {
        let testUser = User(
            id: "user_group_creator",
            email: "creator@cine.com",
            displayName: "Stanley Kubrick Fan",
            authProvider: .apple
        )
        
        let friend1 = Friend(id: "f_1", displayName: "Ana García", username: "@anacine")
        let friend2 = Friend(id: "f_2", displayName: "Carlos Ruiz", username: "@carlosr")
        
        let newGroup = try await createGroupUseCase.execute(
            name: "Cinefilia Clásica 2001",
            description: "Odisea en el espacio y debates.",
            iconEmoji: "🛸",
            initialMembers: [friend1, friend2],
            creator: testUser
        )
        
        #expect(newGroup.members.count == 2)
        #expect(newGroup.totalMembersCount == 3)
        #expect(newGroup.members.contains(where: { $0.id == "f_1" }))
        #expect(newGroup.members.contains(where: { $0.id == "f_2" }))
        
        // Verifica que se genera el mensaje inicial del sistema
        let messages = try await getGroupMessagesUseCase.execute(groupId: newGroup.id)
        #expect(!messages.isEmpty)
        #expect(messages.first?.messageType == .system)
        #expect(messages.first?.text.contains("Ana García") == true)
    }
    
    @Test("Join Group Via Invite Code")
    func joinGroupViaInviteCode() async throws {
        let testUser = User(
            id: "user_via_code",
            email: "code@cine.com",
            displayName: "Invitado Por Código",
            authProvider: .google
        )
        
        let joinedGroup = try await joinGroupByInviteCodeUseCase.execute(
            inviteCodeOrLink: "CINE-NOLAN",
            user: testUser
        )
        
        #expect(joinedGroup.name == "Cineclub Nolan & Sci-Fi")
        #expect(joinedGroup.members.contains(where: { $0.id == testUser.id }))
        
        // Verifica mensaje de sistema generado al unirse por enlace
        let messages = try await getGroupMessagesUseCase.execute(groupId: joinedGroup.id)
        #expect(messages.contains(where: { $0.messageType == .system && $0.text.contains("Invitado Por Código") }))
    }
    
    @Test("Join Group Via Full Invite URL Link")
    func joinGroupViaFullInviteURLLink() async throws {
        let testUser = User(
            id: "user_via_url",
            email: "url@cine.com",
            displayName: "Invitado Por Enlace",
            authProvider: .apple
        )
        
        let joinedGroup = try await joinGroupByInviteCodeUseCase.execute(
            inviteCodeOrLink: "https://moviesocial.app/join/CINE-CLASSIC",
            user: testUser
        )
        
        #expect(joinedGroup.name == "Tertulia de Clásicos Inmortales")
        #expect(joinedGroup.members.contains(where: { $0.id == testUser.id }))
    }
    
    @Test("Add Members To Existing Group")
    func addMembersToExistingGroup() async throws {
        let newFriend = Friend(id: "new_friend_99", displayName: "Sofía Coppola Fan", username: "@sofiac")
        
        let updatedGroup = try await addMembersToGroupUseCase.execute(
            groupId: "group_3",
            friends: [newFriend]
        )
        
        #expect(updatedGroup.members.contains(where: { $0.id == "new_friend_99" }))
    }
    
    @Test("Send Message In Group Chat")
    func sendMessageInGroupChat() async throws {
        let testUser = User(
            id: "user_member",
            email: "member@cine.com",
            displayName: "Laura Cineasta",
            authProvider: .google
        )
        
        let sentMessage = try await sendGroupMessageUseCase.execute(
            groupId: "group_1",
            text: "¿A qué hora quedamos para ver la película?",
            user: testUser
        )
        
        #expect(sentMessage.groupId == "group_1")
        #expect(sentMessage.userName == "Laura Cineasta")
        #expect(sentMessage.text == "¿A qué hora quedamos para ver la película?")
        #expect(sentMessage.messageType == .text)
        
        let messages = try await getGroupMessagesUseCase.execute(groupId: "group_1")
        #expect(messages.contains(where: { $0.id == sentMessage.id }))
    }
    
    @Test("Send Movie Share Message In Group Chat")
    func sendMovieShareMessageInGroupChat() async throws {
        let testUser = User(
            id: "user_recommender",
            email: "rec@cine.com",
            displayName: "Pablo Crítico",
            authProvider: .apple
        )
        
        let sentMessage = try await sendGroupMessageUseCase.execute(
            groupId: "group_1",
            text: "¡Tenéis que ver esta obra de arte!",
            user: testUser,
            messageType: .movieShare,
            sharedMovieId: "238",
            sharedMovieTitle: "El Padrino",
            sharedMoviePosterURL: URL(string: "https://image.tmdb.org/t/p/w500/3bhkrj58Vtu7enYsRolD1fZdja1.jpg"),
            sharedMovieYear: 1972
        )
        
        #expect(sentMessage.groupId == "group_1")
        #expect(sentMessage.messageType == .movieShare)
        #expect(sentMessage.sharedMovieTitle == "El Padrino")
        #expect(sentMessage.sharedMovieYear == 1972)
    }
    
    @Test("Join Group Adds User To Members")
    func joinGroupAddsUserToMembers() async throws {
        let testUser = User(
            id: "user_new_joiner",
            email: "joiner@cine.com",
            displayName: "David Lynch Fan",
            authProvider: .apple
        )
        
        let updatedGroup = try await joinGroupUseCase.execute(groupId: "group_2", user: testUser)
        #expect(updatedGroup.members.contains(where: { $0.id == testUser.id }))
    }
}

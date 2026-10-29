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
    
    init() {
        let repo = GroupRepositoryImpl()
        self.groupRepo = repo
        self.getGroupsUseCase = GetGroupsUseCase(repository: repo)
        self.createGroupUseCase = CreateGroupUseCase(repository: repo)
        self.getGroupMessagesUseCase = GetGroupMessagesUseCase(repository: repo)
        self.sendGroupMessageUseCase = SendGroupMessageUseCase(repository: repo)
        self.joinGroupUseCase = JoinGroupUseCase(repository: repo)
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
        
        let groups = try await getGroupsUseCase.execute()
        #expect(groups.contains(where: { $0.id == newGroup.id }))
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
        
        let messages = try await getGroupMessagesUseCase.execute(groupId: "group_1")
        #expect(messages.contains(where: { $0.id == sentMessage.id }))
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

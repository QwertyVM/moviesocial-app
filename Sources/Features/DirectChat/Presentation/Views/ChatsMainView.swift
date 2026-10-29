import SwiftUI

public enum ChatSection: String, CaseIterable, Identifiable, Sendable {
    case direct = "Chats 1 a 1"
    case groups = "Cineclubs"
    
    public var id: String { rawValue }
}

/// Vista principal de la sección de Chats que unifica Chats One-to-One y Cineclubs / Grupos
public struct ChatsMainView: View {
    @Bindable public var directChatViewModel: DirectChatViewModel
    @Bindable public var groupsViewModel: GroupsViewModel
    public let currentUser: User?
    public let onSelectMovie: (String) -> Void
    
    @State public var selectedSection: ChatSection = .direct
    
    public init(
        directChatViewModel: DirectChatViewModel,
        groupsViewModel: GroupsViewModel,
        currentUser: User?,
        initialSection: ChatSection = .direct,
        onSelectMovie: @escaping (String) -> Void
    ) {
        self.directChatViewModel = directChatViewModel
        self.groupsViewModel = groupsViewModel
        self.currentUser = currentUser
        self._selectedSection = State(initialValue: initialSection)
        self.onSelectMovie = onSelectMovie
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.WhatsApp.chatBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Segmented control superior
                    sectionPickerView
                    
                    // Contenido según la pestaña seleccionada
                    if selectedSection == .direct {
                        DirectChatListView(
                            viewModel: directChatViewModel,
                            currentUser: currentUser,
                            onSelectMovie: onSelectMovie
                        )
                    } else {
                        GroupsListView(
                            viewModel: groupsViewModel,
                            currentUser: currentUser,
                            isEmbedded: true,
                            onSelectMovie: onSelectMovie
                        )
                    }
                }
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(selectedSection == .direct ? "CHATS DIRECTOS (1 A 1)" : "CINECLUBS Y GRUPOS")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .tracking(2)
                        .foregroundColor(.white)
                }
                
                ToolbarItemGroup(placement: .primaryAction) {
                    if selectedSection == .direct {
                        Button {
                            directChatViewModel.isStartingNewChat = true
                        } label: {
                            Image(systemName: "plus.bubble.fill")
                                .font(.system(size: 16))
                                .foregroundColor(Theme.Colors.WhatsApp.accentGreen)
                        }
                    } else {
                        Button {
                            groupsViewModel.isJoiningViaLink = true
                        } label: {
                            Image(systemName: "link.badge.plus")
                                .font(.system(size: 15))
                                .foregroundColor(Theme.Colors.WhatsApp.accentGreen)
                        }
                        
                        Button {
                            groupsViewModel.startGroupCreation()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 17))
                                .foregroundColor(Theme.Colors.WhatsApp.accentGreen)
                        }
                    }
                }
            }
            .task {
                if let user = currentUser {
                    await directChatViewModel.loadConversations(userId: user.id)
                }
                await directChatViewModel.loadFriends()
                
                if groupsViewModel.groups.isEmpty {
                    await groupsViewModel.loadGroups()
                }
                await groupsViewModel.loadFriends()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var sectionPickerView: some View {
        Picker("Sección", selection: $selectedSection) {
            let unread = directChatViewModel.totalUnreadCount
            if unread > 0 {
                Text("Chats 1 a 1 (\(unread))").tag(ChatSection.direct)
            } else {
                Text("Chats 1 a 1").tag(ChatSection.direct)
            }
            
            Text("Cineclubs (\(groupsViewModel.groups.count))").tag(ChatSection.groups)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }
}


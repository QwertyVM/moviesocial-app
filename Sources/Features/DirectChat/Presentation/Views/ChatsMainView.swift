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
                    // Segmented control superior minimalista
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
                    Text(selectedSection == .direct ? "CHATS DIRECTOS" : "CINECLUBS")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(3)
                        .foregroundColor(Theme.Colors.textTertiary)
                }
                
                ToolbarItemGroup(placement: .primaryAction) {
                    if selectedSection == .direct {
                        Button {
                            directChatViewModel.isStartingNewChat = true
                        } label: {
                            Image(systemName: "plus.bubble")
                                .font(.system(size: 15))
                                .foregroundColor(Theme.Colors.textPrimary)
                        }
                    } else {
                        Button {
                            groupsViewModel.isJoiningViaLink = true
                        } label: {
                            Image(systemName: "link")
                                .font(.system(size: 14))
                                .foregroundColor(Theme.Colors.textSecondary)
                        }
                        
                        Button {
                            groupsViewModel.startGroupCreation()
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Theme.Colors.textPrimary)
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
        HStack(spacing: 0) {
            let unread = directChatViewModel.totalUnreadCount
            let directTitle = unread > 0 ? "Directos (\(unread))" : "Directos"
            chatSectionButton(title: directTitle, section: .direct)
            chatSectionButton(title: "Cineclubs (\(groupsViewModel.groups.count))", section: .groups)
        }
        .padding(2)
        .background(Theme.Colors.surface)
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(Theme.Colors.border, lineWidth: 0.8)
        )
        .padding(.horizontal, 14)
        .padding(.top, 6)
        .padding(.bottom, 6)
    }
    
    private func chatSectionButton(title: String, section: ChatSection) -> some View {
        let isSelected = (selectedSection == section)
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedSection = section
            }
        } label: {
            Text(title)
                .font(.system(size: 12.5, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? Theme.Colors.textPrimary : Theme.Colors.textTertiary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(isSelected ? Theme.Colors.surfaceElevated : Color.clear)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

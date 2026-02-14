//
// ConversationView.swift
// MessageViewKitDemo
//
// Pure SwiftUI conversation view wrapping ConversationContentView
//

import SwiftUI

/// Pure SwiftUI conversation view that wraps the  conversation UI.
struct ConversationView: View {
    let threadId: String
    let threadName: String
    let isGroup: Bool
    let dataProvider: MockDataProvider

    @StateObject private var viewModel: ConversationViewModel
    @State private var showingInfo = false
    @State private var isContextMenuVisible = false

    init(threadId: String, threadName: String, isGroup: Bool = false, dataProvider: MockDataProvider) {
        self.threadId = threadId
        self.threadName = threadName
        self.isGroup = isGroup
        self.dataProvider = dataProvider

        let messages = dataProvider.messagesForThread(threadId: threadId)
        let vm = ConversationViewModel(messages: messages)
        vm.isGroupConversation = isGroup
        _viewModel = StateObject(wrappedValue: vm)
    }

    var body: some View {
        ConversationContentView(viewModel: viewModel, isContextMenuVisible: $isContextMenuVisible)
            .conversationStyle(.default)
            .navigationTitle(threadName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if isGroup {
                    ToolbarItem(placement: .topBarTrailing) {
                        groupToolbarButton
                    }
                } else {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showingInfo = true
                        } label: {
                            Image(systemName: "info.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingInfo) {
                if isGroup {
                    groupInfoSheet
                } else {
                    directInfoAlert
                }
            }
            .modifier(PreiOS26TabBarHiddenModifier())
            .onAppear {
                setupSendHandler()
            }
    }

    // MARK: - Group Toolbar Button

    private var groupToolbarButton: some View {
        Button {
            showingInfo = true
        } label: {
            let participants = dataProvider.participantNamesForThread(threadId: threadId)
            GroupAvatarView(participantNames: participants, size: 32)
        }
    }

    // MARK: - Group Info Sheet

    private var groupInfoSheet: some View {
        let members = dataProvider.membersForThread(threadId: threadId)
        let groupMembers = members.map { member in
            GroupMember(
                id: member.id,
                displayName: member.name,
                isAdmin: member.isAdmin,
                isCurrentUser: member.id == "me"
            )
        }

        return GroupInfoView(
            groupName: threadName,
            participantNames: dataProvider.participantNamesForThread(threadId: threadId),
            members: groupMembers,
            messageCount: viewModel.messages.count,
            onDismiss: { showingInfo = false }
        )
    }

    // MARK: - Direct Chat Info Alert

    private var directInfoAlert: some View {
        // Simple info view for direct chats
        NavigationStack {
            VStack(spacing: 20) {
                // Avatar
                let name = threadName
                ZStack {
                    Circle()
                        .fill(avatarColor(for: name))
                        .frame(width: 80, height: 80)
                    Text(initials(for: name))
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.top, 40)

                Text(name)
                    .font(.title2.weight(.bold))

                Text("\(viewModel.messages.count) messages")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showingInfo = false }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Setup

    private func setupSendHandler() {
        viewModel.onSendMessage = { [weak dataProvider] text in
            guard let dataProvider = dataProvider else { return }

            // Create a sending message
            let messageId = UUID().uuidString
            let message = MockMessage(
                uniqueId: messageId,
                sortId: UInt64(Date().timeIntervalSince1970 * 1000),
                timestamp: Date(),
                bodyText: text,
                isOutgoing: true,
                deliveryStatus: .sending,
                authorId: "me",
                authorDisplayName: "Me"
            )

            // Add to view model
            viewModel.appendMessage(message)

            // Add to data provider
            dataProvider.addMessage(message, toThread: threadId)

            // Simulate delivery after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let deliveredMessage = MockMessage(
                    uniqueId: messageId,
                    sortId: message.sortId,
                    timestamp: message.timestamp,
                    bodyText: text,
                    isOutgoing: true,
                    deliveryStatus: .delivered,
                    authorId: "me",
                    authorDisplayName: "Me"
                )
                viewModel.updateMessage(deliveredMessage)
                dataProvider.updateMessage(deliveredMessage, inThread: threadId)
            }

            // Simulate read after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                let readMessage = MockMessage(
                    uniqueId: messageId,
                    sortId: message.sortId,
                    timestamp: message.timestamp,
                    bodyText: text,
                    isOutgoing: true,
                    deliveryStatus: .read,
                    authorId: "me",
                    authorDisplayName: "Me"
                )
                viewModel.updateMessage(readMessage)
                dataProvider.updateMessage(readMessage, inThread: threadId)
            }
        }

        viewModel.onTypingStateChanged = { isTyping in
            print("User \(isTyping ? "started" : "stopped") typing in thread: \(threadId)")
        }

        // Reaction handlers
        viewModel.onReact = { [weak dataProvider, weak viewModel] emoji, messageId in
            guard let dataProvider = dataProvider, let viewModel = viewModel else {
                print("DEBUG: onReact - dataProvider or viewModel is nil")
                return
            }

            print("DEBUG: onReact called with emoji=\(emoji) messageId=\(messageId)")

            // Add reaction to data provider
            dataProvider.addReaction(emoji: emoji, toMessage: messageId, inThread: threadId)

            // Refresh view model with updated messages
            let updatedMessages = dataProvider.messagesForThread(threadId: threadId)
            print("DEBUG: Got \(updatedMessages.count) messages, reactions on target: \(updatedMessages.first { $0.uniqueId == messageId }?.reactions.count ?? -1)")
            viewModel.setMessages(updatedMessages)
            print("DEBUG: Called setMessages, viewModel.messages.count = \(viewModel.messages.count)")
        }

        viewModel.onRemoveReaction = { [weak dataProvider, weak viewModel] reaction, messageId in
            guard let dataProvider = dataProvider, let viewModel = viewModel else { return }

            // Remove reaction from data provider
            dataProvider.removeReaction(reaction, fromMessage: messageId, inThread: threadId)

            // Refresh view model with updated messages
            let updatedMessages = dataProvider.messagesForThread(threadId: threadId)
            viewModel.setMessages(updatedMessages)
        }
    }

    // MARK: - Helpers

    private func initials(for name: String) -> String {
        let words = name.split(separator: " ")
        if words.count >= 2 {
            return String(words[0].prefix(1) + words[1].prefix(1)).uppercased()
        } else if let first = name.first {
            return String(first).uppercased()
        }
        return "?"
    }

    private func avatarColor(for name: String) -> Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .red, .cyan, .indigo]
        let hash = abs(name.hashValue)
        return colors[hash % colors.count]
    }
}

private struct PreiOS26TabBarHiddenModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
        } else {
            content.toolbar(.hidden, for: .tabBar)
        }
    }
}

#Preview {
    NavigationStack {
        ConversationView(
            threadId: "preview",
            threadName: "Alice",
            dataProvider: MockDataProvider()
        )
    }
}

#Preview("Group Chat") {
    NavigationStack {
        ConversationView(
            threadId: "preview-group",
            threadName: "Weekend Hikers",
            isGroup: true,
            dataProvider: MockDataProvider()
        )
    }
}

#Preview("Arabic RTL") {
    NavigationStack {
        ConversationView(
            threadId: "preview",
            threadName: "Alice",
            dataProvider: MockDataProvider()
        )
    }
    .arabicPreview()
}

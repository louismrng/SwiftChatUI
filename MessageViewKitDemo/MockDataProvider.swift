//
// MockDataProvider.swift
// MessageViewKitDemo
//
// Combined mock data provider for threads () and messages ()
//

import Foundation
import Combine

// MARK: - Mock Data Provider

/// A combined mock data provider that supplies both thread and message data.
/// Demonstrates how to wire data sources to both ChatList and Conversation.
public class MockDataProvider: ObservableObject {

    // MARK: - Published Properties

    @Published public private(set) var threads: [MockThread] = []

    // MARK: - Private Properties

    private var updateTimer: Timer?
    private var typingTimers: [String: Timer] = [:]
    private var messageStore: [String: [MockMessage]] = [:]

    /// Group member data: threadId -> [(id, displayName, isAdmin)]
    private var groupMembersStore: [String: [(id: String, name: String, isAdmin: Bool)]] = [:]

    // MARK: - Initialization

    public init() {
        loadInitialData()
    }

    deinit {
        stopSimulation()
    }

    // MARK: - Data Loading

    public func loadInitialData() {
        threads = Self.generateMockThreads()
        messageStore = Self.generateMockMessages(for: threads)
        groupMembersStore = Self.generateGroupMembers(for: threads)
    }

    // MARK: - Thread Operations

    public func archiveThread(id: String) {
        threads.removeAll { $0.uniqueId == id }
        messageStore.removeValue(forKey: id)
    }

    public func deleteThread(id: String) {
        threads.removeAll { $0.uniqueId == id }
        messageStore.removeValue(forKey: id)
    }

    public func toggleMute(threadId: String) {
        guard let index = threads.firstIndex(where: { $0.uniqueId == threadId }) else { return }
        let thread = threads[index]
        threads[index] = thread.withUpdated(isMuted: !thread.isMuted)
    }

    public func toggleRead(threadId: String) {
        guard let index = threads.firstIndex(where: { $0.uniqueId == threadId }) else { return }
        let thread = threads[index]
        let newHasUnread = !thread.hasUnreadMessages
        threads[index] = thread.withUpdated(
            hasUnreadMessages: newHasUnread,
            unreadCount: newHasUnread ? 1 : 0
        )
    }

    public func markAsRead(threadId: String) {
        guard let index = threads.firstIndex(where: { $0.uniqueId == threadId }) else { return }
        let thread = threads[index]
        guard thread.hasUnreadMessages else { return }
        threads[index] = thread.withUpdated(hasUnreadMessages: false, unreadCount: 0)
    }

    // MARK: - Message Operations

    /// Get messages for a specific thread
    public func messagesForThread(threadId: String) -> [MockMessage] {
        return messageStore[threadId] ?? []
    }

    /// Add a new outgoing message to a thread
    public func addMessage(_ message: MockMessage, toThread threadId: String) {
        if messageStore[threadId] == nil {
            messageStore[threadId] = []
        }
        messageStore[threadId]?.append(message)

        // Update thread's last message
        updateThreadLastMessage(threadId: threadId, text: message.bodyText ?? "Photo", isOutgoing: true)
    }

    /// Update an existing message (e.g., for delivery status changes)
    public func updateMessage(_ message: MockMessage, inThread threadId: String) {
        guard let index = messageStore[threadId]?.firstIndex(where: { $0.uniqueId == message.uniqueId }) else { return }
        messageStore[threadId]?[index] = message
    }

    // MARK: - Group Operations

    /// Get members for a group thread
    public func membersForThread(threadId: String) -> [(id: String, name: String, isAdmin: Bool)] {
        return groupMembersStore[threadId] ?? []
    }

    /// Check if a thread is a group
    public func isGroupThread(threadId: String) -> Bool {
        return threads.first(where: { $0.uniqueId == threadId })?.isGroup ?? false
    }

    /// Get participant names for a thread
    public func participantNamesForThread(threadId: String) -> [String] {
        return threads.first(where: { $0.uniqueId == threadId })?.participantNames ?? []
    }

    // MARK: - Reaction Operations

    /// Add a reaction to a message
    public func addReaction(emoji: String, toMessage messageId: String, inThread threadId: String, reactorId: String = "me", reactorDisplayName: String? = "Me") {
        guard let messageIndex = messageStore[threadId]?.firstIndex(where: { $0.uniqueId == messageId }) else { return }
        let message = messageStore[threadId]![messageIndex]

        // Check if user already reacted with this emoji
        if message.reactions.contains(where: { $0.emoji == emoji && $0.reactorId == reactorId }) {
            return
        }

        let reaction = Reaction(
            emoji: emoji,
            reactorId: reactorId,
            reactorDisplayName: reactorDisplayName
        )

        let updatedMessage = MockMessage(
            uniqueId: message.uniqueId,
            sortId: message.sortId,
            timestamp: message.timestamp,
            bodyText: message.bodyText,
            image: message.image,
            isOutgoing: message.isOutgoing,
            deliveryStatus: message.deliveryStatus,
            authorId: message.authorId,
            authorDisplayName: message.authorDisplayName,
            reactions: message.reactions + [reaction]
        )
        messageStore[threadId]?[messageIndex] = updatedMessage
    }

    /// Remove a reaction from a message
    public func removeReaction(_ reaction: Reaction, fromMessage messageId: String, inThread threadId: String) {
        guard let messageIndex = messageStore[threadId]?.firstIndex(where: { $0.uniqueId == messageId }) else { return }
        let message = messageStore[threadId]![messageIndex]

        let updatedReactions = message.reactions.filter { $0.id != reaction.id }

        let updatedMessage = MockMessage(
            uniqueId: message.uniqueId,
            sortId: message.sortId,
            timestamp: message.timestamp,
            bodyText: message.bodyText,
            image: message.image,
            isOutgoing: message.isOutgoing,
            deliveryStatus: message.deliveryStatus,
            authorId: message.authorId,
            authorDisplayName: message.authorDisplayName,
            reactions: updatedReactions
        )
        messageStore[threadId]?[messageIndex] = updatedMessage
    }

    private func updateThreadLastMessage(threadId: String, text: String, isOutgoing: Bool, senderName: String? = nil) {
        guard let index = threads.firstIndex(where: { $0.uniqueId == threadId }) else { return }
        let thread = threads[index]

        let snippet: Snippet
        if thread.isGroup && !isOutgoing, let sender = senderName {
            snippet = .groupMessage(text: text, senderName: sender)
        } else {
            snippet = .message(text: text)
        }
        let status: MessageStatus? = isOutgoing ? .sent : nil

        threads[index] = thread.withUpdated(
            lastMessageDate: Date(),
            lastMessageSnippet: snippet,
            lastMessageStatus: status
        )
    }

    // MARK: - Simulation

    /// Start simulating real-time updates (new messages, typing indicators)
    public func startSimulation() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: Double.random(in: 8...15), repeats: true) { [weak self] _ in
            self?.simulateIncomingMessage()
        }
        simulateTypingIndicators()
    }

    /// Stop the simulation
    public func stopSimulation() {
        updateTimer?.invalidate()
        updateTimer = nil
        typingTimers.values.forEach { $0.invalidate() }
        typingTimers.removeAll()
    }

    private func simulateIncomingMessage() {
        guard !threads.isEmpty else { return }

        let randomIndex = Int.random(in: 0..<threads.count)
        let thread = threads[randomIndex]

        guard !thread.isNoteToSelf else { return }

        if thread.isGroup {
            simulateGroupIncomingMessage(thread: thread, at: randomIndex)
        } else {
            simulateDirectIncomingMessage(thread: thread, at: randomIndex)
        }
    }

    private func simulateDirectIncomingMessage(thread: MockThread, at index: Int) {
        let texts = [
            "Hey, what's up?",
            "Did you see that?",
            "Can you call me?",
            "Thanks!",
            "See you later!",
            "Sounds good!",
            "Just finished lunch",
            "On my way!",
        ]

        let text = texts.randomElement()!
        let snippet = Snippet.message(text: text)

        threads[index] = thread.withUpdated(
            hasUnreadMessages: true,
            unreadCount: thread.unreadCount + 1,
            lastMessageDate: Date(),
            lastMessageSnippet: snippet,
            lastMessageStatus: nil,
            isTyping: false
        )

        let newMessage = MockMessage(
            sortId: UInt64(Date().timeIntervalSince1970 * 1000),
            timestamp: Date(),
            bodyText: text,
            isOutgoing: false,
            authorId: thread.uniqueId,
            authorDisplayName: thread.displayName
        )
        messageStore[thread.uniqueId]?.append(newMessage)
    }

    private func simulateGroupIncomingMessage(thread: MockThread, at index: Int) {
        let members = groupMembersStore[thread.uniqueId] ?? []
        let otherMembers = members.filter { $0.id != "me" }
        guard let sender = otherMembers.randomElement() else { return }

        let groupTexts = [
            "Anyone free this weekend?",
            "Check out this article I found",
            "Running late, be there in 10",
            "That's hilarious 😂",
            "Good point!",
            "I agree with that",
            "Has anyone heard back yet?",
            "Let me look into it",
            "Just saw your message",
            "Can someone help me with this?",
            "Sounds like a plan!",
            "Don't forget about tomorrow",
            "Great news everyone!",
            "I'll handle that",
            "Let's discuss this later",
        ]

        let text = groupTexts.randomElement()!
        let snippet = Snippet.groupMessage(text: text, senderName: sender.name.components(separatedBy: " ").first ?? sender.name)

        threads[index] = thread.withUpdated(
            hasUnreadMessages: true,
            unreadCount: thread.unreadCount + 1,
            lastMessageDate: Date(),
            lastMessageSnippet: snippet,
            lastMessageStatus: nil,
            isTyping: false
        )

        let newMessage = MockMessage(
            sortId: UInt64(Date().timeIntervalSince1970 * 1000),
            timestamp: Date(),
            bodyText: text,
            isOutgoing: false,
            authorId: sender.id,
            authorDisplayName: sender.name
        )
        messageStore[thread.uniqueId]?.append(newMessage)
    }

    private func simulateTypingIndicators() {
        guard threads.count > 2 else { return }

        let eligibleThreads = threads.filter { !$0.isNoteToSelf && !$0.isTyping }
        guard let thread = eligibleThreads.randomElement(),
              let index = threads.firstIndex(where: { $0.uniqueId == thread.uniqueId }) else { return }

        threads[index] = thread.withUpdated(isTyping: true)

        let timer = Timer.scheduledTimer(withTimeInterval: Double.random(in: 2...4), repeats: false) { [weak self] _ in
            self?.stopTyping(threadId: thread.uniqueId)

            DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 5...12)) {
                self?.simulateTypingIndicators()
            }
        }
        typingTimers[thread.uniqueId] = timer
    }

    private func stopTyping(threadId: String) {
        guard let index = threads.firstIndex(where: { $0.uniqueId == threadId }) else { return }
        let thread = threads[index]
        threads[index] = thread.withUpdated(isTyping: false)
        typingTimers.removeValue(forKey: threadId)
    }

    // MARK: - Mock Data Generation

    /// Group definitions with member lists for realistic group simulation
    private struct GroupDefinition {
        let name: String
        let members: [(id: String, name: String, isAdmin: Bool)]
        let isPinned: Bool
        let isMuted: Bool
    }

    private static let groupDefinitions: [GroupDefinition] = [
        GroupDefinition(
            name: "Family Chat 👨‍👩‍👧‍👦",
            members: [
                (id: "me", name: "Me", isAdmin: true),
                (id: "mom", name: "Mom", isAdmin: true),
                (id: "dad", name: "Dad", isAdmin: false),
                (id: "sarah", name: "Sarah", isAdmin: false),
                (id: "mike", name: "Mike", isAdmin: false),
            ],
            isPinned: true,
            isMuted: false
        ),
        GroupDefinition(
            name: "Work Team",
            members: [
                (id: "me", name: "Me", isAdmin: false),
                (id: "alice_j", name: "Alice Johnson", isAdmin: true),
                (id: "bob_s", name: "Bob Smith", isAdmin: true),
                (id: "carol_w", name: "Carol Williams", isAdmin: false),
                (id: "david_b", name: "David Brown", isAdmin: false),
                (id: "eve_d", name: "Eve Davis", isAdmin: false),
                (id: "frank_m", name: "Frank Miller", isAdmin: false),
            ],
            isPinned: false,
            isMuted: true
        ),
        GroupDefinition(
            name: "Book Club 📚",
            members: [
                (id: "me", name: "Me", isAdmin: false),
                (id: "lisa_j", name: "Lisa Johnson", isAdmin: true),
                (id: "karen_w", name: "Karen White", isAdmin: false),
                (id: "carol_w2", name: "Carol Williams", isAdmin: false),
            ],
            isPinned: false,
            isMuted: false
        ),
        GroupDefinition(
            name: "Weekend Hikers 🥾",
            members: [
                (id: "me", name: "Me", isAdmin: true),
                (id: "jack_b", name: "Jack Black", isAdmin: false),
                (id: "joe_s", name: "Joe Smith", isAdmin: false),
                (id: "frank_m", name: "Frank Miller", isAdmin: false),
                (id: "david_b", name: "David Brown", isAdmin: false),
                (id: "alice_j", name: "Alice Johnson", isAdmin: false),
                (id: "bob_s", name: "Bob Smith", isAdmin: false),
                (id: "eve_d", name: "Eve Davis", isAdmin: false),
            ],
            isPinned: false,
            isMuted: false
        ),
        GroupDefinition(
            name: "Game Night 🎮",
            members: [
                (id: "me", name: "Me", isAdmin: false),
                (id: "jack_b", name: "Jack Black", isAdmin: true),
                (id: "bob_s", name: "Bob Smith", isAdmin: false),
                (id: "frank_m", name: "Frank Miller", isAdmin: false),
            ],
            isPinned: false,
            isMuted: false
        ),
    ]

    private static func generateMockThreads() -> [MockThread] {
        let contacts = [
            ("Alice Johnson", false),
            ("Bob Smith", false),
            ("Carol Williams", false),
            ("David Brown", false),
            ("Eve Davis", false),
            ("Frank Miller", false),
            ("Jack Black", false),
            ("Joe Smith", false),
            ("Karen White", false),
            ("Lisa Johnson", false),
        ]

        let snippets: [Snippet] = [
            .message(text: "Hey! How are you doing today?"),
            .message(text: "Did you see the game last night?"),
            .message(text: "Can you send me that file?"),
            .message(text: "Thanks for your help!"),
            .message(text: "Let's meet up soon"),
        ]

        var threads: [MockThread] = []

        // Contacts
        for i in 0..<contacts.count {
            let (name, _) = contacts[i]
            threads.append(MockThread(
                displayName: name,
                hasUnreadMessages: i % 3 == 0,
                unreadCount: i % 3 == 0 ? UInt.random(in: 1...10) : 0,
                lastMessageDate: Date().addingTimeInterval(Double(-i * 3600)),
                lastMessageSnippet: snippets[i % snippets.count],
                lastMessageStatus: [.sent, .delivered, .read].randomElement()
            ))
        }

        // Groups with rich data
        for (i, group) in groupDefinitions.enumerated() {
            let participantNames = group.members.filter { $0.id != "me" }.map { $0.name }
            let lastSender = group.members.filter { $0.id != "me" }.randomElement()

            let groupLastSnippets: [(String, String)] = [
                ("Meeting tomorrow at 3pm", lastSender?.name.components(separatedBy: " ").first ?? ""),
                ("Who's bringing the snacks?", lastSender?.name.components(separatedBy: " ").first ?? ""),
                ("Great job everyone!", lastSender?.name.components(separatedBy: " ").first ?? ""),
                ("See you all Saturday!", lastSender?.name.components(separatedBy: " ").first ?? ""),
                ("Just sent the photos", lastSender?.name.components(separatedBy: " ").first ?? ""),
            ]

            let (text, sender) = groupLastSnippets[i % groupLastSnippets.count]
            threads.append(MockThread(
                displayName: group.name,
                isGroup: true,
                isPinned: group.isPinned,
                isMuted: group.isMuted,
                hasUnreadMessages: i == 0 || i == 3,
                unreadCount: i == 0 ? 5 : (i == 3 ? 12 : 0),
                lastMessageDate: Date().addingTimeInterval(Double(-(i * 2 + 1) * 1800)),
                lastMessageSnippet: .groupMessage(text: text, senderName: sender),
                memberCount: group.members.count,
                participantNames: participantNames
            ))
        }

        // Note to Self
        threads.append(MockThread(
            displayName: "Note to Self",
            lastMessageDate: Date().addingTimeInterval(-86400),
            lastMessageSnippet: .draft(text: "Shopping list: milk, eggs, bread"),
            isNoteToSelf: true
        ))

        return threads
    }

    private static func generateGroupMembers(for threads: [MockThread]) -> [String: [(id: String, name: String, isAdmin: Bool)]] {
        var store: [String: [(id: String, name: String, isAdmin: Bool)]] = [:]

        for thread in threads where thread.isGroup {
            // Find matching group definition
            if let group = groupDefinitions.first(where: { $0.name == thread.displayName }) {
                store[thread.uniqueId] = group.members
            }
        }

        return store
    }

    private static func generateMockMessages(for threads: [MockThread]) -> [String: [MockMessage]] {
        var store: [String: [MockMessage]] = [:]
        let now = Date()
        let calendar = Calendar.current

        for thread in threads {
            if thread.isGroup {
                store[thread.uniqueId] = generateGroupMessages(for: thread, now: now, calendar: calendar)
            } else {
                store[thread.uniqueId] = generateDirectMessages(for: thread, now: now, calendar: calendar)
            }
        }

        return store
    }

    // MARK: - Direct Message Generation

    private static func generateDirectMessages(for thread: MockThread, now: Date, calendar: Calendar) -> [MockMessage] {
        var messages: [MockMessage] = []

        let messageCount = Int.random(in: 5...10)
        for i in 0..<messageCount {
            let isOutgoing = Bool.random()
            let timeOffset = -(messageCount - i) * 600
            let timestamp = calendar.date(byAdding: .second, value: timeOffset, to: now)!

            let sampleTexts = [
                "Hey, how are you?",
                "I'm good, thanks for asking!",
                "Did you see the news today?",
                "Yes, it's pretty interesting.",
                "Let's catch up soon!",
                "Sounds great!",
                "What time works for you?",
                "How about 3pm?",
                "Perfect, see you then!",
                "Great, looking forward to it!"
            ]

            var reactions: [Reaction] = []
            if i == 2 || i == 5 {
                reactions.append(Reaction(emoji: "👍", reactorId: "user1", reactorDisplayName: "Alice"))
                if i == 5 {
                    reactions.append(Reaction(emoji: "❤️", reactorId: "user2", reactorDisplayName: "Bob"))
                    reactions.append(Reaction(emoji: "😂", reactorId: "user3", reactorDisplayName: "Carol"))
                }
            }
            if i == 3 {
                reactions.append(Reaction(emoji: "❤️", reactorId: "me", reactorDisplayName: "Me"))
            }

            let message = MockMessage(
                sortId: UInt64(i + 1),
                timestamp: timestamp,
                bodyText: sampleTexts[i % sampleTexts.count],
                isOutgoing: isOutgoing,
                deliveryStatus: isOutgoing ? [.sent, .delivered, .read].randomElement()! : .sent,
                authorId: isOutgoing ? "me" : thread.uniqueId,
                authorDisplayName: isOutgoing ? "Me" : thread.displayName,
                reactions: reactions
            )
            messages.append(message)
        }

        return messages
    }

    // MARK: - Group Message Generation

    private static func generateGroupMessages(for thread: MockThread, now: Date, calendar: Calendar) -> [MockMessage] {
        guard let group = groupDefinitions.first(where: { $0.name == thread.displayName }) else {
            return generateDirectMessages(for: thread, now: now, calendar: calendar)
        }

        var messages: [MockMessage] = []
        let otherMembers = group.members.filter { $0.id != "me" }

        // Group-specific conversation templates for realistic chat flow
        let conversationFlows: [String: [[String]]] = [
            "Family Chat 👨‍👩‍👧‍👦": [
                [
                    "Hey everyone! Dinner at our place this Sunday?",
                    "Sounds great! What time?",
                    "How about 6pm?",
                    "I'll bring dessert 🍰",
                    "Perfect! I'll make pasta",
                    "Can't wait! Should I bring anything?",
                    "Just bring yourselves 😊",
                    "See you all Sunday!",
                ],
            ],
            "Work Team": [
                [
                    "Team, the client meeting is moved to Thursday",
                    "Got it, updating my calendar",
                    "Do we have the latest deck ready?",
                    "I'm finishing the slides now, will share by EOD",
                    "Make sure to include the Q3 numbers",
                    "Already on it 👍",
                    "Great teamwork everyone",
                    "Also, standup is at 10am tomorrow",
                    "Will there be a remote option?",
                    "Yes, same Zoom link as always",
                ],
            ],
            "Book Club 📚": [
                [
                    "Just finished Chapter 12! No spoilers please",
                    "Oh you're going to love the ending",
                    "The character development in this one is incredible",
                    "I cried at the part with the letter 😭",
                    "Same! So beautifully written",
                    "Should we pick the next book?",
                    "I vote for something lighter this time",
                    "How about a mystery novel?",
                ],
            ],
            "Weekend Hikers 🥾": [
                [
                    "Trail suggestion for this Saturday?",
                    "How about Eagle Peak? 8 miles roundtrip",
                    "I've done that one, it's beautiful!",
                    "What's the elevation gain?",
                    "About 2,000 feet. Moderate difficulty",
                    "I'm in! What time do we meet?",
                    "7am at the trailhead parking lot?",
                    "Early but worth it for the sunrise views 🌄",
                    "Don't forget to bring plenty of water",
                    "And sunscreen! I got burned last time 😅",
                    "I'll bring trail mix for everyone",
                    "See you all Saturday morning!",
                ],
            ],
            "Game Night 🎮": [
                [
                    "Game night this Friday?",
                    "Absolutely! My place or yours?",
                    "Let's do mine, I just got a new board game",
                    "Which one?",
                    "Wingspan! It's about birds, trust me it's fun",
                    "I've heard great things about that one",
                    "I'll bring snacks and drinks",
                    "See you at 7!",
                ],
            ],
        ]

        let flow = conversationFlows[thread.displayName]?.first ?? [
            "Hey everyone!",
            "What's new?",
            "Not much, just checking in",
            "Same here",
        ]

        // System message: group creation (at the very beginning, hours ago)
        let creationTime = calendar.date(byAdding: .hour, value: -24, to: now)!
        let adminName = group.members.first(where: { $0.isAdmin })?.name ?? "Someone"
        messages.append(MockMessage(
            sortId: 1,
            timestamp: creationTime,
            bodyText: "\(adminName) created this group",
            isOutgoing: false,
            deliveryStatus: .sent,
            authorId: "system",
            authorDisplayName: nil,
            isSystemMessage: true
        ))

        // System message: members added
        let addTime = calendar.date(byAdding: .second, value: 30, to: creationTime)!
        let memberNames = otherMembers.prefix(3).map { $0.name.components(separatedBy: " ").first ?? $0.name }
        let addedText = memberNames.count > 2
            ? "\(adminName) added \(memberNames[0]), \(memberNames[1]), and \(memberNames.count - 2) others"
            : "\(adminName) added \(memberNames.joined(separator: " and "))"
        messages.append(MockMessage(
            sortId: 2,
            timestamp: addTime,
            bodyText: addedText,
            isOutgoing: false,
            deliveryStatus: .sent,
            authorId: "system",
            authorDisplayName: nil,
            isSystemMessage: true
        ))

        // Generate conversation messages
        let startSortId: UInt64 = 10
        for (i, text) in flow.enumerated() {
            let isOutgoing = (i % 4 == 2) // Roughly 25% of messages are "yours"
            let timeOffset = -(flow.count - i) * 420 // ~7 min apart
            let timestamp = calendar.date(byAdding: .second, value: timeOffset, to: now)!

            let sender: (id: String, name: String, isAdmin: Bool)
            if isOutgoing {
                sender = (id: "me", name: "Me", isAdmin: false)
            } else {
                // Rotate through other members for variety
                sender = otherMembers[i % otherMembers.count]
            }

            // Reactions: add to some messages for realism
            var reactions: [Reaction] = []
            if i == 0 {
                // First message often gets reactions
                let reactor1 = otherMembers[(i + 1) % otherMembers.count]
                reactions.append(Reaction(emoji: "👍", reactorId: reactor1.id, reactorDisplayName: reactor1.name))
                let reactor2 = otherMembers[(i + 2) % otherMembers.count]
                reactions.append(Reaction(emoji: "❤️", reactorId: reactor2.id, reactorDisplayName: reactor2.name))
            }
            if i == flow.count - 1 && !isOutgoing {
                // Last message may get a thumbs up from "me"
                reactions.append(Reaction(emoji: "👍", reactorId: "me", reactorDisplayName: "Me"))
            }
            if i == 3 && !isOutgoing {
                let reactor = otherMembers[(i + 1) % otherMembers.count]
                reactions.append(Reaction(emoji: "😂", reactorId: reactor.id, reactorDisplayName: reactor.name))
                reactions.append(Reaction(emoji: "😂", reactorId: "me", reactorDisplayName: "Me"))
            }

            let message = MockMessage(
                sortId: startSortId + UInt64(i),
                timestamp: timestamp,
                bodyText: text,
                isOutgoing: isOutgoing,
                deliveryStatus: isOutgoing ? .read : .sent,
                authorId: sender.id,
                authorDisplayName: sender.name,
                reactions: reactions
            )
            messages.append(message)
        }

        return messages
    }
}

// MARK: - MockThread Update Helper

private extension MockThread {
    /// Creates a copy of this thread with specified properties updated.
    /// Properties not provided retain their current values.
    func withUpdated(
        isPinned: Bool? = nil,
        isMuted: Bool? = nil,
        hasUnreadMessages: Bool? = nil,
        unreadCount: UInt? = nil,
        lastMessageDate: Date?? = nil,
        lastMessageSnippet: Snippet?? = nil,
        lastMessageStatus: MessageStatus?? = nil,
        isTyping: Bool? = nil
    ) -> MockThread {
        MockThread(
            uniqueId: self.uniqueId,
            displayName: self.displayName,
            isGroup: self.isGroup,
            isPinned: isPinned ?? self.isPinned,
            isMuted: isMuted ?? self.isMuted,
            hasUnreadMessages: hasUnreadMessages ?? self.hasUnreadMessages,
            unreadCount: unreadCount ?? self.unreadCount,
            lastMessageDate: lastMessageDate ?? self.lastMessageDate,
            lastMessageSnippet: lastMessageSnippet ?? self.lastMessageSnippet,
            lastMessageStatus: lastMessageStatus ?? self.lastMessageStatus,
            isTyping: isTyping ?? self.isTyping,
            isBlocked: self.isBlocked,
            hasPendingMessageRequest: self.hasPendingMessageRequest,
            isNoteToSelf: self.isNoteToSelf,
            memberCount: self.memberCount,
            participantNames: self.participantNames
        )
    }
}

// MARK: - Helper Extension

private extension Snippet {
    var text: String {
        switch self {
        case .message(let text): return text
        case .groupMessage(let text, _): return text
        case .draft(let text): return text
        default: return ""
        }
    }
}

//
// ConversationViewModel.swift
// Conversation
//
// ObservableObject for managing conversation state in SwiftUI
//

import SwiftUI
import Combine

// MARK: - Conversation ViewModel

/// Main view model for managing conversation state in SwiftUI.
/// Use this with ConversationContentView to display a chat interface.
@MainActor
public final class ConversationViewModel: ObservableObject {

    // MARK: - Published Properties

    /// The list of messages to display
    @Published public private(set) var messages: [AnyMessage] = []

    /// Whether to show the typing indicator
    @Published public var isShowingTypingIndicator: Bool = false

    /// The current draft text in the input field
    @Published public var draftText: String = ""

    /// ID of message to scroll to (set to trigger scroll)
    @Published public var scrollToMessageId: String?

    // MARK: - Callbacks

    /// Called when the user sends a message
    public var onSendMessage: ((String) -> Void)?

    /// Called when the user starts/stops typing
    public var onTypingStateChanged: ((Bool) -> Void)?

    /// Called when the user adds a reaction (emoji, messageId)
    public var onReact: ((String, String) -> Void)?

    /// Called when the user removes a reaction (reaction, messageId)
    public var onRemoveReaction: ((Reaction, String) -> Void)?

    // MARK: - Context Menu Callbacks

    /// Called when the user selects Reply action
    public var onReply: ((AnyMessage) -> Void)?

    /// Called when the user selects Forward action
    public var onForward: ((AnyMessage) -> Void)?

    /// Called when the user selects Copy action
    public var onCopy: ((AnyMessage) -> Void)?

    /// Called when the user selects Select action
    public var onSelect: ((AnyMessage) -> Void)?

    /// Called when the user selects Info action
    public var onInfo: ((AnyMessage) -> Void)?

    /// Called when the user selects Delete action
    public var onDelete: ((AnyMessage) -> Void)?

    /// The current user's ID for identifying own reactions
    public var currentUserId: String = "me"

    /// Whether this is a group conversation (shows sender names, avatars)
    public var isGroupConversation: Bool = false

    // MARK: - Initialization

    public init(messages: [AnyMessage] = []) {
        self.messages = messages
    }

    /// Initialize with messages conforming to Message
    public convenience init<M: Message>(messages: [M]) {
        self.init(messages: messages.map { AnyMessage($0) })
    }

    // MARK: - Message Management

    /// Set all messages (replaces existing)
    public func setMessages(_ newMessages: [AnyMessage]) {
        messages = newMessages.sorted { $0.sortId < $1.sortId }
    }

    /// Set all messages from Message array
    public func setMessages<M: Message>(_ newMessages: [M]) {
        setMessages(newMessages.map { AnyMessage($0) })
    }

    /// Append a single message
    public func appendMessage(_ message: AnyMessage) {
        messages.append(message)
        messages.sort { $0.sortId < $1.sortId }
        scrollToMessageId = message.id
    }

    /// Append a message conforming to Message
    public func appendMessage<M: Message>(_ message: M) {
        appendMessage(AnyMessage(message))
    }

    /// Update an existing message by ID
    public func updateMessage(_ message: AnyMessage) {
        guard let index = messages.firstIndex(where: { $0.id == message.id }) else {
            return
        }
        messages[index] = message
    }

    /// Update an existing message conforming to Message
    public func updateMessage<M: Message>(_ message: M) {
        updateMessage(AnyMessage(message))
    }

    /// Remove a message by ID
    public func removeMessage(id: String) {
        messages.removeAll { $0.id == id }
    }

    // MARK: - Send Message

    /// Send a message with the current draft text
    public func sendMessage() {
        let text = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        draftText = ""
        onSendMessage?(text)
    }

    /// Send a message with specific text
    public func sendMessage(_ text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        onSendMessage?(trimmedText)
    }

    // MARK: - Scroll Control

    /// Scroll to the bottom of the message list
    public func scrollToBottom() {
        scrollToMessageId = messages.last?.id
    }

    /// Scroll to a specific message
    public func scrollToMessage(id: String) {
        scrollToMessageId = id
    }

    // MARK: - Typing State

    /// Update typing state and notify callback
    public func setTyping(_ isTyping: Bool) {
        onTypingStateChanged?(isTyping)
    }
}

// MARK: - Message Grouping

public extension ConversationViewModel {
    /// Group messages by date for display with date headers
    var messagesGroupedByDate: [(date: Date, messages: [AnyMessage])] {
        let calendar = Calendar.current
        var groups: [(date: Date, messages: [AnyMessage])] = []

        var currentDate: Date?
        var currentMessages: [AnyMessage] = []

        for message in messages {
            let messageDate = calendar.startOfDay(for: message.timestamp)

            if messageDate != currentDate {
                if let date = currentDate, !currentMessages.isEmpty {
                    groups.append((date: date, messages: currentMessages))
                }
                currentDate = messageDate
                currentMessages = [message]
            } else {
                currentMessages.append(message)
            }
        }

        if let date = currentDate, !currentMessages.isEmpty {
            groups.append((date: date, messages: currentMessages))
        }

        return groups
    }
}

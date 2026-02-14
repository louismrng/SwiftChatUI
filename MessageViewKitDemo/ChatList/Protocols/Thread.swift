//
// Thread.swift
// ChatList
//
// Extracted from Signal iOS - Adapter protocol for chat list threads
//

import UIKit

// MARK: - Thread Protocol

/// Minimal thread protocol for rendering in ChatList.
/// Implement this to adapt your thread/conversation model.
public protocol Thread {
    /// Unique identifier for this thread
    var uniqueId: String { get }

    /// Display name for the thread (contact name or group name)
    var displayName: String { get }

    /// Whether this is a group thread
    var isGroup: Bool { get }

    /// Whether this thread is pinned
    var isPinned: Bool { get }

    /// Whether this thread is muted
    var isMuted: Bool { get }

    /// Whether this thread has unread messages
    var hasUnreadMessages: Bool { get }

    /// Number of unread messages (0 if unknown but marked unread)
    var unreadCount: UInt { get }

    /// Date of the last message (nil if no messages)
    var lastMessageDate: Date? { get }

    /// Snippet for the last message
    var lastMessageSnippet: Snippet? { get }

    /// Delivery status of the last message (for outgoing)
    var lastMessageStatus: MessageStatus? { get }

    /// Whether someone is currently typing in this thread
    var isTyping: Bool { get }

    /// Whether the thread is blocked
    var isBlocked: Bool { get }

    /// Whether there's a pending message request
    var hasPendingMessageRequest: Bool { get }

    /// Whether this is a note-to-self thread (shows verified badge)
    var isNoteToSelf: Bool { get }

    /// Number of members in a group thread (0 for 1:1)
    var memberCount: Int { get }

    /// Display names of group participants (empty for 1:1)
    var participantNames: [String] { get }
}

// MARK: - Message Snippet

/// Represents the snippet text shown in the chat list cell
public enum Snippet: Equatable {
    /// Thread is blocked
    case blocked

    /// Pending message request with optional inviter name
    case pendingMessageRequest(addedToGroupByName: String?)

    /// Draft message
    case draft(text: String)

    /// Voice memo draft
    case voiceMemoDraft

    /// Contact (1:1) message snippet
    case message(text: String)

    /// Group message snippet with sender name
    case groupMessage(text: String, senderName: String)

    /// No snippet to display
    case none
}

// MARK: - Message Status

/// Delivery status for outgoing messages
public enum MessageStatus: Equatable {
    case uploading
    case sending
    case sent
    case delivered
    case read
    case viewed
    case failed
    case pending
    case skipped

    /// SF Symbol name for the status icon
    public var iconName: String? {
        switch self {
        case .uploading, .sending:
            return "arrow.clockwise"
        case .sent, .skipped:
            return "checkmark"
        case .delivered:
            return "checkmark.circle"
        case .read, .viewed:
            return "checkmark.circle.fill"
        case .failed:
            return "exclamationmark.circle"
        case .pending:
            return "exclamationmark.circle"
        }
    }

    /// Whether this status indicates a failure
    public var isFailure: Bool {
        self == .failed
    }

    /// Whether this status should animate (spinning)
    public var shouldAnimate: Bool {
        switch self {
        case .uploading, .sending:
            return true
        default:
            return false
        }
    }
}

// MARK: - Filter Mode

/// Filter mode for the chat list
public enum FilterMode: Equatable {
    /// Show all conversations
    case none

    /// Show only unread conversations
    case unread
}

// MARK: - Type-Erased Thread Wrapper

/// A type-erased wrapper for Thread that provides Identifiable and Equatable
/// conformance for use with SwiftUI's ForEach and List views.
public struct AnyThread: Identifiable, Equatable {
    public let id: String
    public let displayName: String
    public let isGroup: Bool
    public let isPinned: Bool
    public let isMuted: Bool
    public let hasUnreadMessages: Bool
    public let unreadCount: UInt
    public let lastMessageDate: Date?
    public let lastMessageSnippet: Snippet?
    public let lastMessageStatus: MessageStatus?
    public let isTyping: Bool
    public let isBlocked: Bool
    public let hasPendingMessageRequest: Bool
    public let isNoteToSelf: Bool
    public let memberCount: Int
    public let participantNames: [String]

    public init<T: Thread>(_ thread: T) {
        self.id = thread.uniqueId
        self.displayName = thread.displayName
        self.isGroup = thread.isGroup
        self.isPinned = thread.isPinned
        self.isMuted = thread.isMuted
        self.hasUnreadMessages = thread.hasUnreadMessages
        self.unreadCount = thread.unreadCount
        self.lastMessageDate = thread.lastMessageDate
        self.lastMessageSnippet = thread.lastMessageSnippet
        self.lastMessageStatus = thread.lastMessageStatus
        self.isTyping = thread.isTyping
        self.isBlocked = thread.isBlocked
        self.hasPendingMessageRequest = thread.hasPendingMessageRequest
        self.isNoteToSelf = thread.isNoteToSelf
        self.memberCount = thread.memberCount
        self.participantNames = thread.participantNames
    }

    public static func == (lhs: AnyThread, rhs: AnyThread) -> Bool {
        lhs.id == rhs.id &&
        lhs.displayName == rhs.displayName &&
        lhs.isGroup == rhs.isGroup &&
        lhs.isPinned == rhs.isPinned &&
        lhs.isMuted == rhs.isMuted &&
        lhs.hasUnreadMessages == rhs.hasUnreadMessages &&
        lhs.unreadCount == rhs.unreadCount &&
        lhs.lastMessageDate == rhs.lastMessageDate &&
        lhs.lastMessageSnippet == rhs.lastMessageSnippet &&
        lhs.lastMessageStatus == rhs.lastMessageStatus &&
        lhs.isTyping == rhs.isTyping &&
        lhs.isBlocked == rhs.isBlocked &&
        lhs.hasPendingMessageRequest == rhs.hasPendingMessageRequest &&
        lhs.isNoteToSelf == rhs.isNoteToSelf &&
        lhs.memberCount == rhs.memberCount &&
        lhs.participantNames == rhs.participantNames
    }
}

// MARK: - AnyThread Thread Conformance

extension AnyThread: Thread {
    public var uniqueId: String { id }
}

// MARK: - Mock Implementation for Testing

/// Simple mock thread for testing the vertical slice
public struct MockThread: Thread {
    public let uniqueId: String
    public let displayName: String
    public let isGroup: Bool
    public let isPinned: Bool
    public let isMuted: Bool
    public let hasUnreadMessages: Bool
    public let unreadCount: UInt
    public let lastMessageDate: Date?
    public let lastMessageSnippet: Snippet?
    public let lastMessageStatus: MessageStatus?
    public let isTyping: Bool
    public let isBlocked: Bool
    public let hasPendingMessageRequest: Bool
    public let isNoteToSelf: Bool
    public let memberCount: Int
    public let participantNames: [String]

    public init(
        uniqueId: String = UUID().uuidString,
        displayName: String = "Test Contact",
        isGroup: Bool = false,
        isPinned: Bool = false,
        isMuted: Bool = false,
        hasUnreadMessages: Bool = false,
        unreadCount: UInt = 0,
        lastMessageDate: Date? = Date(),
        lastMessageSnippet: Snippet? = .message(text: "Hello there!"),
        lastMessageStatus: MessageStatus? = nil,
        isTyping: Bool = false,
        isBlocked: Bool = false,
        hasPendingMessageRequest: Bool = false,
        isNoteToSelf: Bool = false,
        memberCount: Int = 0,
        participantNames: [String] = []
    ) {
        self.uniqueId = uniqueId
        self.displayName = displayName
        self.isGroup = isGroup
        self.isPinned = isPinned
        self.isMuted = isMuted
        self.hasUnreadMessages = hasUnreadMessages
        self.unreadCount = unreadCount
        self.lastMessageDate = lastMessageDate
        self.lastMessageSnippet = lastMessageSnippet
        self.lastMessageStatus = lastMessageStatus
        self.isTyping = isTyping
        self.isBlocked = isBlocked
        self.hasPendingMessageRequest = hasPendingMessageRequest
        self.isNoteToSelf = isNoteToSelf
        self.memberCount = memberCount
        self.participantNames = participantNames
    }
}

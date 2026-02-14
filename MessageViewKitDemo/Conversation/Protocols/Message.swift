//
// Message.swift
// Conversation
//
// Extracted from Signal iOS - Adapter protocol for messages
//

import UIKit

// MARK: - Message Protocol

/// Minimal message protocol for rendering in Conversation.
/// Implement this to adapt your XMPP/SIP message model.
public protocol Message {
    /// Unique identifier for this message
    var uniqueId: String { get }

    /// Sort order (typically timestamp-based)
    var sortId: UInt64 { get }

    /// When the message was sent/received
    var timestamp: Date { get }

    /// The message body text (nil for media-only messages)
    var bodyText: String? { get }

    /// The message image (nil for text-only messages)
    var image: UIImage? { get }

    /// Whether this message was sent by the local user
    var isOutgoing: Bool { get }

    /// Delivery status for outgoing messages
    var deliveryStatus: DeliveryStatus { get }

    /// Author identifier (for incoming messages in groups)
    var authorId: String { get }

    /// Author display name (resolved)
    var authorDisplayName: String? { get }

    /// Reactions on this message
    var reactions: [Reaction] { get }

    /// Whether this is a system message (e.g. "Alice added Bob to the group")
    var isSystemMessage: Bool { get }
}

// MARK: - Delivery Status

public enum DeliveryStatus: Equatable {
    case sending
    case sent
    case delivered
    case read
    case failed(String?) // Optional error message

    public var iconName: String? {
        switch self {
        case .sending: return "circle.dotted"
        case .sent: return "checkmark"
        case .delivered: return "checkmark.circle"
        case .read: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.circle"
        }
    }

    public var isFailure: Bool {
        if case .failed = self { return true }
        return false
    }
}

// MARK: - Conversation Protocol

/// Minimal conversation/thread protocol.
/// Implement this to adapt your XMPP roster or MUC.
public protocol Conversation {
    /// Unique identifier for this conversation
    var uniqueId: String { get }

    /// Display name for the conversation
    var displayName: String { get }

    /// Whether this is a group conversation (MUC)
    var isGroup: Bool { get }

    /// Participant IDs (for groups)
    var participantIds: [String] { get }
}

// MARK: - Mock Implementations for Testing

/// Simple mock message for testing the vertical slice
public struct MockMessage: Message {
    public let uniqueId: String
    public let sortId: UInt64
    public let timestamp: Date
    public let bodyText: String?
    public let image: UIImage?
    public let isOutgoing: Bool
    public let deliveryStatus: DeliveryStatus
    public let authorId: String
    public let authorDisplayName: String?
    public let reactions: [Reaction]
    public let isSystemMessage: Bool

    public init(
        uniqueId: String = UUID().uuidString,
        sortId: UInt64 = UInt64(Date().timeIntervalSince1970 * 1000),
        timestamp: Date = Date(),
        bodyText: String? = nil,
        image: UIImage? = nil,
        isOutgoing: Bool,
        deliveryStatus: DeliveryStatus = .sent,
        authorId: String = "user123",
        authorDisplayName: String? = nil,
        reactions: [Reaction] = [],
        isSystemMessage: Bool = false
    ) {
        self.uniqueId = uniqueId
        self.sortId = sortId
        self.timestamp = timestamp
        self.bodyText = bodyText
        self.image = image
        self.isOutgoing = isOutgoing
        self.deliveryStatus = deliveryStatus
        self.authorId = authorId
        self.authorDisplayName = authorDisplayName
        self.reactions = reactions
        self.isSystemMessage = isSystemMessage
    }
}

/// Simple mock conversation for testing
public struct MockConversation: Conversation {
    public let uniqueId: String
    public let displayName: String
    public let isGroup: Bool
    public let participantIds: [String]

    public init(
        uniqueId: String = UUID().uuidString,
        displayName: String = "Test Conversation",
        isGroup: Bool = false,
        participantIds: [String] = []
    ) {
        self.uniqueId = uniqueId
        self.displayName = displayName
        self.isGroup = isGroup
        self.participantIds = participantIds
    }
}

// MARK: - Type-Erased Message Wrapper for SwiftUI

/// A type-erased wrapper for Message that provides Identifiable and Equatable
/// conformance for use with SwiftUI's ForEach and List views.
public struct AnyMessage: Identifiable, Equatable {
    public let id: String
    public let sortId: UInt64
    public let timestamp: Date
    public let bodyText: String?
    public let image: UIImage?
    public let isOutgoing: Bool
    public let deliveryStatus: DeliveryStatus
    public let authorId: String
    public let authorDisplayName: String?
    public let reactions: [Reaction]
    public let isSystemMessage: Bool

    public init<M: Message>(_ message: M) {
        self.id = message.uniqueId
        self.sortId = message.sortId
        self.timestamp = message.timestamp
        self.bodyText = message.bodyText
        self.image = message.image
        self.isOutgoing = message.isOutgoing
        self.deliveryStatus = message.deliveryStatus
        self.authorId = message.authorId
        self.authorDisplayName = message.authorDisplayName
        self.reactions = message.reactions
        self.isSystemMessage = message.isSystemMessage
    }

    public static func == (lhs: AnyMessage, rhs: AnyMessage) -> Bool {
        lhs.id == rhs.id &&
        lhs.sortId == rhs.sortId &&
        lhs.timestamp == rhs.timestamp &&
        lhs.bodyText == rhs.bodyText &&
        lhs.isOutgoing == rhs.isOutgoing &&
        lhs.deliveryStatus == rhs.deliveryStatus &&
        lhs.authorId == rhs.authorId &&
        lhs.authorDisplayName == rhs.authorDisplayName &&
        lhs.reactions == rhs.reactions &&
        lhs.isSystemMessage == rhs.isSystemMessage
    }
}

// MARK: - AnyMessage Message Conformance

extension AnyMessage: Message {
    public var uniqueId: String { id }
}

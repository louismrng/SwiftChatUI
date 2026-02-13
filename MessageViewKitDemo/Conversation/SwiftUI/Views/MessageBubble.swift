//
// MessageBubble.swift
// Conversation
//
// Composite bubble view that wraps text or image content with reaction support
//

import SwiftUI

// MARK: - Message Bubble View

/// A composite view that wraps either a text bubble or image bubble
/// based on message content, with proper alignment and reaction support.
public struct MessageBubble: View {
    // MARK: - Environment

    @Environment(\.conversationStyle) private var style

    // MARK: - Properties

    let message: AnyMessage
    let isGroupConversation: Bool
    let currentUserId: String
    let coordinateSpaceName: String?
    let onReact: ((String, String) -> Void)?
    let onRemoveReaction: ((Reaction, String) -> Void)?
    let onLongPress: ((CGRect) -> Void)?

    // MARK: - State

    @State private var showingReactionDetails = false
    @State private var selectedEmojiForDetails: String?
    @State private var capturedBubbleFrame: CGRect = .zero

    // MARK: - Initialization

    public init(
        message: AnyMessage,
        isGroupConversation: Bool = false,
        currentUserId: String = "me",
        coordinateSpaceName: String? = nil,
        onReact: ((String, String) -> Void)? = nil,
        onRemoveReaction: ((Reaction, String) -> Void)? = nil,
        onLongPress: ((CGRect) -> Void)? = nil
    ) {
        self.message = message
        self.isGroupConversation = isGroupConversation
        self.currentUserId = currentUserId
        self.coordinateSpaceName = coordinateSpaceName
        self.onReact = onReact
        self.onRemoveReaction = onRemoveReaction
        self.onLongPress = onLongPress
    }

    // MARK: - Computed Properties

    private var frameCoordinateSpace: CoordinateSpace {
        if let name = coordinateSpaceName {
            return .named(name)
        }
        return .global
    }

    // MARK: - Body

    // MARK: - Sender Avatar Colors

    private static let senderColors: [Color] = [
        .blue, .green, .orange, .purple, .pink, .red, .cyan, .indigo, .mint, .teal
    ]

    private var senderColor: Color {
        let hash = abs(message.authorId.hashValue)
        return Self.senderColors[hash % Self.senderColors.count]
    }

    private var senderInitial: String {
        if let name = message.authorDisplayName, let first = name.first {
            return String(first).uppercased()
        }
        return "?"
    }

    private var showGroupSenderInfo: Bool {
        isGroupConversation && !message.isOutgoing && !message.isSystemMessage
    }

    // MARK: - Body

    public var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            if message.isOutgoing {
                Spacer(minLength: 60)
            }

            // Mini sender avatar for group incoming messages
            if showGroupSenderInfo {
                ZStack {
                    Circle()
                        .fill(senderColor)
                    Text(senderInitial)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(width: 28, height: 28)
            }

            VStack(alignment: message.isOutgoing ? .trailing : .leading, spacing: 1) {
                // Sender name label for group incoming messages
                if showGroupSenderInfo {
                    Text(message.authorDisplayName ?? "Unknown")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(senderColor)
                        .padding(.leading, 4)
                }

                bubbleWithReactions
            }

            if !message.isOutgoing {
                Spacer(minLength: showGroupSenderInfo ? 40 : 60)
            }
        }
        .padding(.horizontal, 12)
    }

    // MARK: - Bubble with Reactions

    @ViewBuilder
    private var bubbleWithReactions: some View {
        VStack(alignment: message.isOutgoing ? .trailing : .leading, spacing: 0) {
            bubbleContent
                .background(
                    GeometryReader { geometry in
                        Color.clear
                            .task(id: geometry.frame(in: frameCoordinateSpace)) {
                                capturedBubbleFrame = geometry.frame(in: frameCoordinateSpace)
                            }
                    }
                )
                .onLongPressGesture(minimumDuration: 0.3) {
                    onLongPress?(capturedBubbleFrame)
                }

            // Reaction badges below bubble
            if !message.reactions.isEmpty {
                reactionBadges
                    .offset(y: -6)
            }
        }
        .sheet(isPresented: $showingReactionDetails) {
            ReactionDetailsSheet(
                reactions: message.reactions,
                currentUserId: currentUserId,
                selectedEmoji: selectedEmojiForDetails,
                onRemoveReaction: { reaction in
                    onRemoveReaction?(reaction, message.id)
                    showingReactionDetails = false
                },
                onDismiss: {
                    showingReactionDetails = false
                }
            )
            .presentationDetents([.medium])
        }
    }

    // MARK: - Bubble Content

    @ViewBuilder
    private var bubbleContent: some View {
        if message.image != nil {
            ImageBubble(message: message)
        } else {
            TextBubble(message: message)
        }
    }

    // MARK: - Reaction Badges

    private var reactionBadges: some View {
        ReactionBadgesView(
            reactions: message.reactions,
            currentUserId: currentUserId,
            onBadgeTap: { emoji in
                selectedEmojiForDetails = emoji
                showingReactionDetails = true
            }
        )
    }
}

// MARK: - Bubble Frame Preference Key

private struct BubbleFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

// MARK: - Preview

#if DEBUG
struct MessageBubble_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            // Incoming text message
            MessageBubble(message: AnyMessage(MockMessage(
                bodyText: "Hey there!",
                isOutgoing: false
            )))

            // Outgoing text message with reactions
            MessageBubble(message: AnyMessage(MockMessage(
                bodyText: "Hi! How are you?",
                isOutgoing: true,
                deliveryStatus: .delivered,
                reactions: [
                    Reaction(emoji: "👍", reactorId: "user1", reactorDisplayName: "Alice"),
                    Reaction(emoji: "❤️", reactorId: "me", reactorDisplayName: "Me")
                ]
            )))

            // Incoming image message
            MessageBubble(message: AnyMessage(MockMessage(
                image: UIImage(systemName: "photo.fill")?
                    .withConfiguration(UIImage.SymbolConfiguration(pointSize: 100)),
                isOutgoing: false,
                reactions: [
                    Reaction(emoji: "😂", reactorId: "user2", reactorDisplayName: "Bob"),
                    Reaction(emoji: "😂", reactorId: "user3", reactorDisplayName: "Carol")
                ]
            )))

            // Outgoing image message
            MessageBubble(message: AnyMessage(MockMessage(
                image: UIImage(systemName: "photo.fill")?
                    .withConfiguration(UIImage.SymbolConfiguration(pointSize: 100)),
                isOutgoing: true,
                deliveryStatus: .read
            )))
        }
        .previewLayout(.sizeThatFits)
    }
}
#endif

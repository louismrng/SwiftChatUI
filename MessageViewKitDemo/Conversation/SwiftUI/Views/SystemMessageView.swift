//
// SystemMessageView.swift
// Conversation
//
// Centered system message bubble for group events (joins, leaves, etc.)
//

import SwiftUI

// MARK: - System Message View

/// Displays a centered, pill-shaped system message for group events.
/// Used for messages like "Alice added Bob", "Carol left the group", etc.
public struct SystemMessageView: View {
    let message: AnyMessage

    public init(message: AnyMessage) {
        self.message = message
    }

    public var body: some View {
        HStack {
            Spacer()

            Text(message.bodyText ?? "")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color(UIColor.systemGray6))
                )

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 8) {
        SystemMessageView(message: AnyMessage(MockMessage(
            bodyText: "Alice created this group",
            isOutgoing: false,
            isSystemMessage: true
        )))

        SystemMessageView(message: AnyMessage(MockMessage(
            bodyText: "Bob joined the group",
            isOutgoing: false,
            isSystemMessage: true
        )))

        SystemMessageView(message: AnyMessage(MockMessage(
            bodyText: "Carol changed the group name to \"Weekend Hikers\"",
            isOutgoing: false,
            isSystemMessage: true
        )))
    }
    .padding()
}

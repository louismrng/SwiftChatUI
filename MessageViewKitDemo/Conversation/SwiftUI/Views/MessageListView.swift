//
// MessageListView.swift
// Conversation
//
// Scrolling message list with date headers and typing indicator
//

import SwiftUI

// MARK: - Message List View

/// A scrolling list of messages grouped by date.
/// Supports scroll-to-bottom and typing indicator.
public struct MessageListView: View {
    // MARK: - Environment

    @Environment(\.conversationStyle) private var style

    // MARK: - Properties

    @ObservedObject var viewModel: ConversationViewModel
    @FocusState.Binding var isInputFocused: Bool
    let coordinateSpaceName: String?
    let onLongPress: ((AnyMessage, CGRect) -> Void)?

    // MARK: - Initialization

    public init(
        viewModel: ConversationViewModel,
        isInputFocused: FocusState<Bool>.Binding,
        coordinateSpaceName: String? = nil,
        onLongPress: ((AnyMessage, CGRect) -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self._isInputFocused = isInputFocused
        self.coordinateSpaceName = coordinateSpaceName
        self.onLongPress = onLongPress
    }

    // MARK: - Body

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 4) {
                    messageContent
                }
                .padding(.vertical, 8)
            }
            .contentShape(Rectangle())
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture {
                isInputFocused = false
            }
            .onChange(of: viewModel.scrollToMessageId) { _, messageId in
                if let messageId = messageId {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(messageId, anchor: .bottom)
                    }
                    viewModel.scrollToMessageId = nil
                }
            }
        }
    }

    // MARK: - Message Content

    @ViewBuilder
    private var messageContent: some View {
        ForEach(viewModel.messagesGroupedByDate, id: \.date) { group in
            // Date header
            DateHeader(date: group.date)

            // Messages in this group
            ForEach(group.messages) { message in
                if message.isSystemMessage {
                    SystemMessageView(message: message)
                        .id(message.id)
                } else {
                    MessageBubble(
                        message: message,
                        isGroupConversation: viewModel.isGroupConversation,
                        currentUserId: viewModel.currentUserId,
                        coordinateSpaceName: coordinateSpaceName,
                        onReact: { emoji, messageId in viewModel.onReact?(emoji, messageId) },
                        onRemoveReaction: { reaction, messageId in viewModel.onRemoveReaction?(reaction, messageId) },
                        onLongPress: { frame in onLongPress?(message, frame) }
                    )
                    .id("\(message.id)-\(message.reactions.count)-\(message.reactions.map(\.emoji).joined())")
                }
            }
        }

        // Typing indicator
        if viewModel.isShowingTypingIndicator {
            TypingIndicator()
                .id("typing-indicator")
        }
    }
}

// MARK: - Preview

#if DEBUG
struct MessageListView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ConversationViewModel(messages: [
            MockMessage(
                sortId: 1,
                timestamp: Date().addingTimeInterval(-3600),
                bodyText: "Hey there!",
                isOutgoing: false
            ),
            MockMessage(
                sortId: 2,
                timestamp: Date().addingTimeInterval(-3000),
                bodyText: "Hi! How are you?",
                isOutgoing: true,
                deliveryStatus: .read
            ),
            MockMessage(
                sortId: 3,
                timestamp: Date().addingTimeInterval(-2400),
                bodyText: "I'm doing well, thanks for asking!",
                isOutgoing: false
            )
        ])

        return PreviewContainer(viewModel: viewModel)
            .previewLayout(.sizeThatFits)
            .frame(height: 400)
    }

    struct PreviewContainer: View {
        @FocusState private var isInputFocused: Bool
        let viewModel: ConversationViewModel

        var body: some View {
            MessageListView(
                viewModel: viewModel,
                isInputFocused: $isInputFocused
            )
        }
    }
}
#endif

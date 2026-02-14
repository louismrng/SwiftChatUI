//
// ThreadRow.swift
// ChatList
//
// SwiftUI view for a single thread row in the chat list
//

import SwiftUI

// MARK: - Thread Row Content View

/// Content view for a single row in the chat list.
/// Used inside NavigationLink; does not handle tap itself.
public struct ThreadRowContent: View {
    @Environment(\.chatListStyle) private var style

    let thread: AnyThread
    let isSelected: Bool

    public init(thread: AnyThread, isSelected: Bool = false) {
        self.thread = thread
        self.isSelected = isSelected
    }

    public var body: some View {
        HStack(spacing: style.avatarContentSpacing) {
            // Avatar
            avatarView

            // Content
            VStack(alignment: .leading, spacing: 1) {
                topRow
                bottomRow
            }
        }
        .padding(.vertical, 7)
        .contentShape(Rectangle())
        .listRowBackground(isSelected ? style.selectedBackgroundColor : nil)
    }

    // MARK: - Avatar

    @ViewBuilder
    private var avatarView: some View {
        if thread.isGroup {
            GroupAvatarView(
                participantNames: thread.participantNames,
                size: style.avatarSize
            )
        } else {
            // Placeholder avatar - in real integration this would bridge to ConversationAvatarView
            ZStack {
                Circle()
                    .fill(avatarBackgroundColor)

                Text(avatarInitials)
                    .font(.system(size: style.avatarSize * 0.4, weight: .medium))
                    .foregroundColor(.white)
            }
            .frame(width: style.avatarSize, height: style.avatarSize)
        }
    }

    private var avatarInitials: String {
        let name = thread.displayName
        let words = name.split(separator: " ")
        if words.count >= 2 {
            return String(words[0].prefix(1) + words[1].prefix(1)).uppercased()
        } else if let first = name.first {
            return String(first).uppercased()
        }
        return "?"
    }

    private var avatarBackgroundColor: Color {
        // Generate a consistent color based on the thread ID
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .red, .cyan, .indigo]
        let hash = abs(thread.id.hashValue)
        return colors[hash % colors.count]
    }

    // MARK: - Top Row

    private var topRow: some View {
        HStack(spacing: 6) {
            // Name
            Text(displayName)
                .font(style.nameFont)
                .foregroundColor(style.primaryTextColor)
                .lineLimit(1)

            // Verified badge (for note-to-self)
            if thread.isNoteToSelf {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: style.iconSize))
                    .foregroundColor(style.accentColor)
            }

            // Mute indicator
            if shouldShowMuteIndicator {
                Image(systemName: "bell.slash.fill")
                    .font(.system(size: style.iconSize))
                    .foregroundColor(style.muteIconColor)
            }

            Spacer(minLength: 0)

            // Date/time
            if let date = thread.lastMessageDate {
                Text(formatDate(date))
                    .font(style.dateFont)
                    .foregroundColor(style.secondaryTextColor)
            }
        }
    }

    private var displayName: String {
        if thread.isNoteToSelf {
            return String(localized: "thread.note_to_self")
        }
        return thread.displayName.isEmpty ? String(localized: "thread.new_group") : thread.displayName
    }

    private var shouldShowMuteIndicator: Bool {
        thread.isMuted && !thread.isBlocked && !thread.hasPendingMessageRequest
    }

    // MARK: - Bottom Row

    private var bottomRow: some View {
        HStack(spacing: 6) {
            // Snippet or typing indicator
            if thread.isTyping {
                ThreadTypingIndicator()
            } else {
                snippetText
                    .font(style.snippetFont)
                    .foregroundColor(style.secondaryTextColor)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            // Message status indicator
            if let status = thread.lastMessageStatus, !thread.hasUnreadMessages {
                messageStatusIcon(for: status)
            }

            // Unread badge
            if thread.hasUnreadMessages {
                UnreadBadge(count: thread.unreadCount)
            }
        }
    }

    @ViewBuilder
    private var snippetText: some View {
        if let snippet = thread.lastMessageSnippet {
            switch snippet {
            case .blocked:
                Text("thread.snippet.blocked")
                    .italic()

            case .pendingMessageRequest(let addedBy):
                if let addedBy = addedBy {
                    Text("thread.snippet.added_to_group \(addedBy)")
                } else {
                    Text("thread.snippet.message_request")
                }

            case .draft(let text):
                (Text("thread.snippet.draft_prefix").italic() + Text(text))

            case .voiceMemoDraft:
                (Text("thread.snippet.draft_prefix").italic() + Text("thread.snippet.voice_message"))

            case .message(let text):
                Text(text)

            case .groupMessage(let text, let senderName):
                (Text("\(senderName): ").bold() + Text(text))

            case .none:
                Text("")
            }
        } else {
            Text("")
        }
    }

    @ViewBuilder
    private func messageStatusIcon(for status: MessageStatus) -> some View {
        if let iconName = status.iconName {
            Image(systemName: iconName)
                .font(.system(size: 14))
                .foregroundColor(style.readReceiptColor(for: status))
                .rotationEffect(status.shouldAnimate ? .degrees(360) : .zero)
                .animation(
                    status.shouldAnimate
                        ? .linear(duration: 1).repeatForever(autoreverses: false)
                        : .default,
                    value: status.shouldAnimate
                )
        }
    }

    // MARK: - Date Formatting

    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return formatTime(date)
        } else if calendar.isDateInYesterday(date) {
            return String(localized: "thread.date.yesterday")
        } else if let daysAgo = calendar.dateComponents([.day], from: date, to: Date()).day, daysAgo < 7 {
            return formatWeekday(date)
        } else {
            return formatShortDate(date)
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }

    private func formatWeekday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    private func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Typing Indicator

/// Simple animated typing indicator
struct ThreadTypingIndicator: View {
    @State private var animationPhase = 0

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.secondary)
                    .frame(width: 6, height: 6)
                    .scaleEffect(animationPhase == index ? 1.2 : 0.8)
                    .animation(
                        .easeInOut(duration: 0.4)
                            .repeatForever()
                            .delay(Double(index) * 0.15),
                        value: animationPhase
                    )
            }
        }
        .onAppear {
            animationPhase = 1
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        ThreadRowContent(
            thread: AnyThread(MockThread(
                displayName: "Alice Johnson",
                hasUnreadMessages: true,
                unreadCount: 3,
                lastMessageDate: Date(),
                lastMessageSnippet: .message(text: "Hey, are you coming to the party tonight?")
            ))
        )

        Divider()

        ThreadRowContent(
            thread: AnyThread(MockThread(
                displayName: "Work Group",
                isGroup: true,
                isMuted: true,
                lastMessageDate: Date().addingTimeInterval(-3600),
                lastMessageSnippet: .groupMessage(text: "Meeting at 3pm", senderName: "Bob"),
                lastMessageStatus: .delivered
            ))
        )

        Divider()

        ThreadRowContent(
            thread: AnyThread(MockThread(
                displayName: "Note to Self",
                lastMessageDate: Date().addingTimeInterval(-86400),
                lastMessageSnippet: .draft(text: "Remember to buy milk"),
                lastMessageStatus: nil,
                isNoteToSelf: true
            ))
        )
    }
    .chatListStyle(.default)
}

#Preview("Arabic RTL") {
    VStack(spacing: 0) {
        ThreadRowContent(
            thread: AnyThread(MockThread(
                displayName: "Alice Johnson",
                hasUnreadMessages: true,
                unreadCount: 3,
                lastMessageDate: Date(),
                lastMessageSnippet: .message(text: "Hey, are you coming to the party tonight?")
            ))
        )

        Divider()

        ThreadRowContent(
            thread: AnyThread(MockThread(
                displayName: "Work Group",
                isGroup: true,
                isMuted: true,
                lastMessageDate: Date().addingTimeInterval(-3600),
                lastMessageSnippet: .groupMessage(text: "Meeting at 3pm", senderName: "Bob"),
                lastMessageStatus: .delivered
            ))
        )

        Divider()

        ThreadRowContent(
            thread: AnyThread(MockThread(
                displayName: "Note to Self",
                lastMessageDate: Date().addingTimeInterval(-86400),
                lastMessageSnippet: .draft(text: "Remember to buy milk"),
                lastMessageStatus: nil,
                isNoteToSelf: true
            ))
        )
    }
    .chatListStyle(.default)
    .arabicPreview()
}

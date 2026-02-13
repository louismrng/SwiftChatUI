//
// GroupInfoView.swift
// Conversation
//
// Group info sheet with member list, shared media, and settings (Signal/WhatsApp style)
//

import SwiftUI

// MARK: - Group Member

/// Represents a member in a group for display purposes.
public struct GroupMember: Identifiable {
    public let id: String
    public let displayName: String
    public let isAdmin: Bool
    public let isCurrentUser: Bool

    public init(id: String, displayName: String, isAdmin: Bool = false, isCurrentUser: Bool = false) {
        self.id = id
        self.displayName = displayName
        self.isAdmin = isAdmin
        self.isCurrentUser = isCurrentUser
    }
}

// MARK: - Group Info View

/// A full-screen group info view styled like Signal/WhatsApp.
/// Shows group avatar, name, member list, shared media, and group actions.
public struct GroupInfoView: View {
    let groupName: String
    let participantNames: [String]
    let members: [GroupMember]
    let messageCount: Int
    let onDismiss: () -> Void

    private static let avatarColors: [Color] = [
        .blue, .green, .orange, .purple, .pink, .red, .cyan, .indigo, .mint, .teal
    ]

    public init(
        groupName: String,
        participantNames: [String],
        members: [GroupMember],
        messageCount: Int,
        onDismiss: @escaping () -> Void
    ) {
        self.groupName = groupName
        self.participantNames = participantNames
        self.members = members
        self.messageCount = messageCount
        self.onDismiss = onDismiss
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Group Header
                    groupHeader
                        .padding(.top, 20)
                        .padding(.bottom, 24)

                    // Quick Actions
                    quickActionsRow
                        .padding(.bottom, 16)

                    // Description
                    descriptionSection

                    // Members Section
                    membersSection

                    // Shared Media Section
                    sharedMediaSection

                    // Group Actions
                    groupActionsSection
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Group Header

    private var groupHeader: some View {
        VStack(spacing: 10) {
            GroupAvatarView(participantNames: participantNames, size: 80)
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)

            Text(groupName)
                .font(.title2.weight(.bold))

            Text("\(members.count) members")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Quick Actions

    private var quickActionsRow: some View {
        HStack(spacing: 20) {
            quickActionButton(icon: "bell.slash", label: "Mute")
            quickActionButton(icon: "magnifyingglass", label: "Search")
            quickActionButton(icon: "phone", label: "Call")
            quickActionButton(icon: "video", label: "Video")
        }
        .padding(.horizontal, 24)
    }

    private func quickActionButton(icon: String, label: String) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(Color(UIColor.systemGray5))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 17))
                    .foregroundColor(.primary)
            }

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Description Section

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionBackground {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Add group description")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .padding(.bottom, 24)
    }

    // MARK: - Members Section

    private var membersSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("MEMBERS")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
                .padding(.bottom, 6)

            sectionBackground {
                VStack(spacing: 0) {
                    // Add members row
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 40, height: 40)

                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        }

                        Text("Add members")
                            .font(.body)
                            .foregroundColor(.accentColor)

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                    Divider()
                        .padding(.leading, 68)

                    // Invite link row
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 40, height: 40)

                            Image(systemName: "link")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        }

                        Text("Invite via link")
                            .font(.body)
                            .foregroundColor(.accentColor)

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                    // Member list
                    ForEach(members) { member in
                        Divider()
                            .padding(.leading, 68)

                        memberRow(member: member)
                    }
                }
            }
        }
        .padding(.bottom, 24)
    }

    private func memberRow(member: GroupMember) -> some View {
        HStack(spacing: 12) {
            // Member avatar
            ZStack {
                Circle()
                    .fill(colorForName(member.displayName))
                    .frame(width: 40, height: 40)

                Text(initialsFor(member.displayName))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(member.isCurrentUser ? "You" : member.displayName)
                        .font(.body)

                    if member.isAdmin {
                        Text("Admin")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color(UIColor.systemGray5))
                            )
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Shared Media Section

    private var sharedMediaSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("SHARED MEDIA")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
                .padding(.bottom, 6)

            sectionBackground {
                VStack(spacing: 0) {
                    mediaRow(icon: "photo.on.rectangle", label: "Media", count: "\(messageCount)")
                    Divider().padding(.leading, 52)
                    mediaRow(icon: "doc", label: "Documents", count: "0")
                    Divider().padding(.leading, 52)
                    mediaRow(icon: "link", label: "Links", count: "0")
                }
            }
        }
        .padding(.bottom, 24)
    }

    private func mediaRow(icon: String, label: String, count: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 17))
                .foregroundColor(.accentColor)
                .frame(width: 28)

            Text(label)
                .font(.body)

            Spacer()

            Text(count)
                .font(.body)
                .foregroundColor(.secondary)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Group Actions Section

    private var groupActionsSection: some View {
        VStack(spacing: 0) {
            sectionBackground {
                VStack(spacing: 0) {
                    actionRow(icon: "rectangle.portrait.and.arrow.right", label: "Exit Group", color: .red)
                    Divider().padding(.leading, 52)
                    actionRow(icon: "hand.raised", label: "Report Group", color: .red)
                }
            }
        }
        .padding(.bottom, 40)
    }

    private func actionRow(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 17))
                .foregroundColor(color)
                .frame(width: 28)

            Text(label)
                .font(.body)
                .foregroundColor(color)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Section Background

    private func sectionBackground<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 16)
    }

    // MARK: - Helpers

    private func initialsFor(_ name: String) -> String {
        let words = name.split(separator: " ")
        if words.count >= 2 {
            return String(words[0].prefix(1) + words[1].prefix(1)).uppercased()
        } else if let first = name.first {
            return String(first).uppercased()
        }
        return "?"
    }

    private func colorForName(_ name: String) -> Color {
        let hash = abs(name.hashValue)
        return Self.avatarColors[hash % Self.avatarColors.count]
    }
}

// MARK: - Preview

#Preview("Group Info") {
    GroupInfoView(
        groupName: "Family Chat",
        participantNames: ["Alice Johnson", "Bob Smith", "Carol Williams", "David Brown"],
        members: [
            GroupMember(id: "me", displayName: "Me", isAdmin: true, isCurrentUser: true),
            GroupMember(id: "alice", displayName: "Alice Johnson", isAdmin: true),
            GroupMember(id: "bob", displayName: "Bob Smith"),
            GroupMember(id: "carol", displayName: "Carol Williams"),
            GroupMember(id: "david", displayName: "David Brown"),
        ],
        messageCount: 42,
        onDismiss: {}
    )
}

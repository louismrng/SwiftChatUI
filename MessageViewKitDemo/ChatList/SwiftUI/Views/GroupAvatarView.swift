//
// GroupAvatarView.swift
// ChatList
//
// Overlapping multi-avatar view for group threads (Signal/WhatsApp style)
//

import SwiftUI

// MARK: - Group Avatar View

/// Displays overlapping circular avatars for group chat participants.
/// Shows up to 4 member initials in a 2x2 grid layout for groups,
/// or a single avatar with a group icon for small groups.
public struct GroupAvatarView: View {
    let participantNames: [String]
    let size: CGFloat

    private static let avatarColors: [Color] = [
        .blue, .green, .orange, .purple, .pink, .red, .cyan, .indigo, .mint, .teal
    ]

    public init(participantNames: [String], size: CGFloat = 56) {
        self.participantNames = participantNames
        self.size = size
    }

    public var body: some View {
        if participantNames.count >= 2 {
            gridAvatarView
        } else {
            singleGroupAvatar
        }
    }

    // MARK: - Grid Layout (2x2 for 2+ members)

    private var gridAvatarView: some View {
        let members = Array(participantNames.prefix(4))
        return ZStack {
            Circle()
                .fill(Color(UIColor.systemGray5))

            if members.count == 2 {
                twoMemberLayout(members: members)
            } else if members.count == 3 {
                threeMemberLayout(members: members)
            } else {
                fourMemberLayout(members: members)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    // MARK: - Two Member Layout (side by side)

    private func twoMemberLayout(members: [String]) -> some View {
        HStack(spacing: 1.5) {
            miniAvatar(name: members[0], size: size * 0.48)
            miniAvatar(name: members[1], size: size * 0.48)
        }
    }

    // MARK: - Three Member Layout (1 top, 2 bottom)

    private func threeMemberLayout(members: [String]) -> some View {
        VStack(spacing: 1.5) {
            miniAvatar(name: members[0], size: size * 0.38)
            HStack(spacing: 1.5) {
                miniAvatar(name: members[1], size: size * 0.38)
                miniAvatar(name: members[2], size: size * 0.38)
            }
        }
    }

    // MARK: - Four Member Layout (2x2 grid)

    private func fourMemberLayout(members: [String]) -> some View {
        VStack(spacing: 1.5) {
            HStack(spacing: 1.5) {
                miniAvatar(name: members[0], size: size * 0.38)
                miniAvatar(name: members[1], size: size * 0.38)
            }
            HStack(spacing: 1.5) {
                miniAvatar(name: members[2], size: size * 0.38)
                if members.count > 3 {
                    miniAvatar(name: members[3], size: size * 0.38)
                } else {
                    moreIndicator(size: size * 0.38)
                }
            }
        }
    }

    // MARK: - Mini Avatar

    private func miniAvatar(name: String, size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(colorForName(name))

            Text(initialsFor(name))
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundColor(.white)
                .minimumScaleFactor(0.5)
        }
        .frame(width: size, height: size)
    }

    // MARK: - More Indicator

    private func moreIndicator(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(Color(UIColor.systemGray3))

            Text("+\(participantNames.count - 3)")
                .font(.system(size: size * 0.38, weight: .semibold))
                .foregroundColor(.white)
                .minimumScaleFactor(0.5)
        }
        .frame(width: size, height: size)
    }

    // MARK: - Single Group Avatar (fallback)

    private var singleGroupAvatar: some View {
        ZStack {
            Circle()
                .fill(Color.green.gradient)

            Image(systemName: "person.3.fill")
                .font(.system(size: size * 0.35))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
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

#Preview("Group Avatars") {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            GroupAvatarView(participantNames: ["Alice Johnson", "Bob Smith"], size: 56)
            GroupAvatarView(participantNames: ["Alice Johnson", "Bob Smith", "Carol Williams"], size: 56)
            GroupAvatarView(participantNames: ["Alice Johnson", "Bob Smith", "Carol Williams", "David Brown"], size: 56)
        }

        HStack(spacing: 20) {
            GroupAvatarView(participantNames: ["Alice", "Bob", "Carol", "David", "Eve", "Frank"], size: 56)
            GroupAvatarView(participantNames: [], size: 56)
            GroupAvatarView(participantNames: ["Alice Johnson", "Bob Smith"], size: 40)
        }
    }
    .padding()
}

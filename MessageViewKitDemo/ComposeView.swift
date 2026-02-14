//
// ComposeView.swift
// MessageViewKitDemo
//
// Pure SwiftUI compose view for starting new conversations
//

import SwiftUI

/// Pure SwiftUI compose view with contact list.
struct ComposeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedContact: String?
    @State private var showingConfirmation = false

    private let contacts = [
        "Alice Johnson",
        "Bob Smith",
        "Carol Williams",
        "David Brown",
        "Eve Davis",
        "Frank Miller",
        "Grace Wilson",
        "Henry Moore"
    ]

    private var filteredContacts: [String] {
        if searchText.isEmpty {
            return contacts
        }
        return contacts.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        List {
            // New Group option
            Section {
                Button {
                    // Placeholder for group creation
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 36, height: 36)
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        }
                        Text("New Group")
                            .foregroundStyle(.primary)
                    }
                }
            }

            // Contacts
            Section {
                ForEach(filteredContacts, id: \.self) { contact in
                    Button {
                        selectedContact = contact
                        showingConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                            Text(contact)
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .searchable(text: $searchText, prompt: "compose.search_prompt")
        .navigationTitle("compose.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("common.cancel") {
                    dismiss()
                }
            }
        }
        .alert("compose.start_conversation", isPresented: $showingConfirmation) {
            Button("common.cancel", role: .cancel) { }
            Button("common.start") {
                dismiss()
            }
        } message: {
            Text("compose.start_conversation_prompt \(selectedContact ?? "")")
        }
    }
}

#Preview {
    NavigationStack {
        ComposeView()
    }
}

#Preview("Arabic RTL") {
    NavigationStack {
        ComposeView()
    }
    .arabicPreview()
}

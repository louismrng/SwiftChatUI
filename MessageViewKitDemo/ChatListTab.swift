//
// ChatListTab.swift
// MessageViewKitDemo
//
// SwiftUI view wrapping the chat list with its own NavigationStack.
//

import SwiftUI

/// The Messages tab containing the chat list with navigation.
struct ChatListTab: View {
    @ObservedObject var dataProvider: MockDataProvider

    @StateObject private var viewModel = ChatListViewModel()
    @State private var navigationPath = NavigationPath()
    @State private var showingCompose = false
    @State private var searchText = ""

    var body: some View {
        NavigationStack(path: $navigationPath) {
            chatListContent
                .navigationDestination(for: String.self) { threadId in
                    let thread = dataProvider.threads.first(where: { $0.uniqueId == threadId })
                    ConversationView(
                        threadId: threadId,
                        threadName: thread?.displayName ?? String(localized: "common.chat"),
                        isGroup: thread?.isGroup ?? false,
                        dataProvider: dataProvider
                    )
                    .onAppear {
                        dataProvider.markAsRead(threadId: threadId)
                    }
                }
        }
        .modifier(iOS26TabBarModifier(isVisible: navigationPath.isEmpty))
        .sheet(isPresented: $showingCompose) {
            NavigationStack {
                ComposeView()
            }
        }
    }

    @ViewBuilder
    private var chatListContent: some View {
        ChatListView(viewModel: viewModel)
            .chatListStyle(.default)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
            .navigationTitle("chat_list.title")
            .navigationBarTitleDisplayMode(.automatic)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCompose = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .onAppear {
                setupCallbacks()
                updateThreads()
            }
            .onReceive(dataProvider.$threads) { threads in
                viewModel.setThreads(threads.map { AnyThread($0) })
            }
            .onChange(of: searchText) { _, newValue in
                viewModel.searchText = newValue
            }
    }

    // MARK: - Setup

    private func setupCallbacks() {
        viewModel.onArchiveThread = { threadId in
            dataProvider.archiveThread(id: threadId)
        }

        viewModel.onDeleteThread = { threadId in
            dataProvider.deleteThread(id: threadId)
        }

        viewModel.onToggleMuteThread = { threadId in
            dataProvider.toggleMute(threadId: threadId)
        }

        viewModel.onToggleReadThread = { threadId in
            dataProvider.toggleRead(threadId: threadId)
        }
    }

    private func updateThreads() {
        viewModel.setThreads(dataProvider.threads.map { AnyThread($0) })
    }
}

private struct iOS26TabBarModifier: ViewModifier {
    let isVisible: Bool

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .toolbar(isVisible ? .visible : .hidden, for: .tabBar)
                .animation(.easeInOut(duration: 0.25), value: isVisible)
        } else {
            content
        }
    }
}

#Preview {
    ChatListTab(dataProvider: MockDataProvider())
}

#Preview("Arabic RTL") {
    ChatListTab(dataProvider: MockDataProvider())
        .arabicPreview()
}

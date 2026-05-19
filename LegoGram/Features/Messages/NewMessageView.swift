import SwiftUI

/// Lets the user search for another BrickFeed builder and start a DM conversation.
/// Opened by tapping the compose button in DirectMessageListView.
struct NewMessageView: View {

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var dmStore = DMStore.shared

    @State private var searchText = ""
    @State private var searchResults: [User] = []
    @State private var isSearching = false
    @State private var selectedUser: User?
    @State private var navigateToThread = false
    @State private var newConversation: DMConversation?
    @State private var errorMessage: String?

    @FocusState private var searchFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    searchBar

                    if isSearching {
                        Spacer()
                        ProgressView().tint(.legoYellow).scaleEffect(1.3)
                        Spacer()
                    } else if searchText.isEmpty {
                        emptyPrompt
                    } else if searchResults.isEmpty {
                        noResultsView
                    } else {
                        resultsList
                    }
                }
            }
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.cardBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.legoYellow)
                }
            }
            .navigationDestination(isPresented: $navigateToThread) {
                if let conv = newConversation {
                    DirectMessageThreadView(conversation: conv)
                }
            }
        }
        .onAppear { searchFocused = true }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondaryText)

            TextField("Search by username…", text: $searchText)
                .foregroundColor(.lightText)
                .font(.legoBody)
                .autocorrectionDisabled()
                .autocapitalization(.none)
                .focused($searchFocused)
                .onChange(of: searchText) { _, newValue in
                    performSearch(query: newValue)
                }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    searchResults = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondaryText)
                }
            }
        }
        .padding(12)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Results List

    private var resultsList: some View {
        List {
            ForEach(searchResults) { user in
                Button {
                    startConversation(with: user)
                } label: {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.legoRed)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Text(String(user.username.prefix(1)).uppercased())
                                    .font(.legoCardTitle).foregroundColor(.white)
                            )

                        VStack(alignment: .leading, spacing: 3) {
                            Text("@\(user.username)")
                                .font(.legoCardTitle).foregroundColor(.lightText)
                            if !user.displayName.isEmpty {
                                Text(user.displayName)
                                    .font(.legoBody).foregroundColor(.secondaryText)
                            }
                        }

                        Spacer()

                        Image(systemName: "message.fill")
                            .foregroundColor(.legoYellow)
                    }
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.cardBackground)
            }
        }
        .listStyle(.plain)
        .background(Color.darkBackground)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Empty / No Results

    private var emptyPrompt: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "person.2.fill")
                .font(.system(size: 56)).foregroundColor(.secondaryText)
            Text("Find a Builder")
                .font(.legoCardTitle).foregroundColor(.lightText)
            Text("Type a username to search for builders on BrickFeed")
                .font(.legoBody).foregroundColor(.secondaryText)
                .multilineTextAlignment(.center).padding(.horizontal)
            Spacer()
        }
    }

    private var noResultsView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48)).foregroundColor(.secondaryText)
            Text("No builders found")
                .font(.legoCardTitle).foregroundColor(.lightText)
            Text("Try a different username")
                .font(.legoBody).foregroundColor(.secondaryText)
            Spacer()
        }
    }

    // MARK: - Actions

    private func performSearch(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            searchResults = []
            return
        }
        isSearching = true
        Task {
            do {
                let users = try await FirebaseService.shared.searchUsers(query: trimmed)
                let currentUid = UserSession.shared.uid
                let blockedIds = await PostStore.shared.blockedUserIDs
                let blockedNames = await PostStore.shared.blockedUsers
                await MainActor.run {
                    // Hide self and any blocked users so blocked accounts can
                    // never be DM'd (Apple Guideline 1.2).
                    searchResults = users.filter {
                        $0.id != currentUid &&
                        !blockedIds.contains($0.id) &&
                        !blockedNames.contains($0.username)
                    }
                    isSearching = false
                }
            } catch {
                await MainActor.run { isSearching = false }
            }
        }
    }

    private func startConversation(with user: User) {
        let currentUserId   = UserSession.shared.uid
        let currentUsername = UserSession.shared.username

        Task {
            do {
                let convId = try await FirebaseService.shared.getOrCreateConversation(
                    currentUserId: currentUserId,
                    currentUsername: currentUsername,
                    otherUserId: user.id,
                    otherUsername: user.username
                )
                let conv = dmStore.conversation(with: user.username, userId: user.id)
                // Update the conversation ID to match Firestore
                await MainActor.run {
                    newConversation = DMConversation(
                        id: convId,
                        otherUserId: user.id,
                        otherUsername: user.username,
                        messages: []
                    )
                    navigateToThread = true
                }
            } catch {
                await MainActor.run {
                    // Fall back to local conversation
                    newConversation = dmStore.conversation(with: user.username, userId: user.id)
                    navigateToThread = true
                }
            }
        }
    }
}

#Preview {
    NewMessageView()
}

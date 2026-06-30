import SwiftUI

/// Which side of the follow relationship a `FollowListView` shows.
enum FollowListMode {
    /// Users who follow the profile owner.
    case followers
    /// Users the profile owner follows.
    case following

    /// Navigation-bar title.
    var title: String {
        switch self {
        case .followers: return "Followers"
        case .following: return "Following"
        }
    }

    /// Shown when there are no users to list.
    var emptyMessage: String {
        switch self {
        case .followers: return "No followers yet"
        case .following: return "Not following anyone yet"
        }
    }

    /// SF Symbol for the empty state.
    var emptyIcon: String {
        switch self {
        case .followers: return "person.2.fill"
        case .following: return "person.crop.circle.badge.plus"
        }
    }
}

/// A scrollable list of the users who follow `userId` (`.followers`) or whom
/// `userId` follows (`.following`).
///
/// followers/following are stored as `users/{uid}/followers` and
/// `users/{uid}/following` subcollections whose document IDs are the *other*
/// user's UID — nothing is denormalized — so we resolve the IDs to full `User`
/// objects via `FirebaseService.fetchUsers(for:)`. Each row reuses the
/// `UserAvatar` + username layout from `UserSearchRow` and taps through to that
/// user's profile using the app-wide `String` → `OtherProfileView` navigation
/// destination (pushed by every screen that hosts a profile in its stack).
struct FollowListView: View {
    let userId: String
    let mode: FollowListMode

    @State private var users: [User] = []
    @State private var isLoading = true

    var body: some View {
        ZStack {
            Color.darkBackground.ignoresSafeArea()

            if isLoading {
                ProgressView()
                    .tint(.legoYellow)
            } else if users.isEmpty {
                emptyState
            } else {
                userList
            }
        }
        .navigationTitle(mode.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task(id: taskKey) { await load() }
    }

    // Reload whenever the profile or mode changes.
    private var taskKey: String { "\(userId)-\(mode.title)" }

    // MARK: - List

    private var userList: some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                ForEach(users) { user in
                    // Push the username onto the path — the enclosing stack's
                    // `.navigationDestination(for: String.self)` resolves it to
                    // `OtherProfileView(username:)`, the same as everywhere else.
                    NavigationLink(value: user.username) {
                        row(for: user)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color.cardBackground)
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.top, 8)

            Color.clear.frame(height: 40)
        }
    }

    private func row(for user: User) -> some View {
        HStack(spacing: 12) {
            UserAvatar(
                url: user.avatarURL,
                username: user.username,
                size: 48,
                fallbackFill: Color.legoRed,
                initialColor: .white,
                initialFont: .legoCardTitle
            )

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("@\(user.username)")
                        .font(.legoCardTitle).foregroundColor(.lightText)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    AdminBadge(uid: user.id)
                    FollowingBadge(uid: user.id)
                }
                Text("\(user.postCount) post\(user.postCount == 1 ? "" : "s")")
                    .font(.legoCaption).foregroundColor(.secondaryText)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondaryText)
        }
        .padding(12)
        .contentShape(Rectangle())
        .background(Color.cardBackground)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: mode.emptyIcon)
                .font(.system(size: 48))
                .foregroundColor(.secondaryText)
            Text(mode.emptyMessage)
                .font(.legoCardTitle).foregroundColor(.lightText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
        .padding(.horizontal, 32)
    }

    // MARK: - Loading

    private func load() async {
        guard !userId.isEmpty else {
            isLoading = false
            return
        }
        isLoading = true
        do {
            let ids: [String]
            switch mode {
            case .followers:
                ids = try await FirebaseService.shared.fetchFollowerIds(userId: userId)
            case .following:
                ids = Array(try await FirebaseService.shared.fetchFollowingIds(userId: userId))
            }
            let fetched = try await FirebaseService.shared.fetchUsers(for: ids)
            await MainActor.run {
                self.users = fetched
                self.isLoading = false
            }
        } catch {
            print("[FollowListView] load failed: \(error.localizedDescription)")
            await MainActor.run { self.isLoading = false }
        }
    }
}

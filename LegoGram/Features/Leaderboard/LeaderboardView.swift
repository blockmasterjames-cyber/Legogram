import SwiftUI

/// The Leaderboard screen — shows who the best brick builders are by total points.
/// Global leaderboard by default. Friends leaderboard available via segmented control.
/// Kid Safe Mode does NOT restrict the leaderboard (per requirements).
struct LeaderboardView: View {

    @ObservedObject private var postStore = PostStore.shared
    @ObservedObject private var userSession = UserSession.shared

    enum LeaderboardScope: String, CaseIterable {
        case global  = "Global"
        case friends = "Friends"
    }

    @State private var selectedScope: LeaderboardScope = .global
    @State private var globalBuilders: [BuilderEntry]  = []
    @State private var isLoading     = false
    @State private var loadError: String?
    @State private var selectedUsername: String?

    private var friendBuilders: [BuilderEntry] {
        let followed = postStore.followingUsernames
        return globalBuilders
            .filter { followed.contains($0.username) }
            .enumerated()
            .map { idx, e in BuilderEntry(rank: idx + 1, username: e.username,
                                          displayName: e.displayName, score: e.score,
                                          avatarURL: e.avatarURL,
                                          isCurrentUser: e.isCurrentUser) }
    }

    private var activeBuilders: [BuilderEntry] {
        selectedScope == .global ? globalBuilders : friendBuilders
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                VStack(spacing: 0) {

                    // Title
                    Text("Leaderboard")
                        .font(.legoScreenTitle)
                        .foregroundColor(.lightText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 8)

                    // Global / Friends segmented control
                    Picker("Scope", selection: $selectedScope) {
                        ForEach(LeaderboardScope.allCases, id: \.self) { scope in
                            Text(scope.rawValue).tag(scope)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.bottom, 12)

                    // Content
                    ScrollView {
                        if isLoading {
                            VStack {
                                Spacer(minLength: 60)
                                ProgressView()
                                    .tint(.legoYellow)
                                    .scaleEffect(1.5)
                                Text("Loading leaderboard…")
                                    .font(.legoCaption).foregroundColor(.secondaryText)
                                    .padding(.top, 12)
                            }
                        } else if let error = loadError {
                            VStack(spacing: 12) {
                                Image(systemName: "wifi.exclamationmark")
                                    .font(.system(size: 48)).foregroundColor(.secondaryText)
                                Text(error)
                                    .font(.legoBody).foregroundColor(.secondaryText)
                                    .multilineTextAlignment(.center)
                                Button("Try Again") { Task { await loadLeaderboard() } }
                                    .font(.legoCardTitle).foregroundColor(.legoYellow)
                            }
                            .padding(.top, 40).padding(.horizontal)
                        } else if activeBuilders.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: selectedScope == .global
                                      ? "trophy" : "person.2")
                                    .font(.system(size: 48)).foregroundColor(.secondaryText)
                                Text(selectedScope == .global
                                     ? "Be the first on the leaderboard!"
                                     : "Follow some builders to see\nthe Friends Leaderboard!")
                                    .font(.legoBody).foregroundColor(.secondaryText)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 40).padding(.horizontal)
                        } else {
                            VStack(spacing: 10) {
                                ForEach(activeBuilders) { builder in
                                    Button { selectedUsername = builder.username } label: {
                                        BuilderRow(builder: builder)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 4)
                        }

                        Color.clear.frame(height: 80)
                    }
                }
            }
            .navigationDestination(item: $selectedUsername) { username in
                OtherProfileView(username: username)
            }
        }
        .task { await loadLeaderboard() }
    }

    // MARK: - Load

    private func loadLeaderboard() async {
        print("[Leaderboard] Starting leaderboard load — uid: \(userSession.uid)")
        isLoading  = true
        loadError  = nil
        do {
            let users = try await FirebaseService.shared.fetchLeaderboard(limit: 50)
            let currentUid = userSession.uid
            print("[Leaderboard] Loaded \(users.count) users successfully")

            // If Firestore has no users yet, seed the OG accounts and reload
            if users.isEmpty {
                print("[Leaderboard] No users found — seeding OG accounts and retrying")
                await OGAccountsService.shared.seedOGAccountsToFirestoreIfNeeded()
                let seededUsers = try await FirebaseService.shared.fetchLeaderboard(limit: 50)
                print("[Leaderboard] After seeding: \(seededUsers.count) users")
                let cuid = userSession.uid
                globalBuilders = seededUsers.enumerated().map { idx, user in
                    BuilderEntry(rank: idx + 1, username: user.username,
                                 displayName: user.displayName, score: user.totalPoints,
                                 avatarURL: user.avatarURL, isCurrentUser: user.id == cuid)
                }
                isLoading = false
                return
            }

            globalBuilders = users.enumerated().map { idx, user in
                BuilderEntry(
                    rank:          idx + 1,
                    username:      user.username,
                    displayName:   user.displayName,
                    score:         user.totalPoints,
                    avatarURL:     user.avatarURL,
                    isCurrentUser: user.id == currentUid
                )
            }
            isLoading = false
        } catch {
            isLoading = false
            let detail = "\(error)"
            print("[Leaderboard] Error: \(error.localizedDescription) — Full: \(error)")
            loadError = "Couldn't load the leaderboard.\n\nError: \(error.localizedDescription)\n\nCheck your connection and try again."
        }
    }
}

// MARK: - Builder Entry Model

struct BuilderEntry: Identifiable {
    let id = UUID()
    let rank: Int
    let username: String
    let displayName: String
    let score: Int
    let avatarURL: String
    let isCurrentUser: Bool
}

// MARK: - Builder Row

struct BuilderRow: View {
    let builder: BuilderEntry

    var body: some View {
        HStack(spacing: 14) {

            // Trophy / Rank
            ZStack {
                if builder.rank <= 3 {
                    Circle()
                        .fill(medalColor(for: builder.rank))
                        .frame(width: 40, height: 40)
                    Text(trophyEmoji(for: builder.rank))
                        .font(.system(size: 20))
                } else {
                    Circle()
                        .fill(Color.cardBackground)
                        .frame(width: 40, height: 40)
                        .overlay(Circle().stroke(Color.secondaryText.opacity(0.3), lineWidth: 1))
                    Text("\(builder.rank)")
                        .font(.legoCardTitle).foregroundColor(.lightText)
                }
            }

            // Avatar
            Group {
                if !builder.avatarURL.isEmpty, let url = URL(string: builder.avatarURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().scaledToFill()
                                .frame(width: 48, height: 48).clipShape(Circle())
                        default:
                            initialCircle
                        }
                    }
                } else {
                    initialCircle
                }
            }

            // Username + score label
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("@\(builder.username)")
                        .font(.legoCardTitle).foregroundColor(.lightText)
                    if builder.isCurrentUser {
                        Text("You")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.darkBackground)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.legoYellow)
                            .cornerRadius(5)
                    }
                }
                if !builder.displayName.isEmpty {
                    Text(builder.displayName)
                        .font(.legoCaption).foregroundColor(.secondaryText)
                }
            }

            Spacer()

            // Points score with brick icon
            VStack(alignment: .trailing, spacing: 2) {
                Text(formattedScore(builder.score))
                    .font(.legoCardTitle).foregroundColor(.legoYellow)
                Text("pts")
                    .font(.legoCaption).foregroundColor(.secondaryText)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondaryText)
        }
        .padding(14)
        .background(
            builder.isCurrentUser
                ? Color.legoYellow.opacity(0.12)
                : Color.cardBackground
        )
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(builder.isCurrentUser
                        ? Color.legoYellow.opacity(0.5) : Color.clear, lineWidth: 1.5)
        )
    }

    private var initialCircle: some View {
        Circle()
            .fill(Color.legoRed.opacity(0.3))
            .frame(width: 48, height: 48)
            .overlay(
                Text(String(builder.username.prefix(1)).uppercased())
                    .font(.legoCardTitle).foregroundColor(.legoYellow)
            )
    }

    private func trophyEmoji(for rank: Int) -> String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return ""
        }
    }

    private func medalColor(for rank: Int) -> Color {
        switch rank {
        case 1: return Color(red: 1.0,  green: 0.84, blue: 0.0)  // Gold
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.75)  // Silver
        case 3: return Color(red: 0.80, green: 0.50, blue: 0.20)  // Bronze
        default: return Color.cardBackground
        }
    }

    private func formattedScore(_ score: Int) -> String {
        score >= 1_000
            ? String(format: "%.1fk", Double(score) / 1_000.0)
            : "\(score)"
    }
}

#Preview {
    LeaderboardView()
}

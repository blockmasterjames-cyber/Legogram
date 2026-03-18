import SwiftUI

/// The Leaderboard screen — shows who the best brick builders on BrickFeed are!
/// Sprint 7: Kid Safe Mode scopes the leaderboard to friends-only when ON.
struct LeaderboardView: View {

    @AppStorage("settings_kidSafeMode") private var kidSafeMode: Bool = true
    @ObservedObject private var postStore = PostStore.shared

    @State private var selectedCategory: LeaderboardCategory = .topLikes
    /// Username navigation state — set to open OtherProfileView
    @State private var selectedUsername: String?

    enum LeaderboardCategory: String, CaseIterable {
        case topLikes     = "Top Likes"
        case topFollowers = "Top Followers"
        case topBuilders  = "Top Builders"
    }

    /// All builders (global leaderboard).
    private let allBuilders: [BuilderEntry] = [
        BuilderEntry(rank: 1, username: "brickwizard",      score: 24_501),
        BuilderEntry(rank: 2, username: "legoking_max",     score: 18_342),
        BuilderEntry(rank: 3, username: "starwars_bricks",  score: 15_877),
        BuilderEntry(rank: 4, username: "castle_builder",   score: 11_209),
        BuilderEntry(rank: 5, username: "technic_tommy",    score:  9_654)
    ]

    /// Friends-only leaderboard — only builders the current user follows, re-ranked.
    private var friendBuilders: [BuilderEntry] {
        let followed = postStore.followingUsernames
        let filtered = allBuilders.filter { followed.contains($0.username) }
        // Re-rank the filtered list
        return filtered.enumerated().map { idx, entry in
            BuilderEntry(rank: idx + 1, username: entry.username, score: entry.score)
        }
    }

    /// The active list depending on Kid Safe Mode.
    private var activeBuilders: [BuilderEntry] {
        kidSafeMode ? friendBuilders : allBuilders
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                VStack(spacing: 0) {

                    // MARK: - Screen Title
                    Text("Leaderboard")
                        .font(.legoScreenTitle)
                        .foregroundColor(.lightText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 4)

                    // MARK: - Scope Label (Kid Safe Mode)
                    HStack(spacing: 6) {
                        Image(systemName: kidSafeMode ? "person.2.fill" : "globe")
                            .font(.system(size: 13))
                            .foregroundColor(.legoYellow)
                        Text(kidSafeMode ? "Friends Leaderboard" : "Global Leaderboard")
                            .font(.legoCaption)
                            .foregroundColor(.legoYellow)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.bottom, 12)

                    // MARK: - Category Tabs
                    HStack(spacing: 0) {
                        ForEach(LeaderboardCategory.allCases, id: \.self) { category in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedCategory = category
                                }
                            } label: {
                                Text(category.rawValue)
                                    .font(.legoCaption)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .foregroundColor(selectedCategory == category
                                                     ? .darkBackground : .secondaryText)
                                    .background(selectedCategory == category
                                                ? Color.legoYellow : Color.cardBackground)
                            }
                        }
                    }
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.bottom, 20)

                    // MARK: - Builder List
                    ScrollView {
                        VStack(spacing: 12) {
                            if activeBuilders.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "person.2")
                                        .font(.system(size: 48)).foregroundColor(.secondaryText)
                                    Text("Follow some builders to see the Friends Leaderboard!")
                                        .font(.legoBody).foregroundColor(.secondaryText)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.top, 40).padding(.horizontal)
                            } else {
                                ForEach(activeBuilders) { builder in
                                    Button { selectedUsername = builder.username } label: {
                                        BuilderRow(builder: builder, category: selectedCategory)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal)

                        Color.clear.frame(height: 80)
                    }
                }
            }
            .navigationDestination(item: $selectedUsername) { username in
                OtherProfileView(username: username)
            }
        }
    }
}

// MARK: - Placeholder Model

struct BuilderEntry: Identifiable {
    let id = UUID()
    let rank: Int
    let username: String
    let score: Int
}

// MARK: - Builder Row

struct BuilderRow: View {
    let builder: BuilderEntry
    let category: LeaderboardView.LeaderboardCategory

    var body: some View {
        HStack(spacing: 14) {

            // Medal / Rank
            ZStack {
                Circle()
                    .fill(medalColor(for: builder.rank))
                    .frame(width: 36, height: 36)

                if builder.rank <= 3 {
                    Image(systemName: "medal.fill")
                        .font(.system(size: 18)).foregroundColor(.white)
                } else {
                    Text("\(builder.rank)")
                        .font(.legoCardTitle).foregroundColor(.lightText)
                }
            }

            // Avatar
            Circle()
                .fill(Color.legoRed.opacity(0.3))
                .frame(width: 48, height: 48)
                .overlay(
                    Text(String(builder.username.prefix(1)).uppercased())
                        .font(.legoCardTitle).foregroundColor(.legoYellow)
                )

            // Username + score label
            VStack(alignment: .leading, spacing: 2) {
                Text("@\(builder.username)")
                    .font(.legoCardTitle).foregroundColor(.lightText)
                Text(scoreLabel(for: category))
                    .font(.legoCaption).foregroundColor(.secondaryText)
            }

            Spacer()

            // Score
            Text(formattedScore(builder.score))
                .font(.legoCardTitle).foregroundColor(.legoYellow)

            // Chevron hint — indicates tappable (Feature 10)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondaryText)
        }
        .padding(14)
        .background(Color.cardBackground)
        .cornerRadius(14)
    }

    // MARK: - Helpers

    private func medalColor(for rank: Int) -> Color {
        switch rank {
        case 1: return Color(hex: "#FFD700")
        case 2: return Color(hex: "#C0C0C0")
        case 3: return Color(hex: "#CD7F32")
        default: return Color.cardBackground
        }
    }

    private func scoreLabel(for category: LeaderboardView.LeaderboardCategory) -> String {
        switch category {
        case .topLikes:     return "total likes"
        case .topFollowers: return "followers"
        case .topBuilders:  return "builds posted"
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

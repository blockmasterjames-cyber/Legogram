import SwiftUI

/// The Leaderboard screen — shows who the best LEGO builders on LegoGram are!
/// Like a high score list in a video game, but for LEGO builds.
/// Three tabs let you sort by Likes, Followers, or total Builds posted.
struct LeaderboardView: View {

    @State private var selectedCategory: LeaderboardCategory = .topLikes

    enum LeaderboardCategory: String, CaseIterable {
        case topLikes     = "Top Likes"
        case topFollowers = "Top Followers"
        case topBuilders  = "Top Builders"
    }

    /// Placeholder leaderboard entries — real ones will come from Firebase.
    private let placeholderBuilders: [BuilderEntry] = [
        BuilderEntry(rank: 1, username: "brickwizard",    score: 24_501),
        BuilderEntry(rank: 2, username: "legoking_max",   score: 18_342),
        BuilderEntry(rank: 3, username: "starwars_bricks", score: 15_877),
        BuilderEntry(rank: 4, username: "castle_builder",  score: 11_209),
        BuilderEntry(rank: 5, username: "technic_tommy",   score: 9_654)
    ]

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
                        .padding(.bottom, 16)

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
                                    .foregroundColor(selectedCategory == category ? .darkBackground : .secondaryText)
                                    .background(
                                        selectedCategory == category
                                            ? Color.legoYellow
                                            : Color.cardBackground
                                    )
                            }
                        }
                    }
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.bottom, 20)

                    // MARK: - Builder List
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(placeholderBuilders) { builder in
                                BuilderRow(builder: builder, category: selectedCategory)
                            }
                        }
                        .padding(.horizontal)

                        // Bottom padding for tab bar
                        Color.clear.frame(height: 80)
                    }
                }
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

            // MARK: Medal / Rank
            ZStack {
                Circle()
                    .fill(medalColor(for: builder.rank))
                    .frame(width: 36, height: 36)

                if builder.rank <= 3 {
                    Image(systemName: "medal.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                } else {
                    Text("\(builder.rank)")
                        .font(.legoCardTitle)
                        .foregroundColor(.lightText)
                }
            }

            // MARK: Avatar Placeholder
            Circle()
                .fill(Color.legoRed.opacity(0.3))
                .frame(width: 48, height: 48)
                .overlay(
                    Text(String(builder.username.prefix(1)).uppercased())
                        .font(.legoCardTitle)
                        .foregroundColor(.legoYellow)
                )

            // MARK: Username
            VStack(alignment: .leading, spacing: 2) {
                Text("@\(builder.username)")
                    .font(.legoCardTitle)
                    .foregroundColor(.lightText)

                Text(scoreLabel(for: category))
                    .font(.legoCaption)
                    .foregroundColor(.secondaryText)
            }

            Spacer()

            // MARK: Score
            Text(formattedScore(builder.score))
                .font(.legoCardTitle)
                .foregroundColor(.legoYellow)
        }
        .padding(14)
        .background(Color.cardBackground)
        .cornerRadius(14)
    }

    // MARK: - Helpers
    private func medalColor(for rank: Int) -> Color {
        switch rank {
        case 1: return Color(hex: "#FFD700") // Gold
        case 2: return Color(hex: "#C0C0C0") // Silver
        case 3: return Color(hex: "#CD7F32") // Bronze
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
        if score >= 1_000 {
            let k = Double(score) / 1_000.0
            return String(format: "%.1fk", k)
        }
        return "\(score)"
    }
}

#Preview {
    LeaderboardView()
}

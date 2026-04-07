import SwiftUI

/// A fun, kid-friendly sheet explaining how BrickFeed points are earned.
/// Shows current points total and leaderboard rank.
struct PointsExplanationView: View {

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var userSession = UserSession.shared

    @State private var leaderboardRank: Int? = nil
    @State private var isLoadingRank = true

    private var currentPoints: Int {
        userSession.currentUser?.totalPoints ?? 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        // Header
                        VStack(spacing: 8) {
                            Text("🧱")
                                .font(.system(size: 56))
                            Text("How Points Work")
                                .font(.legoScreenTitle)
                                .foregroundColor(.legoYellow)
                                .multilineTextAlignment(.center)
                            Text("Earn points by building, sharing, and connecting with other LEGO fans!")
                                .font(.legoBody)
                                .foregroundColor(.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 8)

                        // Current Points Card
                        VStack(spacing: 6) {
                            Text("Your Points")
                                .font(.legoCaption)
                                .foregroundColor(.secondaryText)
                            HStack(spacing: 8) {
                                Image(systemName: "square.3.layers.3d")
                                    .font(.system(size: 24))
                                    .foregroundColor(.legoYellow)
                                Text("\(currentPoints)")
                                    .font(.system(size: 48, weight: .black, design: .rounded))
                                    .foregroundColor(.legoYellow)
                            }
                            if let rank = leaderboardRank {
                                Text("🏆 Rank #\(rank) on the Leaderboard")
                                    .font(.legoBody)
                                    .foregroundColor(.successGreen)
                            } else if isLoadingRank {
                                ProgressView().tint(.legoYellow).scaleEffect(0.8)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(20)
                        .background(Color.cardBackground)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.legoYellow.opacity(0.3), lineWidth: 1.5)
                        )
                        .padding(.horizontal)

                        // Points rules
                        VStack(alignment: .leading, spacing: 0) {
                            sectionHeader("How to Earn Points")

                            pointRow(
                                emoji: "📸",
                                title: "Post a Build",
                                subtitle: "Share your LEGO creation with the world",
                                points: "+10",
                                color: .legoRed
                            )
                            Divider().background(Color.secondaryText.opacity(0.2))

                            pointRow(
                                emoji: "❤️",
                                title: "Get a Like",
                                subtitle: "Someone likes one of your posts",
                                points: "+2",
                                color: .legoRed
                            )
                            Divider().background(Color.secondaryText.opacity(0.2))

                            pointRow(
                                emoji: "💬",
                                title: "Get a Comment",
                                subtitle: "Someone comments on your build",
                                points: "+5",
                                color: .blue
                            )
                            Divider().background(Color.secondaryText.opacity(0.2))

                            pointRow(
                                emoji: "👥",
                                title: "Get a Follower",
                                subtitle: "A new builder follows your profile",
                                points: "+1",
                                color: .successGreen
                            )
                        }
                        .background(Color.cardBackground)
                        .cornerRadius(12)
                        .padding(.horizontal)

                        // Fun tips
                        VStack(alignment: .leading, spacing: 12) {
                            sectionHeader("💡 Tips to Climb the Leaderboard")
                            tipRow("Post often — every build earns 10 points instantly!")
                            tipRow("Write great descriptions to get more comments (5 pts each!)")
                            tipRow("Follow other builders — they often follow back!")
                            tipRow("Share your biggest sets for more likes!")
                        }
                        .padding(.horizontal)

                        Color.clear.frame(height: 60)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Points")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.cardBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.legoYellow)
                }
            }
        }
        .preferredColorScheme(.dark)
        .task { await loadRank() }
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.legoCardTitle)
            .foregroundColor(.lightText)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Point Row

    private func pointRow(emoji: String, title: String, subtitle: String, points: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Text(emoji)
                .font(.system(size: 28))
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.legoCardTitle)
                    .foregroundColor(.lightText)
                Text(subtitle)
                    .font(.legoCaption)
                    .foregroundColor(.secondaryText)
            }

            Spacer()

            Text(points)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundColor(color)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Tip Row

    private func tipRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("•")
                .foregroundColor(.legoYellow)
                .font(.legoBody)
            Text(text)
                .font(.legoBody)
                .foregroundColor(.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Load Rank

    private func loadRank() async {
        guard let uid = userSession.currentUser?.id else {
            isLoadingRank = false
            return
        }
        do {
            let leaderboard = try await FirebaseService.shared.fetchLeaderboard(limit: 100)
            leaderboardRank = (leaderboard.firstIndex(where: { $0.id == uid }) ?? -1) + 1
            if leaderboardRank == 0 { leaderboardRank = nil }
        } catch {
            print("[PointsExplanationView] Rank error: \(error)")
        }
        isLoadingRank = false
    }
}

#Preview {
    PointsExplanationView()
}

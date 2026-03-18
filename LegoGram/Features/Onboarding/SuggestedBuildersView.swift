import SwiftUI

/// Shown once after onboarding completes — lets new users follow suggested accounts
/// before entering the main app. blockmasterjames (App Founder) is always listed first.
/// After tapping Done or Skip, `hasSeenSuggestedBuilders` is set to true and the
/// main ContentView is displayed. This screen never shows again.
struct SuggestedBuildersView: View {

    @AppStorage("hasSeenSuggestedBuilders") private var hasSeenSuggestedBuilders = false
    @ObservedObject private var postStore = PostStore.shared

    private let suggested: [SuggestedBuilder] = [
        SuggestedBuilder(username: "blockmasterjames",
                         displayName: "blockmasterjames",
                         bio: "App Founder and Master Builder"),
        SuggestedBuilder(username: "brickwizard",
                         displayName: "Brick Wizard",
                         bio: "Epic builds every day 🧱"),
        SuggestedBuilder(username: "starwars_bricks",
                         displayName: "Star Wars Bricks",
                         bio: "A long time ago in a brick far far away…"),
        SuggestedBuilder(username: "castle_builder",
                         displayName: "Castle Builder",
                         bio: "Medieval sets are my passion 🏰"),
    ]

    var body: some View {
        ZStack {
            Color.darkBackground.ignoresSafeArea()

            VStack(spacing: 0) {

                // MARK: - Header
                HStack {
                    Spacer()
                    Button("Skip") { finish() }
                        .font(.legoBody)
                        .foregroundColor(.secondaryText)
                        .padding(.trailing, 20)
                        .padding(.top, 16)
                }

                // MARK: - Title
                VStack(spacing: 8) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 52))
                        .foregroundColor(.legoYellow)
                        .padding(.top, 12)

                    Text("Suggested Builders")
                        .font(.legoScreenTitle)
                        .foregroundColor(.lightText)

                    Text("Follow some builders to get started!")
                        .font(.legoBody)
                        .foregroundColor(.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.bottom, 24)

                // MARK: - Builder List
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(suggested) { builder in
                            SuggestedBuilderRow(builder: builder)
                        }
                    }
                    .padding(.horizontal)
                }

                // MARK: - Done Button
                Button { finish() } label: {
                    Text("Done")
                        .font(.legoCardTitle)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.legoRed)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
    }

    private func finish() {
        hasSeenSuggestedBuilders = true
    }
}

// MARK: - Model

struct SuggestedBuilder: Identifiable {
    let id = UUID()
    let username: String
    let displayName: String
    let bio: String
}

// MARK: - Row

struct SuggestedBuilderRow: View {

    let builder: SuggestedBuilder
    @ObservedObject private var postStore = PostStore.shared

    private var isFollowing: Bool { postStore.isFollowing(builder.username) }

    var body: some View {
        HStack(spacing: 14) {

            // Avatar initial circle
            Circle()
                .fill(builder.username == "blockmasterjames"
                      ? Color.legoRed : Color.cardBackground)
                .frame(width: 52, height: 52)
                .overlay(
                    Text(String(builder.username.prefix(1)).uppercased())
                        .font(.legoCardTitle)
                        .foregroundColor(builder.username == "blockmasterjames"
                                         ? .white : .legoYellow)
                )
                .overlay(
                    Circle().stroke(
                        builder.username == "blockmasterjames"
                            ? Color.legoYellow : Color.secondaryText.opacity(0.3),
                        lineWidth: 2
                    )
                )

            // Name + bio
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("@\(builder.username)")
                        .font(.legoCardTitle)
                        .foregroundColor(.lightText)
                    if builder.username == "blockmasterjames" {
                        Text("FOUNDER")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(.darkBackground)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Color.legoYellow)
                            .cornerRadius(4)
                    }
                }
                Text(builder.bio)
                    .font(.legoCaption)
                    .foregroundColor(.secondaryText)
                    .lineLimit(1)
            }

            Spacer()

            // Follow / Following button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    postStore.toggleFollow(builder.username)
                }
            } label: {
                Text(isFollowing ? "Following" : "Follow")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(isFollowing ? .secondaryText : .white)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(isFollowing ? Color.cardBackground : Color.legoRed)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isFollowing ? Color.secondaryText.opacity(0.4) : Color.clear,
                                    lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color.cardBackground)
        .cornerRadius(14)
    }
}

#Preview {
    SuggestedBuildersView()
}

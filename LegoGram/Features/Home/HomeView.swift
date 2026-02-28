import SwiftUI

/// The Home screen — the first thing you see when you open LegoGram.
/// It shows a scrollable feed of LEGO build posts from the community.
/// Right now there are two placeholder cards to show how the layout will look.
struct HomeView: View {

    /// Placeholder posts — real ones will come from Firebase in a future sprint.
    private let placeholderPosts: [PlaceholderPost] = [
        PlaceholderPost(
            username: "brickmaster99",
            legoSetNumber: "75192",
            legoSetName: "Millennium Falcon",
            likes: 342,
            comments: 47
        ),
        PlaceholderPost(
            username: "legolover_emma",
            legoSetNumber: "10300",
            legoSetName: "Back to the Future Time Machine",
            likes: 218,
            comments: 31
        )
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // MARK: - Logo Header
                        HStack {
                            LegoGramLogo()
                            Spacer()
                            // Notifications bell — will be wired up in a future sprint
                            Button {
                                // TODO: Open notifications
                            } label: {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.legoYellow)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)

                        // MARK: - Post Feed
                        ForEach(placeholderPosts) { post in
                            PostCard(post: post)
                        }

                        // Spacer so the last card isn't hidden behind the tab bar
                        Color.clear.frame(height: 80)
                    }
                }
            }
        }
    }
}

// MARK: - Placeholder Post Model (local to this screen for now)
struct PlaceholderPost: Identifiable {
    let id = UUID()
    let username: String
    let legoSetNumber: String
    let legoSetName: String
    let likes: Int
    let comments: Int
}

// MARK: - Post Card
/// One card in the feed. Shows a photo placeholder, username, set info, likes, and comments.
struct PostCard: View {

    let post: PlaceholderPost

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // MARK: Photo Placeholder
            ZStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.legoRed.opacity(0.3), Color.legoYellow.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 280)

                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.system(size: 48))
                        .foregroundColor(.secondaryText)
                    Text("Photo goes here")
                        .font(.legoCaption)
                        .foregroundColor(.secondaryText)
                }
            }

            // MARK: Card Info
            VStack(alignment: .leading, spacing: 8) {

                // Username row
                HStack {
                    Circle()
                        .fill(Color.legoRed)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text(String(post.username.prefix(1)).uppercased())
                                .font(.legoCaption)
                                .foregroundColor(.white)
                        )

                    Text("@\(post.username)")
                        .font(.legoCardTitle)
                        .foregroundColor(.lightText)

                    Spacer()
                }

                // LEGO set info
                Text("Set #\(post.legoSetNumber) · \(post.legoSetName)")
                    .font(.legoCaption)
                    .foregroundColor(.legoYellow)

                // Likes and Comments row
                HStack(spacing: 20) {
                    Label("\(post.likes)", systemImage: "heart.fill")
                        .font(.legoBody)
                        .foregroundColor(.legoRed)

                    Label("\(post.comments)", systemImage: "bubble.right.fill")
                        .font(.legoBody)
                        .foregroundColor(.secondaryText)

                    Spacer()

                    // Buy link — will link to affiliate URL in future sprint
                    Button {
                        // TODO: Open buy link
                    } label: {
                        Label("Buy Set", systemImage: "cart.fill")
                            .font(.legoCaption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.legoYellow)
                            .foregroundColor(.darkBackground)
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
        }
        .background(Color.cardBackground)
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

#Preview {
    HomeView()
}

import SwiftUI

/// The Home screen — the first thing you see when you open LegoGram.
/// It shows a scrollable feed of LEGO build posts from the community.
/// Posts are stored in PostStore and update live when you like something or post a new build.
struct HomeView: View {

    @ObservedObject private var postStore = PostStore.shared

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
                            Button {
                                // Notifications — Sprint 3
                            } label: {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.legoYellow)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)

                        // MARK: - Feed or Empty State
                        if postStore.posts.isEmpty {
                            emptyState
                        } else {
                            ForEach(postStore.posts) { post in
                                PostCard(post: post)
                            }
                        }

                        // Spacer so the last card isn't hidden behind the tab bar
                        Color.clear.frame(height: 80)
                    }
                }
            }
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.stack")
                .font(.system(size: 64))
                .foregroundColor(.secondaryText)

            Text("No posts yet!")
                .font(.legoCardTitle)
                .foregroundColor(.lightText)

            Text("Be the first to share your LEGO build!\nTap the red + button below.")
                .font(.legoBody)
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 80)
        .padding(.horizontal)
    }
}

// MARK: - Post Card

/// One card in the feed. Shows the build photo, username, set info,
/// a tappable ❤️ like button, comment count, and a Buy Set button.
struct PostCard: View {

    let post: LegoPost

    @ObservedObject private var postStore = PostStore.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // MARK: Photo
            photoArea

            // MARK: Card Info
            VStack(alignment: .leading, spacing: 8) {

                // Username row
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.legoRed)
                        .frame(width: 34, height: 34)
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

                // Set number + name
                Text("Set #\(post.legoSetNumber)  ·  \(post.legoSetName)")
                    .font(.legoCaption)
                    .foregroundColor(.legoYellow)

                // Description (if any)
                if !post.description.isEmpty {
                    Text(post.description)
                        .font(.legoBody)
                        .foregroundColor(.secondaryText)
                        .lineLimit(3)
                }

                // Likes / Comments / Buy Set
                HStack(spacing: 20) {

                    // Like button — tapping toggles and animates
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                            postStore.toggleLike(post)
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: postStore.isLiked(post) ? "heart.fill" : "heart")
                                .scaleEffect(postStore.isLiked(post) ? 1.2 : 1.0)
                            Text("\(post.likeCount)")
                        }
                        .font(.legoBody)
                        .foregroundColor(postStore.isLiked(post) ? .legoRed : .secondaryText)
                    }
                    .buttonStyle(.plain)

                    // Comment count (read-only for now)
                    Label("\(post.commentCount)", systemImage: "bubble.right.fill")
                        .font(.legoBody)
                        .foregroundColor(.secondaryText)

                    Spacer()

                    // Buy Set — opens LEGO website in Safari
                    if let url = URL(string: post.buyLink), !post.buyLink.isEmpty {
                        Link(destination: url) {
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

                // Estimated affiliate earnings (only shown if > 0)
                if post.estimatedEarnings > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.legoCaption)
                        Text("Earns approx. $\(String(format: "%.2f", post.estimatedEarnings)) per purchase")
                            .font(.legoCaption)
                    }
                    .foregroundColor(.successGreen)
                }
            }
            .padding()
        }
        .background(Color.cardBackground)
        .cornerRadius(16)
        .padding(.horizontal)
    }

    // MARK: - Photo Area

    @ViewBuilder
    private var photoArea: some View {
        if let image = postStore.postImages[post.id] {
            // Real photo taken by the user
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 280)
                .clipped()
        } else {
            // Branded placeholder for pre-loaded posts that have no local image
            ZStack {
                LinearGradient(
                    colors: [Color.legoRed.opacity(0.3), Color.legoYellow.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 280)

                VStack(spacing: 8) {
                    Image(systemName: "building.2.crop.circle")
                        .font(.system(size: 52))
                        .foregroundColor(.secondaryText)
                    Text("Set #\(post.legoSetNumber)")
                        .font(.legoCardTitle)
                        .foregroundColor(.legoYellow)
                }
            }
        }
    }
}

#Preview {
    HomeView()
}

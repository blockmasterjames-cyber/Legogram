import SwiftUI
import AVKit

/// The Home screen — the scrolling feed of LEGO builds from the community.
/// Sprint 3 upgrades:
/// • Tap a post → full-screen PostDetailView
/// • Double-tap a post → like it with an Instagram-style heart animation
/// • Scroll to bottom → auto-loads more posts with a spinner
/// • iPad → 2-column grid instead of 1-column
/// • Post cards show the real LEGO set name from the database
/// • Username / avatar taps navigate to that user's profile
struct HomeView: View {

    @ObservedObject private var postStore = PostStore.shared
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // Navigation state
    @State private var selectedPost: LegoPost?
    @State private var selectedUsername: String?

    private var visiblePosts: [LegoPost] { postStore.visiblePosts }

    // On iPad use a 2-column grid; on iPhone use 1-column
    private var gridColumns: [GridItem] {
        horizontalSizeClass == .regular
            ? [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
            : [GridItem(.flexible())]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 0) {

                        // MARK: Logo Header
                        HStack {
                            LegoGramLogo()
                            Spacer()
                            Button {
                                // Notifications — Sprint 4
                            } label: {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.legoYellow)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 12)

                        // MARK: Feed (1-col iPhone, 2-col iPad)
                        if visiblePosts.isEmpty {
                            emptyState
                        } else {
                            LazyVGrid(columns: gridColumns, spacing: 16) {
                                ForEach(visiblePosts) { post in
                                    PostCard(
                                        post: post,
                                        onTap: { selectedPost = post },
                                        onProfileTap: { selectedUsername = post.username }
                                    )
                                }
                            }
                            .padding(.horizontal, horizontalSizeClass == .regular ? 16 : 0)
                        }

                        // MARK: Infinite Scroll Trigger
                        infiniteScrollTrigger
                    }
                    .padding(.bottom, 80)
                }
            }
            // Navigate to full-screen post detail
            .navigationDestination(item: $selectedPost) { post in
                PostDetailView(post: post)
            }
            // Navigate to another user's profile
            .navigationDestination(item: $selectedUsername) { username in
                OtherProfileView(username: username)
            }
        }
    }

    // MARK: - Infinite Scroll Trigger

    @ViewBuilder
    private var infiniteScrollTrigger: some View {
        if postStore.isLoadingMore {
            HStack {
                ProgressView()
                    .tint(.legoYellow)
                    .scaleEffect(1.2)
                Text("Loading more builds...")
                    .font(.legoCaption)
                    .foregroundColor(.secondaryText)
            }
            .padding(.vertical, 24)
        } else {
            Color.clear.frame(height: 20)
                .onAppear {
                    postStore.loadMorePosts()
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

/// One card in the feed. Shows photo/video, username, LEGO set name, likes, and Buy Set.
/// Double-tapping the card fires the like heart animation.
struct PostCard: View {

    let post: LegoPost
    let onTap: () -> Void
    let onProfileTap: () -> Void

    @ObservedObject private var postStore = PostStore.shared
    @State private var showHeart = false

    private var legoSet: LegoSet? { LegoSetDatabase.set(for: post.legoSetNumber) }
    private var setName: String {
        legoSet?.name ?? post.legoSetName
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // MARK: Photo / Video Area
            ZStack {
                photoArea
                    .onTapGesture(count: 2) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                            postStore.toggleLike(post)
                            showHeart = true
                        }
                        Task {
                            try? await Task.sleep(nanoseconds: 900_000_000)
                            withAnimation { showHeart = false }
                        }
                    }
                    .onTapGesture(count: 1) {
                        onTap()
                    }

                // Video play button overlay
                if post.isVideoPost {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.white.opacity(0.85))
                        .allowsHitTesting(false)
                }

                // Double-tap heart animation
                if showHeart {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.legoRed.opacity(0.9))
                        .scaleEffect(showHeart ? 1.0 : 0.1)
                        .opacity(showHeart ? 1.0 : 0.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showHeart)
                        .allowsHitTesting(false)
                }
            }

            // MARK: Card Info
            VStack(alignment: .leading, spacing: 8) {

                // Username row — tapping goes to that user's profile
                Button(action: onProfileTap) {
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
                }
                .buttonStyle(.plain)

                // LEGO set name (from database lookup, with fallback)
                Text("Set #\(post.legoSetNumber)  ·  \(setName)")
                    .font(.legoCaption)
                    .foregroundColor(.legoYellow)

                // Description
                if !post.description.isEmpty {
                    Text(BadWordFilter.filter(post.description))
                        .font(.legoBody)
                        .foregroundColor(.secondaryText)
                        .lineLimit(3)
                }

                // Action row: Likes / Comments / Buy Set
                HStack(spacing: 20) {

                    // Like button
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                            postStore.toggleLike(post)
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: postStore.isLiked(post) ? "heart.fill" : "heart")
                                .scaleEffect(postStore.isLiked(post) ? 1.2 : 1.0)
                            Text("\(currentLikeCount)")
                        }
                        .font(.legoBody)
                        .foregroundColor(postStore.isLiked(post) ? .legoRed : .secondaryText)
                    }
                    .buttonStyle(.plain)

                    // Comment count — tapping opens detail
                    Button(action: onTap) {
                        Label("\(post.commentCount)", systemImage: "bubble.right.fill")
                            .font(.legoBody)
                            .foregroundColor(.secondaryText)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    // Buy Set — uses legoStoreURL from database
                    if let set = legoSet, let url = URL(string: set.legoStoreURL) {
                        Link(destination: url) {
                            Label("Buy · $\(String(format: "%.0f", set.retailPrice))",
                                  systemImage: "cart.fill")
                                .font(.legoCaption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.legoYellow)
                                .foregroundColor(.darkBackground)
                                .cornerRadius(8)
                        }
                    } else if !post.buyLink.isEmpty, let url = URL(string: post.buyLink) {
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

                // Earnings
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
        .padding(.horizontal, 16)
    }

    // Live like count from store
    private var currentLikeCount: Int {
        postStore.posts.first(where: { $0.id == post.id })?.likeCount ?? post.likeCount
    }

    // MARK: - Photo / Video Area

    @ViewBuilder
    private var photoArea: some View {
        if let image = postStore.postImages[post.id] {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 280)
                .clipped()
        } else if let videoURL = postStore.postVideoURLs[post.id] {
            VideoPlayer(player: AVPlayer(url: videoURL))
                .frame(height: 280)
                .disabled(true) // Tapping controls detail view, not video controls
        } else {
            ZStack {
                LinearGradient(
                    colors: [Color.legoRed.opacity(0.3), Color.legoYellow.opacity(0.2)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .frame(height: 280)

                VStack(spacing: 8) {
                    Image(systemName: "building.2.crop.circle")
                        .font(.system(size: 52))
                        .foregroundColor(.secondaryText)
                    Text("Set #\(post.legoSetNumber)")
                        .font(.legoCardTitle)
                        .foregroundColor(.legoYellow)
                    if let set = legoSet {
                        Text(set.theme)
                            .font(.legoCaption)
                            .foregroundColor(.secondaryText)
                    }
                }
            }
        }
    }
}

#Preview {
    HomeView()
}

import SwiftUI
import AVKit

/// Wrapper used as the navigation item so we can carry both the post
/// and whether the detail view should auto-scroll to comments.
struct FeedNavigation: Identifiable {
    let post: LegoPost
    let scrollToComments: Bool
    var id: String { post.id + (scrollToComments ? "-c" : "") }
}

/// The Home screen — the scrolling feed of LEGO builds from the community.
/// Sprint 4 upgrades:
/// • Sticky logo header with notification bell that stays at top while scrolling
/// • Real LEGO set images loaded with AsyncImage from Brickset CDN
/// • Age rating badge on every post card
/// • Polished card design with shadow
/// • Tapping the comment bubble auto-scrolls to the comments section
struct HomeView: View {

    @ObservedObject private var postStore = PostStore.shared
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var navigation: FeedNavigation?
    @State private var selectedUsername: String?

    private var visiblePosts: [LegoPost] { postStore.visiblePosts }

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
                    LazyVStack(spacing: 16) {

                        if visiblePosts.isEmpty {
                            emptyState
                        } else {
                            LazyVGrid(columns: gridColumns, spacing: 16) {
                                ForEach(visiblePosts) { post in
                                    PostCard(
                                        post: post,
                                        onTap: {
                                            navigation = FeedNavigation(post: post,
                                                                        scrollToComments: false)
                                        },
                                        onCommentTap: {
                                            navigation = FeedNavigation(post: post,
                                                                        scrollToComments: true)
                                        },
                                        onProfileTap: { selectedUsername = post.username }
                                    )
                                }
                            }
                            .padding(.horizontal, horizontalSizeClass == .regular ? 16 : 0)
                        }

                        // Infinite scroll trigger
                        infiniteScrollTrigger
                    }
                    .padding(.bottom, 80)
                    .padding(.top, 8)
                }
                // Sticky logo header — stays pinned at top while feed scrolls
                .safeAreaInset(edge: .top) {
                    feedHeader
                }
            }
            .navigationDestination(item: $navigation) { nav in
                PostDetailView(post: nav.post, scrollToComments: nav.scrollToComments)
            }
            .navigationDestination(item: $selectedUsername) { username in
                OtherProfileView(username: username)
            }
        }
    }

    // MARK: - Sticky Feed Header

    private var feedHeader: some View {
        HStack(alignment: .center) {
            LegoGramLogo()

            Spacer()

            Button {
                // Notifications — future sprint
            } label: {
                Image(systemName: "bell.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.legoYellow)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(
            Color.darkBackground
                .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
        )
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

/// One card in the feed. Shows the real LEGO set image, username, age rating badge,
/// likes, comments, and a Buy Set button. Double-tap to like. Tap comment bubble
/// to open the detail view scrolled straight to the comments section.
struct PostCard: View {

    let post: LegoPost
    let onTap: () -> Void
    let onCommentTap: () -> Void
    let onProfileTap: () -> Void

    @ObservedObject private var postStore = PostStore.shared
    @State private var showHeart = false

    private var legoSet: LegoSet? { LegoSetDatabase.set(for: post.legoSetNumber) }
    private var setName: String { legoSet?.name ?? post.legoSetName }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // MARK: Image / Video Area
            ZStack {
                mediaArea
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

                // Username row (taps → profile)
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

                // Set name + age rating badge
                HStack(spacing: 6) {
                    Text(setName)
                        .font(.legoCaption)
                        .foregroundColor(.legoYellow)
                        .lineLimit(1)

                    if let set = legoSet {
                        AgeRatingBadge(rating: set.ageRating)
                    }
                }

                // Description
                if !post.description.isEmpty {
                    Text(BadWordFilter.filter(post.description))
                        .font(.legoBody)
                        .foregroundColor(.secondaryText)
                        .lineLimit(3)
                }

                // Action row: Like · Comment · Buy Set
                HStack(spacing: 16) {

                    // Heart / like button
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                            postStore.toggleLike(post)
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: postStore.isLiked(post) ? "heart.fill" : "heart")
                                .font(.system(size: 18))
                                .scaleEffect(postStore.isLiked(post) ? 1.2 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.5),
                                           value: postStore.isLiked(post))
                            Text("\(currentLikeCount)")
                                .font(.legoBody)
                        }
                        .foregroundColor(postStore.isLiked(post) ? .legoRed : .secondaryText)
                    }
                    .buttonStyle(.plain)

                    // Comment bubble — tapping opens detail and scrolls to comments
                    Button(action: onCommentTap) {
                        HStack(spacing: 5) {
                            Image(systemName: "bubble.right.fill")
                                .font(.system(size: 16))
                            Text("\(commentCount)")
                                .font(.legoBody)
                        }
                        .foregroundColor(.secondaryText)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    // Buy Set button
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

                // Earnings line
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
            .padding(12)
        }
        .background(Color.cardBackground)
        .cornerRadius(16)
        // Polished shadow around the card
        .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 16)
    }

    // Live values from the store
    private var currentLikeCount: Int {
        postStore.posts.first(where: { $0.id == post.id })?.likeCount ?? post.likeCount
    }
    private var commentCount: Int {
        postStore.comments(for: post.id).count
    }

    // MARK: - Media Area (AsyncImage from CDN, then user photo, then placeholder)

    @ViewBuilder
    private var mediaArea: some View {
        if let image = postStore.postImages[post.id] {
            // User uploaded a real photo
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 260)
                .clipped()
        } else if let videoURL = postStore.postVideoURLs[post.id] {
            VideoPlayer(player: AVPlayer(url: videoURL))
                .frame(height: 260)
                .disabled(true)
        } else if let imageURL = legoSet?.setImageURL {
            // Load official set image from Brickset CDN
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .success(let img):
                    img.resizable()
                        .scaledToFill()
                        .frame(height: 260)
                        .clipped()
                case .failure:
                    placeholderArea
                case .empty:
                    ZStack {
                        Color.cardBackground.frame(height: 260)
                        ProgressView().tint(.legoYellow)
                    }
                @unknown default:
                    placeholderArea
                }
            }
        } else {
            placeholderArea
        }
    }

    private var placeholderArea: some View {
        ZStack {
            LinearGradient(
                colors: [Color.legoRed.opacity(0.3), Color.legoYellow.opacity(0.2)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .frame(height: 260)

            VStack(spacing: 8) {
                Image(systemName: "building.2.crop.circle")
                    .font(.system(size: 48))
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

// MARK: - Age Rating Badge

/// A small LEGO-yellow rounded badge showing the recommended age, e.g. "9+" or "18+".
struct AgeRatingBadge: View {
    let rating: String

    var body: some View {
        Text(rating)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundColor(Color(red: 0.12, green: 0.12, blue: 0.12))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.legoYellow)
            .cornerRadius(4)
    }
}

#Preview {
    HomeView()
}

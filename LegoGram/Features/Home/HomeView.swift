import SwiftUI
import AVKit

/// Wrapper used as the navigation item so we can carry both the post
/// and whether the detail view should auto-scroll to comments.
struct FeedNavigation: Identifiable, Hashable {
    let post: LegoPost
    let scrollToComments: Bool
    var id: String { post.id + (scrollToComments ? "-c" : "") }
}

/// The Home screen — scrolling feed of LEGO builds.
/// Sprint 5 upgrades:
/// • Smart feed: followed posts first, then "Recommended For You" section
/// • Follow button on recommended post cards
/// • DM icon in header
/// • Square photos with rounded corners
/// • iPad 2-column portrait, 3-column landscape
struct HomeView: View {

    @ObservedObject private var postStore = PostStore.shared
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var navigation: FeedNavigation?
    @State private var selectedUsername: String?
    @State private var showingDMSheet = false

    // MARK: - Feed Sections

    private var followedPosts: [LegoPost] {
        postStore.visiblePosts.filter { postStore.isFollowing($0.username) }
    }

    private var recommendedPosts: [LegoPost] {
        postStore.visiblePosts
            .filter { !postStore.isFollowing($0.username) }
            .sorted { $0.likeCount > $1.likeCount }
    }

    private func gridColumns(for width: CGFloat) -> [GridItem] {
        let count: Int
        if width >= 1000 { count = 3 }        // iPad landscape
        else if width >= 600 { count = 2 }     // iPad portrait
        else { count = 1 }                     // iPhone
        return Array(repeating: GridItem(.flexible(), spacing: 16), count: count)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                GeometryReader { geo in
                    ScrollView {
                        LazyVStack(spacing: 0) {

                            if followedPosts.isEmpty && recommendedPosts.isEmpty {
                                emptyState
                            } else {
                                // Section 1: Followed posts
                                if !followedPosts.isEmpty {
                                    LazyVGrid(columns: gridColumns(for: geo.size.width), spacing: 16) {
                                        ForEach(followedPosts) { post in
                                            PostCard(
                                                post: post,
                                                showFollowButton: false,
                                                onTap: { navigation = FeedNavigation(post: post, scrollToComments: false) },
                                                onCommentTap: { navigation = FeedNavigation(post: post, scrollToComments: true) },
                                                onProfileTap: { selectedUsername = post.username }
                                            )
                                        }
                                    }
                                    .padding(.horizontal, horizontalSizeClass == .regular ? 16 : 0)
                                    .padding(.top, 8)
                                }

                                // Section 2: Recommended For You
                                if !recommendedPosts.isEmpty {
                                    recommendedHeader
                                    LazyVGrid(columns: gridColumns(for: geo.size.width), spacing: 16) {
                                        ForEach(recommendedPosts) { post in
                                            PostCard(
                                                post: post,
                                                showFollowButton: true,
                                                onTap: { navigation = FeedNavigation(post: post, scrollToComments: false) },
                                                onCommentTap: { navigation = FeedNavigation(post: post, scrollToComments: true) },
                                                onProfileTap: { selectedUsername = post.username }
                                            )
                                        }
                                    }
                                    .padding(.horizontal, horizontalSizeClass == .regular ? 16 : 0)
                                }
                            }

                            // Infinite scroll trigger
                            infiniteScrollTrigger
                        }
                        .padding(.bottom, 80)
                        .padding(.top, 8)
                    }
                }
                // Sticky logo header
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
        .sheet(isPresented: $showingDMSheet) {
            DirectMessageListView()
        }
    }

    // MARK: - Sticky Feed Header

    private var feedHeader: some View {
        HStack(alignment: .center) {
            BrickFeedLogo()
            Spacer()

            // DM button (Sprint 5)
            Button { showingDMSheet = true } label: {
                Image(systemName: "message.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.legoYellow)
            }
            .padding(.trailing, 12)

            // Notification bell
            Button {} label: {
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

    // MARK: - Recommended For You Header

    private var recommendedHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Recommended For You")
                    .font(.legoCardTitle)
                    .foregroundColor(.legoYellow)
                Text("Top builds from the community")
                    .font(.legoCaption)
                    .foregroundColor(.secondaryText)
            }
            Spacer()
            Image(systemName: "star.fill")
                .foregroundColor(.legoYellow)
                .font(.system(size: 18))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.cardBackground.opacity(0.6))
        .padding(.top, 8)
    }

    // MARK: - Infinite Scroll Trigger

    @ViewBuilder
    private var infiniteScrollTrigger: some View {
        if postStore.isLoadingMore {
            HStack {
                ProgressView().tint(.legoYellow).scaleEffect(1.2)
                Text("Loading more builds...")
                    .font(.legoCaption).foregroundColor(.secondaryText)
            }
            .padding(.vertical, 24)
        } else {
            Color.clear.frame(height: 20)
                .onAppear { postStore.loadMorePosts() }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.stack")
                .font(.system(size: 64)).foregroundColor(.secondaryText)
            Text("No posts yet!")
                .font(.legoCardTitle).foregroundColor(.lightText)
            Text("Be the first to share your Brick build!\nTap the red + button below.")
                .font(.legoBody).foregroundColor(.secondaryText).multilineTextAlignment(.center)
        }
        .padding(.top, 80).padding(.horizontal)
    }
}

// MARK: - Post Card

/// One card in the feed. Square photo, username, age badge, likes, comments, Buy Set.
/// Sprint 5: square photo, follow button on recommended posts.
struct PostCard: View {

    let post: LegoPost
    var showFollowButton: Bool = false
    let onTap: () -> Void
    let onCommentTap: () -> Void
    let onProfileTap: () -> Void

    @ObservedObject private var postStore = PostStore.shared
    @State private var showHeart = false

    private var legoSet: LegoSet? {
        post.isCustomBuild ? nil : LegoSetDatabase.set(for: post.legoSetNumber)
    }
    private var setName: String {
        if post.isCustomBuild { return post.customBuildName }
        return legoSet?.name ?? post.legoSetName
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // MARK: Square Image / Video Area
            ZStack(alignment: .topTrailing) {
                squareMediaArea
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
                    .onTapGesture(count: 1) { onTap() }

                // Video play button overlay
                if post.isVideoPost {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.white.opacity(0.85))
                        .allowsHitTesting(false)
                        .padding(8)
                }

                // Follow button on recommended posts
                if showFollowButton && !postStore.isFollowing(post.username) {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            postStore.toggleFollow(post.username)
                        }
                    } label: {
                        Text("Follow")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.legoRed)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .padding(8)
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
            .cornerRadius(12)

            // MARK: Card Info
            VStack(alignment: .leading, spacing: 8) {

                // Username row
                Button(action: onProfileTap) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.legoRed)
                            .frame(width: 34, height: 34)
                            .overlay(
                                Text(String(post.username.prefix(1)).uppercased())
                                    .font(.legoCaption).foregroundColor(.white)
                            )
                        Text("@\(post.username)")
                            .font(.legoCardTitle).foregroundColor(.lightText)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)

                // Set name + age rating badge (or Custom Build badge)
                HStack(spacing: 6) {
                    Text(setName)
                        .font(.legoCaption).foregroundColor(.legoYellow).lineLimit(1)
                    if post.isCustomBuild {
                        Text("Custom Build")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Color.blue)
                            .cornerRadius(4)
                    } else if let set = legoSet {
                        AgeRatingBadge(rating: set.ageRating)
                    }
                }

                // Description
                if !post.description.isEmpty {
                    Text(BadWordFilter.filter(post.description))
                        .font(.legoBody).foregroundColor(.secondaryText).lineLimit(3)
                }

                // Action row
                HStack(spacing: 16) {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { postStore.toggleLike(post) }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: postStore.isLiked(post) ? "heart.fill" : "heart")
                                .font(.system(size: 18))
                                .scaleEffect(postStore.isLiked(post) ? 1.2 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: postStore.isLiked(post))
                            Text("\(currentLikeCount)").font(.legoBody)
                        }
                        .foregroundColor(postStore.isLiked(post) ? .legoRed : .secondaryText)
                    }
                    .buttonStyle(.plain)

                    Button(action: onCommentTap) {
                        HStack(spacing: 5) {
                            Image(systemName: "bubble.right.fill").font(.system(size: 16))
                            Text("\(commentCount)").font(.legoBody)
                        }
                        .foregroundColor(.secondaryText)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    // No Buy button for custom builds
                    if !post.isCustomBuild,
                       let set = legoSet,
                       let url = URL(string: set.legoStoreURL) {
                        Link(destination: url) {
                            Label("Buy · $\(String(format: "%.0f", set.retailPrice))", systemImage: "cart.fill")
                                .font(.legoCaption)
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(Color.legoYellow)
                                .foregroundColor(.darkBackground)
                                .cornerRadius(8)
                        }
                    }
                }

                if post.estimatedEarnings > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "dollarsign.circle.fill").font(.legoCaption)
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
        .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 16)
    }

    private var currentLikeCount: Int {
        postStore.posts.first(where: { $0.id == post.id })?.likeCount ?? post.likeCount
    }
    private var commentCount: Int { postStore.comments(for: post.id).count }

    // MARK: - Square Media Area (Sprint 5: all images are perfect squares)

    @ViewBuilder
    private var squareMediaArea: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                Group {
                    if let image = postStore.postImages[post.id] {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else if let videoURL = postStore.postVideoURLs[post.id] {
                        VideoPlayer(player: AVPlayer(url: videoURL))
                            .disabled(true)
                    } else if let imageURL = legoSet?.setImageURL {
                        AsyncImage(url: imageURL) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable().scaledToFill()
                            case .failure:
                                placeholderContent
                            case .empty:
                                ZStack {
                                    Color.cardBackground
                                    ProgressView().tint(.legoYellow)
                                }
                            @unknown default:
                                placeholderContent
                            }
                        }
                    } else {
                        placeholderContent
                    }
                }
                .clipped()
            }
            .clipped()
    }

    private var placeholderContent: some View {
        ZStack {
            LinearGradient(
                colors: [Color.legoRed.opacity(0.3), Color.legoYellow.opacity(0.2)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            VStack(spacing: 8) {
                Image(systemName: post.isCustomBuild ? "hammer.fill" : "building.2.crop.circle")
                    .font(.system(size: 36)).foregroundColor(.secondaryText)
                Text(post.isCustomBuild
                     ? post.customBuildName
                     : "Set #\(post.legoSetNumber)")
                    .font(.legoCardTitle).foregroundColor(.legoYellow)
                if !post.isCustomBuild, let set = legoSet {
                    Text(set.theme).font(.legoCaption).foregroundColor(.secondaryText)
                }
            }
        }
    }
}

// MARK: - Age Rating Badge

/// A small LEGO-yellow rounded badge showing the recommended age.
struct AgeRatingBadge: View {
    let rating: String

    var body: some View {
        Text(rating)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundColor(Color(red: 0.12, green: 0.12, blue: 0.12))
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(Color.legoYellow)
            .cornerRadius(4)
    }
}

#Preview {
    HomeView()
}

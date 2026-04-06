import SwiftUI
import AVKit

/// The Home screen — scrolling feed of LEGO builds.
struct HomeView: View {

    @ObservedObject private var postStore = PostStore.shared
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var selectedPost: LegoPost?          // navigate to post detail
    @State private var selectedUsername: String?         // navigate to profile
    @State private var commentPost: LegoPost?            // opens comment sheet
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
        if width >= 1000 { count = 3 }
        else if width >= 600 { count = 2 }
        else { count = 1 }
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
                                if !followedPosts.isEmpty {
                                    LazyVGrid(columns: gridColumns(for: geo.size.width), spacing: 16) {
                                        ForEach(followedPosts) { post in
                                            PostCard(
                                                post: post,
                                                showFollowButton: true,
                                                onTap: { selectedPost = post },
                                                onCommentTap: { commentPost = post },
                                                onProfileTap: { selectedUsername = post.username }
                                            )
                                        }
                                    }
                                    .padding(.horizontal, horizontalSizeClass == .regular ? 16 : 0)
                                    .padding(.top, 8)
                                }

                                if !recommendedPosts.isEmpty {
                                    recommendedHeader
                                    LazyVGrid(columns: gridColumns(for: geo.size.width), spacing: 16) {
                                        ForEach(recommendedPosts) { post in
                                            PostCard(
                                                post: post,
                                                showFollowButton: true,
                                                onTap: { selectedPost = post },
                                                onCommentTap: { commentPost = post },
                                                onProfileTap: { selectedUsername = post.username }
                                            )
                                        }
                                    }
                                    .padding(.horizontal, horizontalSizeClass == .regular ? 16 : 0)
                                }
                            }

                            infiniteScrollTrigger
                        }
                        .padding(.bottom, 80)
                        .padding(.top, 8)
                    }
                }
                .safeAreaInset(edge: .top) {
                    feedHeader
                }
            }
            .navigationDestination(item: $selectedPost) { post in
                PostDetailView(post: post)
            }
            .navigationDestination(item: $selectedUsername) { username in
                OtherProfileView(username: username)
            }
        }
        .sheet(isPresented: $showingDMSheet) {
            DirectMessageListView()
        }
        .sheet(item: $commentPost) { post in
            CommentSheetView(post: post)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Feed Header

    private var feedHeader: some View {
        HStack(alignment: .center) {
            BrickFeedLogo()
            Spacer()

            Button { showingDMSheet = true } label: {
                Image(systemName: "message.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.legoYellow)
            }
            .padding(.trailing, 12)

            Button { } label: {
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

    // MARK: - Recommended Header

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
            Text("Follow some builders to see their posts here!")
                .font(.legoBody).foregroundColor(.secondaryText).multilineTextAlignment(.center)
        }
        .padding(.top, 80).padding(.horizontal)
    }
}

// MARK: - Post Card

/// One card in the feed. Tapping heart likes in-place (no navigation).
/// Tapping comment bubble opens the CommentSheet.
/// Double-tapping photo triggers like with heart animation overlay.
struct PostCard: View {

    let post: LegoPost
    var showFollowButton: Bool = false
    let onTap: () -> Void
    let onCommentTap: () -> Void
    let onProfileTap: () -> Void

    @ObservedObject private var postStore = PostStore.shared
    @State private var showHeart = false
    @State private var isLiking  = false

    private var legoSet: LegoSet? {
        post.isCustomBuild ? nil : LegoSetDatabase.set(for: post.legoSetNumber)
    }
    private var setName: String {
        if post.isCustomBuild { return post.customBuildName }
        return legoSet?.name ?? post.legoSetName
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // MARK: Square Image / Video
            ZStack(alignment: .topTrailing) {
                squareMediaArea
                    .onTapGesture(count: 2) {
                        handleDoubleTap()
                    }
                    .onTapGesture(count: 1) { onTap() }

                if post.isVideoPost {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.white.opacity(0.85))
                        .allowsHitTesting(false)
                        .padding(8)
                }

                // Follow / Unfollow button
                if showFollowButton {
                    let isFollowed = postStore.isFollowing(post.username)
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            postStore.toggleFollow(post.username)
                        }
                        Task {
                            let currentUid = UserSession.shared.uid
                            guard !currentUid.isEmpty else { return }
                            let targetId = OGAccountsService.ogAccounts
                                .first(where: { $0.username == post.username })?.id ?? post.userId
                            do {
                                if !isFollowed {
                                    try await FirebaseService.shared.followUser(
                                        currentUserId: currentUid, targetUserId: targetId)
                                } else {
                                    try await FirebaseService.shared.unfollowUser(
                                        currentUserId: currentUid, targetUserId: targetId)
                                }
                            } catch {
                                print("[PostCard] Follow/unfollow error: \(error)")
                            }
                        }
                    } label: {
                        Text(isFollowed ? "Unfollow" : "Follow")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(isFollowed ? .secondaryText : .white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(isFollowed ? Color.cardBackground : Color.legoRed)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isFollowed ? Color.secondaryText.opacity(0.5) : Color.clear,
                                            lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(8)
                }

                // Double-tap heart animation overlay
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

                // Username row with avatar
                Button(action: onProfileTap) {
                    HStack(spacing: 8) {
                        postAuthorAvatar
                        Text("@\(post.username)")
                            .font(.legoCardTitle).foregroundColor(.lightText)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)

                // Set name + badges
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

                // Action row: Like, Comment, Buy
                HStack(spacing: 16) {

                    // LIKE BUTTON — taps in-place, does NOT navigate
                    Button {
                        handleLikeTap()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: postStore.isLiked(post) ? "heart.fill" : "heart")
                                .font(.system(size: 18))
                                .scaleEffect(postStore.isLiked(post) ? 1.2 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.5),
                                           value: postStore.isLiked(post))
                            Text("\(currentLikeCount)").font(.legoBody)
                        }
                        .foregroundColor(postStore.isLiked(post) ? .legoRed : .secondaryText)
                    }
                    .buttonStyle(.plain)
                    .disabled(isLiking)

                    // COMMENT BUTTON — opens sheet, does NOT navigate
                    Button(action: onCommentTap) {
                        HStack(spacing: 5) {
                            Image(systemName: "bubble.right.fill").font(.system(size: 16))
                            Text("\(currentCommentCount)").font(.legoBody)
                        }
                        .foregroundColor(.secondaryText)
                    }
                    .buttonStyle(.plain)

                    // REPORT button
                    reportMenu

                    Spacer()

                    // Buy button (no earnings shown)
                    if !post.isCustomBuild,
                       let set = legoSet,
                       let url = URL(string: set.legoStoreURL) {
                        Link(destination: url) {
                            Label("Buy · $\(String(format: "%.0f", set.retailPrice))",
                                  systemImage: "cart.fill")
                                .font(.legoCaption)
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(Color.legoYellow)
                                .foregroundColor(.darkBackground)
                                .cornerRadius(8)
                        }
                    }
                }
            }
            .padding(12)
        }
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 16)
    }

    // MARK: - Author Avatar

    private var postAuthorAvatar: some View {
        Circle()
            .fill(Color.legoRed)
            .frame(width: 34, height: 34)
            .overlay(
                Text(String(post.username.prefix(1)).uppercased())
                    .font(.legoCaption).foregroundColor(.white)
            )
    }

    // MARK: - Report Menu

    private var reportMenu: some View {
        Menu {
            Button("Inappropriate content") { reportPost(reason: "Inappropriate content") }
            Button("Bullying") { reportPost(reason: "Bullying") }
            Button("Spam") { reportPost(reason: "Spam") }
            Button("Not LEGO related") { reportPost(reason: "Not LEGO related") }
        } label: {
            Image(systemName: "flag")
                .font(.system(size: 14))
                .foregroundColor(.secondaryText)
        }
    }

    // MARK: - Computed counts

    private var currentLikeCount: Int {
        postStore.posts.first(where: { $0.id == post.id })?.likeCount ?? post.likeCount
    }
    private var currentCommentCount: Int {
        let stored = postStore.posts.first(where: { $0.id == post.id })?.commentCount ?? post.commentCount
        let local  = postStore.comments(for: post.id).count
        return max(stored, local)
    }

    // MARK: - Actions

    private func handleLikeTap() {
        guard !isLiking else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            postStore.toggleLike(post)
        }
        // Sync to Firestore
        isLiking = true
        Task {
            let uid = UserSession.shared.uid
            guard !uid.isEmpty else { isLiking = false; return }
            do {
                let _ = try await FirebaseService.shared.toggleLike(
                    postId: post.id,
                    postOwnerId: post.userId,
                    currentUserId: uid
                )
            } catch {
                print("[PostCard] Like error: \(error)")
            }
            isLiking = false
        }
    }

    private func handleDoubleTap() {
        // Only like if not already liked
        if !postStore.isLiked(post) {
            handleLikeTap()
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            showHeart = true
        }
        Task {
            try? await Task.sleep(nanoseconds: 900_000_000)
            withAnimation { showHeart = false }
        }
    }

    private func reportPost(reason: String) {
        postStore.reportPost(post)
        Task {
            let uid = UserSession.shared.uid
            guard !uid.isEmpty else { return }
            do {
                try await FirebaseService.shared.reportPost(
                    postId: post.id,
                    reportedBy: uid,
                    reason: reason
                )
            } catch {
                print("[PostCard] Report error: \(error)")
            }
        }
    }

    // MARK: - Square Media Area

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
                    } else if !post.imageURL.isEmpty, let url = URL(string: post.imageURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let img): img.resizable().scaledToFill()
                            case .failure: placeholderContent
                            case .empty:
                                ZStack {
                                    Color.cardBackground
                                    ProgressView().tint(.legoYellow)
                                }
                            @unknown default: placeholderContent
                            }
                        }
                    } else if let imageURL = legoSet?.setImageURL {
                        AsyncImage(url: imageURL) { phase in
                            switch phase {
                            case .success(let img): img.resizable().scaledToFill()
                            case .failure: placeholderContent
                            case .empty:
                                ZStack {
                                    Color.cardBackground
                                    ProgressView().tint(.legoYellow)
                                }
                            @unknown default: placeholderContent
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
                Text(post.isCustomBuild ? post.customBuildName : "Set #\(post.legoSetNumber)")
                    .font(.legoCardTitle).foregroundColor(.legoYellow)
                if !post.isCustomBuild, let set = legoSet {
                    Text(set.theme).font(.legoCaption).foregroundColor(.secondaryText)
                }
            }
        }
    }
}

// MARK: - Age Rating Badge

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

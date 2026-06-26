import SwiftUI
import AVKit

/// The full-screen detail view for a single LEGO build post.
///
/// Build 17 follow-up: comment viewing was previously split between an inline
/// section on this screen and a sheet on the feed PostCard — two different
/// UIs for the same data. We've collapsed both onto a single
/// `CommentSheetView`. Every comment entry point in the app (feed PostCard,
/// PostDetailView, notifications) now presents the same modal sheet, so the
/// post-identity bug that surfaced from re-keyed inline state can't recur.
struct PostDetailView: View {

    let post: LegoPost

    @ObservedObject private var postStore     = PostStore.shared
    @ObservedObject private var adminRegistry = AdminRegistry.shared
    @Environment(\.dismiss) private var dismiss

    @State private var showHeartAnimation  = false
    @State private var showingShareCard    = false
    @State private var showingCommentSheet = false
    @State private var isLiking            = false
    @State private var showReportConfirm   = false
    @State private var showBlockConfirm    = false
    @State private var showBlockedConfirm  = false   // post-block confirmation (Issue 1)
    @State private var lastReportReason    = ""
    // Admin delete – two-step confirmation
    @State private var showAdminDeleteConfirm1 = false
    @State private var showAdminDeleteConfirm2 = false
    @State private var isAdminDeleting         = false
    @State private var adminDeleteError: String?

    private var legoSet: LegoSet? { LegoSetDatabase.set(for: post.legoSetNumber) }

    /// Always pull the freshest post (with up-to-date like/comment counts)
    /// out of the store so the screen never falls behind the feed.
    private var currentPost: LegoPost {
        postStore.posts.first(where: { $0.id == post.id }) ?? post
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // MARK: Media (carousel or single)
                mediaSection
                    .gesture(
                        TapGesture(count: 2).onEnded {
                            handleLikeTap()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                                showHeartAnimation = true
                            }
                            Task {
                                try? await Task.sleep(nanoseconds: 1_000_000_000)
                                withAnimation { showHeartAnimation = false }
                            }
                        }
                    )
                    .overlay(heartOverlay)

                // MARK: Post Info
                VStack(alignment: .leading, spacing: 14) {

                    NavigationLink(value: post.username) {
                        HStack(spacing: 10) {
                            Circle()
                                .fill(Color.legoRed).frame(width: 42, height: 42)
                                .overlay(
                                    Text(String(post.username.prefix(1)).uppercased())
                                        .font(.legoCardTitle).foregroundColor(.white)
                                )
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text("@\(post.username)")
                                        .font(.legoCardTitle).foregroundColor(.lightText)
                                    AdminBadge(uid: post.userId)
                                    FollowingBadge(uid: post.userId)
                                }
                                Text(post.postedDate.formatted(date: .abbreviated, time: .shortened))
                                    .font(.legoCaption).foregroundColor(.secondaryText)
                            }
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)

                    HStack(spacing: 8) {
                        Text(post.isCustomBuild
                             ? post.customBuildName
                             : (legoSet?.name ?? post.legoSetName))
                            .font(.legoCardTitle).foregroundColor(.legoYellow)
                        if post.isCustomBuild {
                            Text("Custom Build")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.blue).cornerRadius(4)
                        } else if let set = legoSet {
                            AgeRatingBadge(rating: set.ageRating)
                        }
                        Spacer()
                    }

                    if let set = legoSet {
                        HStack(spacing: 6) {
                            Label(set.theme, systemImage: "tag.fill")
                            Text("·")
                            Label("\(set.pieceCount) pieces", systemImage: "square.grid.3x3.fill")
                        }
                        .font(.legoCaption).foregroundColor(.secondaryText)
                    }

                    if !post.description.isEmpty {
                        Text(BadWordFilter.filter(post.description))
                            .font(.legoBody).foregroundColor(.lightText)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Action row — comment icon opens the SAME CommentSheet
                    // used by the feed, so the interaction is identical
                    // everywhere.
                    HStack(spacing: 24) {
                        Button {
                            handleLikeTap()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: postStore.isLiked(post) ? "heart.fill" : "heart")
                                    .font(.system(size: 20))
                                    .scaleEffect(postStore.isLiked(post) ? 1.2 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.5),
                                               value: postStore.isLiked(post))
                                Text("\(currentPost.likeCount)").font(.legoBody)
                            }
                            .foregroundColor(postStore.isLiked(post) ? .legoRed : .secondaryText)
                        }
                        .buttonStyle(.plain)
                        .disabled(isLiking)

                        Button {
                            showingCommentSheet = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "bubble.right.fill").font(.system(size: 20))
                                Text("\(currentPost.commentCount)").font(.legoBody)
                            }
                            .foregroundColor(.secondaryText)
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Menu {
                            Section("Report this post") {
                                Button("Inappropriate content") { reportPost(reason: "Inappropriate content") }
                                Button("Bullying or harassment") { reportPost(reason: "Bullying or harassment") }
                                Button("Spam") { reportPost(reason: "Spam") }
                                Button("Not LEGO related") { reportPost(reason: "Not LEGO related") }
                            }
                            Section {
                                Button(role: .destructive) {
                                    showBlockConfirm = true
                                } label: {
                                    Label("Block @\(post.username)", systemImage: "hand.raised.fill")
                                }
                            }
                            if adminRegistry.isAdmin(UserSession.shared.uid) {
                                Section {
                                    Button(role: .destructive) {
                                        showAdminDeleteConfirm1 = true
                                    } label: {
                                        Label("Delete Post (Admin)", systemImage: "trash.fill")
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "flag").font(.system(size: 18)).foregroundColor(.secondaryText)
                        }
                        .disabled(isAdminDeleting)
                    }

                    // Tap-target "View comments" row so users have an obvious
                    // way in even if they miss the small bubble icon above.
                    Button {
                        showingCommentSheet = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .font(.system(size: 16, weight: .bold))
                            Text(currentPost.commentCount == 0
                                 ? "Be the first to comment"
                                 : "View all \(currentPost.commentCount) comment\(currentPost.commentCount == 1 ? "" : "s")")
                                .font(.legoCardTitle)
                            Spacer()
                            Image(systemName: "chevron.right").font(.system(size: 14))
                        }
                        .foregroundColor(.lightText)
                        .padding(.horizontal, 14).padding(.vertical, 12)
                        .background(Color.cardBackground)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)

                    Button { showingShareCard = true } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .bold))
                            Text("Share to Stories").font(.legoCardTitle)
                            Spacer()
                            Image(systemName: "sparkles").font(.system(size: 14))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16).padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [Color.legoRed, Color.legoRed.opacity(0.75)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)

                    if !post.isCustomBuild {
                        if let set = legoSet { buySetSection(set: set) }
                        else if !post.buyLink.isEmpty, let url = URL(string: post.buyLink) {
                            Link(destination: url) { buySetLabel(price: nil) }
                        }
                    }
                }
                .padding(16)

                Color.clear.frame(height: 16)
            }
        }
        .background(Color.darkBackground.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.cardBackground, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            // No custom leading back button — the system navigation bar already
            // provides one. Adding our own here (without hiding the system one)
            // produced TWO back controls side by side. We keep only the system
            // back button, matching every other pushed screen (OtherProfileView,
            // SetDetailView).
            ToolbarItem(placement: .principal) {
                Text(post.isCustomBuild
                     ? post.customBuildName
                     : (legoSet?.name ?? post.legoSetName))
                    .font(.legoCardTitle).foregroundColor(.lightText).lineLimit(1)
            }
        }
        // PostDetailView's author row uses NavigationLink(value: post.username),
        // which resolves against the String destination declared ONCE at the
        // root of whichever tab's NavigationStack pushed this screen (Home,
        // Profile, Search and Leaderboard each register exactly one). We do NOT
        // declare another String destination here: a second one on the same
        // stack triggers SwiftUI's "navigationDestination for Swift.String was
        // declared earlier… only the root-most is used" warning. One per stack
        // keeps resolution unambiguous and the console clean.
        .sheet(isPresented: $showingShareCard) {
            StoryShareCardView(post: post)
        }
        .sheet(isPresented: $showingCommentSheet) {
            CommentSheetView(post: currentPost)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .alert("Report submitted", isPresented: $showReportConfirm) {
            Button("OK") {}
        } message: {
            Text("Thanks for keeping BrickFeed safe! Our team will review this report (reason: \(lastReportReason)) within 24 hours.")
        }
        .alert("Block @\(post.username)?", isPresented: $showBlockConfirm) {
            Button("Block", role: .destructive) {
                postStore.blockUser(userId: post.userId, username: post.username,
                                    reason: "Blocked from post detail menu")
                showBlockedConfirm = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All of @\(post.username)'s posts, comments, and messages will be hidden immediately.")
        }
        .blockConfirmationAlert(username: post.username, isPresented: $showBlockedConfirm)
        // Admin delete – step 1
        .alert("Delete this post?", isPresented: $showAdminDeleteConfirm1) {
            Button("Continue", role: .destructive) { showAdminDeleteConfirm2 = true }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently removes the post and all its comments for everyone.")
        }
        // Admin delete – step 2
        .alert("Are you sure?", isPresented: $showAdminDeleteConfirm2) {
            Button("Delete", role: .destructive) { adminDeletePost() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone.")
        }
        .alert("Delete failed", isPresented: Binding(
            get: { adminDeleteError != nil },
            set: { if !$0 { adminDeleteError = nil } }
        )) {
            Button("OK") {}
        } message: {
            Text(adminDeleteError ?? "")
        }
    }

    // MARK: - Helpers

    private func handleLikeTap() {
        guard !isLiking else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            postStore.toggleLike(post)
        }
        isLiking = true
        Task {
            let uid = UserSession.shared.uid
            guard !uid.isEmpty else { isLiking = false; return }
            do {
                let _ = try await FirebaseService.shared.toggleLike(
                    postId: post.id, postOwnerId: post.userId, currentUserId: uid)
            } catch {
                print("[PostDetailView] Like error: \(error)")
            }
            isLiking = false
        }
    }

    private func reportPost(reason: String) {
        postStore.reportPost(post)
        lastReportReason = reason
        showReportConfirm = true
        Task {
            let uid = UserSession.shared.uid
            let reporterUsername = UserSession.shared.username
            guard !uid.isEmpty else { return }
            try? await FirebaseService.shared.reportPost(
                postId: post.id,
                postOwnerId: post.userId,
                postOwnerUsername: post.username,
                reportedBy: uid,
                reportedByUsername: reporterUsername,
                reason: reason
            )
        }
    }

    private func adminDeletePost() {
        isAdminDeleting = true
        Task {
            let adminUid = UserSession.shared.uid
            let ownerUid = post.userId
            let postId   = post.id
            do {
                try await FirebaseService.shared.deletePost(postId, userId: ownerUid)
                await FirebaseService.shared.logModerationAction(
                    action: "remove_content",
                    adminUid: adminUid,
                    targetUserId: ownerUid,
                    contentType: "post",
                    contentId: postId,
                    note: "deleted on sight"
                )
                await MainActor.run {
                    postStore.posts.removeAll { $0.id == postId }
                    isAdminDeleting = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    adminDeleteError = error.localizedDescription
                    isAdminDeleting  = false
                }
            }
        }
    }

    // MARK: - Media Section (carousel or single image/video)

    @ViewBuilder
    private var mediaSection: some View {
        let allURLs = post.allImageURLs
        if allURLs.count > 1 {
            // Carousel for multiple photos
            TabView {
                ForEach(Array(allURLs.enumerated()), id: \.offset) { _, urlStr in
                    if let url = URL(string: urlStr) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let img): img.resizable().scaledToFill()
                            case .failure: gradientPlaceholder
                            case .empty:
                                ZStack { Color.black; ProgressView().tint(.legoYellow).scaleEffect(1.5) }
                            @unknown default: gradientPlaceholder
                            }
                        }
                        .clipped()
                    }
                }
            }
            .tabViewStyle(.page)
            .frame(height: UIScreen.main.bounds.width)
            .clipped()
        } else {
            squareMediaSection
        }
    }

    @ViewBuilder
    private var squareMediaSection: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                Group {
                    if let image = postStore.postImages[post.id] {
                        Image(uiImage: image).resizable().scaledToFill()
                    } else if let videoURL = postStore.postVideoURLs[post.id] {
                        VideoPlayer(player: AVPlayer(url: videoURL)).disabled(true)
                    } else if !post.imageURL.isEmpty, let url = URL(string: post.imageURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let img): img.resizable().scaledToFill()
                            case .failure: gradientPlaceholder
                            case .empty:
                                ZStack { Color.black; ProgressView().tint(.legoYellow).scaleEffect(1.5) }
                            @unknown default: gradientPlaceholder
                            }
                        }
                    } else if let imageURL = legoSet?.setImageURL {
                        AsyncImage(url: imageURL) { phase in
                            switch phase {
                            case .success(let img): img.resizable().scaledToFill()
                            case .failure: gradientPlaceholder
                            case .empty:
                                ZStack { Color.black; ProgressView().tint(.legoYellow).scaleEffect(1.5) }
                            @unknown default: gradientPlaceholder
                            }
                        }
                    } else {
                        gradientPlaceholder
                    }
                }
                .clipped()
            }
            .clipped()
    }

    private var gradientPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color.legoRed.opacity(0.3), Color.legoYellow.opacity(0.2)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            VStack(spacing: 10) {
                Image(systemName: post.isCustomBuild ? "hammer.fill" : "building.2.crop.circle")
                    .font(.system(size: 64)).foregroundColor(.secondaryText)
                Text(post.isCustomBuild ? post.customBuildName : "Set #\(post.legoSetNumber)")
                    .font(.legoScreenTitle).foregroundColor(.legoYellow)
            }
        }
    }

    @ViewBuilder
    private var heartOverlay: some View {
        if showHeartAnimation {
            Image(systemName: "heart.fill")
                .font(.system(size: 90))
                .foregroundColor(.legoRed.opacity(0.9))
                .scaleEffect(showHeartAnimation ? 1.0 : 0.1)
                .opacity(showHeartAnimation ? 1.0 : 0.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showHeartAnimation)
                .allowsHitTesting(false)
        }
    }

    // MARK: - Buy Set Section

    private func buySetSection(set: LegoSet) -> some View {
        VStack(spacing: 8) {
            if let url = URL(string: set.legoStoreURL) {
                Link(destination: url) { buySetLabel(price: set.retailPrice) }
            }
        }
    }

    private func buySetLabel(price: Double?) -> some View {
        HStack {
            Image(systemName: "cart.fill").font(.system(size: 18, weight: .bold))
            VStack(alignment: .leading, spacing: 2) {
                Text("Buy Set").font(.legoCardTitle)
                if let price = price {
                    Text("$\(String(format: "%.0f", price)) on the LEGO Store")
                        .font(.legoCaption)
                }
            }
            Spacer()
            Image(systemName: "arrow.up.right")
        }
        .foregroundColor(.darkBackground)
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(Color.legoYellow).cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        PostDetailView(post: .placeholder)
            .navigationDestination(for: String.self) { username in
                OtherProfileView(username: username)
            }
    }
}

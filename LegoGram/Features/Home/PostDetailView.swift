import SwiftUI
import AVKit

/// The full-screen detail view for a single LEGO build post.
struct PostDetailView: View {

    let post: LegoPost
    var scrollToComments: Bool = false

    @ObservedObject private var postStore = PostStore.shared
    @Environment(\.dismiss) private var dismiss

    @State private var commentText      = ""
    @State private var showingReportMenu = false
    @State private var showHeartAnimation = false
    @State private var showingShareCard  = false
    @State private var isLiking          = false
    @State private var isLoadingComments = false
    @FocusState private var commentFieldFocused: Bool

    private var comments: [Comment] {
        (postStore.comments[post.id] ?? []).sorted { $0.postedDate > $1.postedDate }
    }

    private var legoSet: LegoSet? { LegoSetDatabase.set(for: post.legoSetNumber) }

    var body: some View {
        ZStack {
            Color.darkBackground.ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {

                        // MARK: Square Media
                        squareMediaSection
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
                                        Text("@\(post.username)")
                                            .font(.legoCardTitle).foregroundColor(.lightText)
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

                            // Action row
                            HStack(spacing: 24) {
                                // Like button — syncs to Firestore
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
                                    commentFieldFocused = true
                                    withAnimation { proxy.scrollTo("comments-anchor", anchor: .top) }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "bubble.right.fill").font(.system(size: 20))
                                        Text("\(comments.count)").font(.legoBody)
                                    }
                                    .foregroundColor(.secondaryText)
                                }
                                .buttonStyle(.plain)

                                Spacer()

                                // Report menu
                                Menu {
                                    Button("Inappropriate content") { reportPost(reason: "Inappropriate content") }
                                    Button("Bullying") { reportPost(reason: "Bullying") }
                                    Button("Spam") { reportPost(reason: "Spam") }
                                    Button("Not LEGO related") { reportPost(reason: "Not LEGO related") }
                                } label: {
                                    Image(systemName: "flag").font(.system(size: 18)).foregroundColor(.secondaryText)
                                }
                            }

                            // Share to Stories button
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

                            // Buy Set (no earnings shown)
                            if !post.isCustomBuild {
                                if let set = legoSet { buySetSection(set: set) }
                                else if !post.buyLink.isEmpty, let url = URL(string: post.buyLink) {
                                    Link(destination: url) { buySetLabel(price: nil) }
                                }
                            }
                        }
                        .padding(16)

                        Divider().background(Color.secondaryText.opacity(0.4)).padding(.horizontal)

                        // MARK: Comments Section
                        commentsSection.id("comments-anchor")

                        Color.clear.frame(height: 16)
                    }
                }
                .onAppear {
                    if scrollToComments {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            withAnimation { proxy.scrollTo("comments-anchor", anchor: .top) }
                            commentFieldFocused = true
                        }
                    }
                    loadCommentsIfNeeded()
                }
                .onTapGesture { hideKeyboard() }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    commentInputBar
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.cardBackground, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(.legoYellow)
                }
            }
            ToolbarItem(placement: .principal) {
                Text(post.isCustomBuild
                     ? post.customBuildName
                     : (legoSet?.name ?? post.legoSetName))
                    .font(.legoCardTitle).foregroundColor(.lightText).lineLimit(1)
            }
        }
        .navigationDestination(for: String.self) { username in OtherProfileView(username: username) }
        .sheet(isPresented: $showingShareCard) {
            StoryShareCardView(post: post)
        }
    }

    // MARK: - Helpers

    private var currentPost: LegoPost {
        postStore.posts.first(where: { $0.id == post.id }) ?? post
    }

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
        Task {
            let uid = UserSession.shared.uid
            guard !uid.isEmpty else { return }
            try? await FirebaseService.shared.reportPost(postId: post.id, reportedBy: uid, reason: reason)
        }
    }

    private func loadCommentsIfNeeded() {
        guard postStore.comments(for: post.id).isEmpty else { return }
        isLoadingComments = true
        Task {
            if let fetched = try? await FirebaseService.shared.fetchComments(for: post.id) {
                await MainActor.run {
                    postStore.setComments(fetched, for: post.id)
                    isLoadingComments = false
                }
            } else {
                await MainActor.run { isLoadingComments = false }
            }
        }
    }

    // MARK: - Square Media Section

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

    // MARK: - Buy Set Section (no earnings shown)

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

    // MARK: - Comments Section

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Comments (\(comments.count))")
                    .font(.legoCardTitle).foregroundColor(.lightText)
                Spacer()
                if isLoadingComments {
                    ProgressView().tint(.legoYellow).scaleEffect(0.8)
                }
            }
            .padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 8)

            if comments.isEmpty && !isLoadingComments {
                Text("No comments yet — be the first! 🧱")
                    .font(.legoBody).foregroundColor(.secondaryText)
                    .padding(.horizontal, 16).padding(.vertical, 12)
            } else {
                ForEach(comments) { comment in
                    DetailCommentRow(comment: comment)
                }
            }
        }
    }

    // MARK: - Comment Input Bar

    private var commentInputBar: some View {
        HStack(spacing: 10) {
            TextField("Write a comment…", text: $commentText)
                .foregroundColor(.lightText).font(.legoBody)
                .padding(12).background(Color.cardBackground).cornerRadius(20)
                .focused($commentFieldFocused)
                .onSubmit { submitComment() }
                .onChange(of: commentText) { _, newValue in
                    if newValue.count > 200 { commentText = String(newValue.prefix(200)) }
                }

            Button { submitComment() } label: {
                Text("Send")
                    .font(.legoCaption.bold()).foregroundColor(.white)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(commentText.trimmingCharacters(in: .whitespaces).isEmpty
                                ? Color.legoRed.opacity(0.4) : Color.legoRed)
                    .cornerRadius(20)
            }
            .disabled(commentText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(
            Color.darkBackground
                .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: -3)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func submitComment() {
        let trimmed = commentText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let username = UserSession.shared.username
        let userId   = UserSession.shared.uid

        postStore.addComment(to: post, text: trimmed, username: username)
        commentText = ""
        commentFieldFocused = false

        Task {
            do {
                let _ = try await FirebaseService.shared.addComment(
                    to: post.id,
                    postOwnerId: post.userId,
                    text: trimmed,
                    userId: userId,
                    username: username
                )
            } catch {
                print("[PostDetailView] Comment save error: \(error)")
            }
        }
    }
}

// MARK: - Detail Comment Row (private to PostDetailView to avoid conflict with CommentRow in CommentSheetView)

private struct DetailCommentRow: View {
    let comment: Comment

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(Color.legoRed.opacity(0.8))
                .frame(width: 32, height: 32)
                .overlay(
                    Text(String(comment.username.prefix(1)).uppercased())
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("@\(comment.username)")
                        .font(.legoCaption).foregroundColor(.legoYellow)
                    Spacer()
                    Text(comment.timeAgo)
                        .font(.legoCaption).foregroundColor(.secondaryText)
                }
                Text(comment.text)
                    .font(.legoBody).foregroundColor(.lightText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
    }
}

#Preview {
    PostDetailView(post: .placeholder)
}

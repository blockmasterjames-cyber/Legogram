import SwiftUI
import AVKit

/// The full-screen detail view for a single LEGO build post.
/// Shows the photo or video, username, set info, likes, comments, and a Buy Set button.
/// Users can also report a post here to keep LegoGram safe.
struct PostDetailView: View {

    let post: LegoPost

    @ObservedObject private var postStore = PostStore.shared
    @Environment(\.dismiss) private var dismiss

    // Comment input
    @State private var commentText = ""
    @State private var showingReportAlert = false
    @State private var showHeartAnimation = false
    @FocusState private var commentFieldFocused: Bool

    private var comments: [Comment] { postStore.comments(for: post.id) }
    private var legoSet: LegoSet? { LegoSetDatabase.set(for: post.legoSetNumber) }

    // Affiliate earn estimate: ~0.4% of retail price
    private var estimatedEarn: Double {
        guard let set = legoSet else { return post.estimatedEarnings }
        return (set.retailPrice * 0.004).rounded(toPlaces: 2)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {

                        // MARK: Media (Photo or Video)
                        mediaSection
                            .gesture(
                                TapGesture(count: 2).onEnded {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                                        postStore.toggleLike(post)
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
                        VStack(alignment: .leading, spacing: 12) {

                            // Username row — tapping navigates to their profile
                            NavigationLink(value: post.username) {
                                HStack(spacing: 10) {
                                    Circle()
                                        .fill(Color.legoRed)
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Text(String(post.username.prefix(1)).uppercased())
                                                .font(.legoCardTitle)
                                                .foregroundColor(.white)
                                        )
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("@\(post.username)")
                                            .font(.legoCardTitle)
                                            .foregroundColor(.lightText)
                                        Text(post.postedDate.formatted(date: .abbreviated, time: .shortened))
                                            .font(.legoCaption)
                                            .foregroundColor(.secondaryText)
                                    }
                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)

                            // Set name + number
                            Text("Set #\(post.legoSetNumber)  ·  \(post.legoSetName)")
                                .font(.legoCardTitle)
                                .foregroundColor(.legoYellow)

                            // Theme (from database)
                            if let set = legoSet {
                                Text("\(set.theme)  ·  \(set.pieceCount) pieces")
                                    .font(.legoCaption)
                                    .foregroundColor(.secondaryText)
                            }

                            // Description
                            if !post.description.isEmpty {
                                Text(BadWordFilter.filter(post.description))
                                    .font(.legoBody)
                                    .foregroundColor(.lightText)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            // Likes + Comments row
                            HStack(spacing: 24) {
                                // Like button
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                                        postStore.toggleLike(post)
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: postStore.isLiked(post) ? "heart.fill" : "heart")
                                            .font(.system(size: 20))
                                        Text("\(currentPost.likeCount)")
                                            .font(.legoBody)
                                    }
                                    .foregroundColor(postStore.isLiked(post) ? .legoRed : .secondaryText)
                                }
                                .buttonStyle(.plain)

                                // Comment count
                                HStack(spacing: 6) {
                                    Image(systemName: "bubble.right.fill")
                                        .font(.system(size: 20))
                                    Text("\(comments.count)")
                                        .font(.legoBody)
                                }
                                .foregroundColor(.secondaryText)

                                Spacer()

                                // Report button
                                Button {
                                    showingReportAlert = true
                                } label: {
                                    Image(systemName: "flag")
                                        .font(.system(size: 18))
                                        .foregroundColor(.secondaryText)
                                }
                                .buttonStyle(.plain)
                            }

                            // Buy Set Button
                            if let set = legoSet {
                                buySetSection(set: set)
                            } else if !post.buyLink.isEmpty, let url = URL(string: post.buyLink) {
                                Link(destination: url) {
                                    buySetLabel(price: nil)
                                }
                            }

                            // Earnings callout
                            earningsCallout

                        }
                        .padding(16)

                        Divider()
                            .background(Color.secondaryText.opacity(0.4))
                            .padding(.horizontal)

                        // MARK: Comments Section
                        commentsSection

                        Color.clear.frame(height: 100)
                    }
                }

                // MARK: Comment Input (pinned to bottom)
                VStack {
                    Spacer()
                    commentInputBar
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.cardBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.legoYellow)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text(post.legoSetName)
                        .font(.legoCardTitle)
                        .foregroundColor(.lightText)
                }
            }
            .navigationDestination(for: String.self) { username in
                OtherProfileView(username: username)
            }
        }
        .alert("Report Post", isPresented: $showingReportAlert) {
            Button("Report", role: .destructive) {
                postStore.reportPost(post)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Thanks for helping keep LegoGram safe! Our team will review this post.")
        }
    }

    // MARK: - Current Post (live from store for like count updates)

    private var currentPost: LegoPost {
        postStore.posts.first(where: { $0.id == post.id }) ?? post
    }

    // MARK: - Media Section

    @ViewBuilder
    private var mediaSection: some View {
        if let image = postStore.postImages[post.id] {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .background(Color.black)
        } else if let videoURL = postStore.postVideoURLs[post.id] {
            VideoPlayer(player: AVPlayer(url: videoURL))
                .frame(height: 320)
        } else {
            ZStack {
                LinearGradient(
                    colors: [Color.legoRed.opacity(0.3), Color.legoYellow.opacity(0.2)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .frame(height: 300)

                VStack(spacing: 10) {
                    Image(systemName: "building.2.crop.circle")
                        .font(.system(size: 64))
                        .foregroundColor(.secondaryText)
                    Text("Set #\(post.legoSetNumber)")
                        .font(.legoScreenTitle)
                        .foregroundColor(.legoYellow)
                }
            }
        }
    }

    // MARK: - Heart Animation Overlay

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
        VStack(spacing: 10) {
            if let url = URL(string: set.legoStoreURL) {
                Link(destination: url) {
                    buySetLabel(price: set.retailPrice)
                }
            }
        }
    }

    private func buySetLabel(price: Double?) -> some View {
        HStack {
            Image(systemName: "cart.fill")
                .font(.system(size: 18, weight: .bold))
            VStack(alignment: .leading, spacing: 2) {
                Text("Buy Set on LEGO.com")
                    .font(.legoCardTitle)
                if let price = price {
                    Text("$\(String(format: "%.2f", price)) retail")
                        .font(.legoCaption)
                }
            }
            Spacer()
            Image(systemName: "arrow.up.right")
        }
        .foregroundColor(.darkBackground)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.legoYellow)
        .cornerRadius(12)
    }

    // MARK: - Earnings Callout

    @ViewBuilder
    private var earningsCallout: some View {
        if estimatedEarn > 0 {
            HStack(spacing: 8) {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(.successGreen)
                Text("Earn up to **$\(String(format: "%.2f", estimatedEarn))** when someone buys through your link!")
                    .font(.legoCaption)
                    .foregroundColor(.successGreen)
            }
            .padding(10)
            .background(Color.successGreen.opacity(0.12))
            .cornerRadius(10)
        }
    }

    // MARK: - Comments Section

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Comments (\(comments.count))")
                .font(.legoCardTitle)
                .foregroundColor(.lightText)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)

            if comments.isEmpty {
                Text("No comments yet — be the first! 👇")
                    .font(.legoBody)
                    .foregroundColor(.secondaryText)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            } else {
                ForEach(comments) { comment in
                    CommentRow(comment: comment)
                }
            }
        }
    }

    // MARK: - Comment Input Bar

    private var commentInputBar: some View {
        HStack(spacing: 10) {
            TextField("Add a comment...", text: $commentText)
                .foregroundColor(.lightText)
                .font(.legoBody)
                .padding(12)
                .background(Color.cardBackground)
                .cornerRadius(20)
                .focused($commentFieldFocused)
                .onChange(of: commentText) { _, newValue in
                    if newValue.count > 200 {
                        commentText = String(newValue.prefix(200))
                    }
                }

            Button {
                submitComment()
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(commentText.trimmingCharacters(in: .whitespaces).isEmpty
                                ? Color.legoRed.opacity(0.4)
                                : Color.legoRed)
                    .clipShape(Circle())
            }
            .disabled(commentText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.darkBackground.opacity(0.95))
    }

    // MARK: - Actions

    private func submitComment() {
        let trimmed = commentText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        postStore.addComment(to: post, text: trimmed)
        commentText = ""
        commentFieldFocused = false
    }
}

// MARK: - Comment Row

/// A single comment bubble with username, text, and time.
struct CommentRow: View {
    let comment: Comment

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(Color.legoRed.opacity(0.8))
                .frame(width: 32, height: 32)
                .overlay(
                    Text(String(comment.username.prefix(1)).uppercased())
                        .font(.legoCaption)
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("@\(comment.username)")
                        .font(.legoCaption)
                        .foregroundColor(.legoYellow)
                    Spacer()
                    Text(comment.timeAgo)
                        .font(.legoCaption)
                        .foregroundColor(.secondaryText)
                }
                Text(comment.text)
                    .font(.legoBody)
                    .foregroundColor(.lightText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

// MARK: - Double helper
private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

#Preview {
    PostDetailView(post: .placeholder)
}

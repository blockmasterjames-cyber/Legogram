import SwiftUI

/// A bottom sheet that shows comments for a post and lets the user add a new comment.
/// Opened from the feed by tapping the comment bubble icon.
struct CommentSheetView: View {

    let post: LegoPost
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var postStore = PostStore.shared
    @ObservedObject private var userSession = UserSession.shared

    @State private var commentText = ""
    @State private var isSubmitting = false
    @State private var isLoading = false
    @State private var badWordWarning = false
    @FocusState private var commentFocused: Bool

    private var comments: [Comment] {
        postStore.comments(for: post.id)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    sheetHeader
                    Divider().background(Color.secondaryText.opacity(0.3))

                    if isLoading {
                        Spacer()
                        ProgressView().tint(.legoYellow).scaleEffect(1.3)
                        Spacer()
                    } else if comments.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "bubble.right")
                                .font(.system(size: 48))
                                .foregroundColor(.secondaryText)
                            Text("No comments yet!")
                                .font(.legoCardTitle).foregroundColor(.lightText)
                            Text("Be the first to say something nice 🧱")
                                .font(.legoBody).foregroundColor(.secondaryText)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(comments) { comment in
                                    CommentRow(comment: comment)
                                    Divider().background(Color.secondaryText.opacity(0.15))
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }

                    Divider().background(Color.secondaryText.opacity(0.3))

                    if badWordWarning {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.legoYellow)
                            Text("Please keep BrickFeed friendly! 🧱")
                                .font(.legoCaption).foregroundColor(.legoYellow)
                        }
                        .padding(.horizontal, 16).padding(.vertical, 6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.legoYellow.opacity(0.1))
                    }

                    commentInputBar
                }
            }
        }
        .onAppear { loadComments() }
    }

    // MARK: - Header

    private var sheetHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Comments")
                    .font(.legoCardTitle).foregroundColor(.lightText)
                Text("\(comments.count) comment\(comments.count == 1 ? "" : "s")")
                    .font(.legoCaption).foregroundColor(.secondaryText)
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 26))
                    .foregroundColor(.secondaryText)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Comment Input Bar

    private var commentInputBar: some View {
        HStack(spacing: 12) {
            avatarCircle

            TextField("Add a comment…", text: $commentText, axis: .vertical)
                .lineLimit(1...4)
                .font(.legoBody)
                .foregroundColor(.lightText)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.cardBackground)
                .cornerRadius(20)
                .focused($commentFocused)
                .onChange(of: commentText) { _, newValue in
                    if newValue.count > 200 { commentText = String(newValue.prefix(200)) }
                    if BadWordFilter.containsBadWords(newValue) {
                        withAnimation { badWordWarning = true }
                    } else {
                        withAnimation { badWordWarning = false }
                    }
                }

            Button {
                submitComment()
            } label: {
                if isSubmitting {
                    ProgressView().tint(.legoYellow).frame(width: 32, height: 32)
                } else {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20))
                        .foregroundColor(commentText.trimmingCharacters(in: .whitespaces).isEmpty
                                        ? .secondaryText : .legoYellow)
                }
            }
            .disabled(commentText.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.darkBackground)
    }

    // MARK: - Current User Avatar

    @ViewBuilder
    private var avatarCircle: some View {
        let letter = String(userSession.username.prefix(1)).uppercased()
        if let img = userSession.avatarImage {
            Image(uiImage: img)
                .resizable().scaledToFill()
                .frame(width: 34, height: 34)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(Color.legoRed)
                .frame(width: 34, height: 34)
                .overlay(
                    Text(letter.isEmpty ? "?" : letter)
                        .font(.legoCaption).foregroundColor(.white)
                )
        }
    }

    // MARK: - Load Comments

    private func loadComments() {
        guard postStore.comments(for: post.id).isEmpty else { return }
        isLoading = true
        Task {
            do {
                let fetched = try await FirebaseService.shared.fetchComments(for: post.id)
                await MainActor.run {
                    postStore.setComments(fetched, for: post.id)
                    isLoading = false
                }
            } catch {
                await MainActor.run { isLoading = false }
            }
        }
    }

    // MARK: - Submit Comment

    private func submitComment() {
        let text = commentText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        isSubmitting = true
        badWordWarning = false

        Task {
            let username    = userSession.username
            let userId      = userSession.uid
            let postOwnerId = post.userId
            let avatarURL   = userSession.currentUser?.avatarURL ?? ""

            postStore.addComment(to: post, text: text, username: username)

            do {
                let _ = try await FirebaseService.shared.addComment(
                    to: post.id,
                    postOwnerId: postOwnerId,
                    text: text,
                    userId: userId,
                    username: username,
                    avatarURL: avatarURL
                )
            } catch {
                print("[CommentSheetView] Error saving comment: \(error)")
            }

            await MainActor.run {
                commentText  = ""
                isSubmitting = false
                commentFocused = false
            }
        }
    }
}

// MARK: - Comment Row (used in both CommentSheetView and other contexts)

struct CommentRow: View {
    let comment: Comment

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar: show photo if URL available, otherwise colored initial circle
            Group {
                if !comment.avatarURL.isEmpty, let url = URL(string: comment.avatarURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().scaledToFill()
                                .frame(width: 36, height: 36)
                                .clipShape(Circle())
                        default:
                            initialCircle
                        }
                    }
                } else {
                    initialCircle
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("@\(comment.username)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.lightText)
                    Text(comment.timeAgo)
                        .font(.legoCaption)
                        .foregroundColor(.secondaryText)
                }
                Text(comment.text)
                    .font(.legoBody)
                    .foregroundColor(.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var initialCircle: some View {
        Circle()
            .fill(avatarColor(for: comment.username))
            .frame(width: 36, height: 36)
            .overlay(
                Text(String(comment.username.prefix(1)).uppercased())
                    .font(.legoCaption).foregroundColor(.white)
            )
    }

    private func avatarColor(for username: String) -> Color {
        let colors: [Color] = [Color.legoRed.opacity(0.8), .blue, .purple, .orange, .pink, .teal]
        let index = abs(username.hashValue) % colors.count
        return colors[index]
    }
}

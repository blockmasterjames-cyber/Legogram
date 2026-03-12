import SwiftUI

/// Displays another user's LEGO profile page.
/// Shows their stats, post grid, and Follow / Unfollow button.
/// The current user can also Block the user from this screen.
struct OtherProfileView: View {

    let username: String

    @ObservedObject private var postStore = PostStore.shared
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var showingBlockAlert = false
    @State private var showingBlockedConfirm = false

    private var theirPosts: [LegoPost] {
        postStore.posts.filter { $0.username == username }
    }

    private var setsCompleted: Int {
        Set(theirPosts.map { $0.legoSetNumber }).count
    }

    private var gridColumns: [GridItem] {
        let count = horizontalSizeClass == .regular ? 4 : 3
        return Array(repeating: GridItem(.flexible(), spacing: 2), count: count)
    }

    var body: some View {
        ZStack {
            Color.darkBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {

                    // MARK: Cover Photo
                    coverPhoto

                    // MARK: Avatar + Follow Button Row
                    avatarAndFollowRow

                    // MARK: Username & Bio
                    VStack(alignment: .leading, spacing: 6) {
                        Text("@\(username)")
                            .font(.legoScreenTitle)
                            .foregroundColor(.lightText)

                        Text("LEGO fan sharing builds on BrickFeed 🧱")
                            .font(.legoBody)
                            .foregroundColor(.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 48)
                    .padding(.bottom, 16)

                    // MARK: Stats Row (5 stats)
                    statsRow

                    // MARK: Post Grid
                    if theirPosts.isEmpty {
                        emptyPostsState
                    } else {
                        LazyVGrid(columns: gridColumns, spacing: 2) {
                            ForEach(theirPosts) { post in
                                gridTile(for: post)
                            }
                        }
                        .padding(.top, 2)
                    }

                    Color.clear.frame(height: 80)
                }
            }
        }
        .navigationTitle("@\(username)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        showingBlockAlert = true
                    } label: {
                        Label("Block @\(username)", systemImage: "hand.raised.fill")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.legoYellow)
                }
            }
        }
        // Block confirmation
        .alert("Block @\(username)?", isPresented: $showingBlockAlert) {
            Button("Block", role: .destructive) {
                postStore.blockUser(username)
                showingBlockedConfirm = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Blocking this user will hide all of their posts from your feed. You can unblock them in Settings.")
        }
        .alert("@\(username) has been blocked.", isPresented: $showingBlockedConfirm) {
            Button("OK") {}
        } message: {
            Text("You won't see their posts anymore. Thanks for keeping BrickFeed safe!")
        }
    }

    // MARK: - Sub-Views

    private var coverPhoto: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [Color.legoRed, Color.legoYellow.opacity(0.5)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .frame(height: 160)

            HStack(spacing: 20) {
                ForEach(0..<8, id: \.self) { _ in
                    Circle()
                        .fill(.white.opacity(0.15))
                        .frame(width: 24, height: 24)
                }
            }
            .padding(.bottom, 16)
            .padding(.leading, 12)
        }
    }

    private var avatarAndFollowRow: some View {
        HStack(alignment: .bottom) {
            // Avatar
            Circle()
                .fill(Color.cardBackground)
                .frame(width: 90, height: 90)
                .overlay(
                    Text(String(username.prefix(1)).uppercased())
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.legoYellow)
                )
                .overlay(Circle().stroke(Color.darkBackground, lineWidth: 4))
                .offset(y: -40)
                .padding(.leading, 16)

            Spacer()

            // Follow / Unfollow
            Button {
                postStore.toggleFollow(username)
            } label: {
                let following = postStore.isFollowing(username)
                Text(following ? "Following" : "Follow")
                    .font(.legoCaption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 9)
                    .background(following ? Color.cardBackground : Color.legoRed)
                    .foregroundColor(following ? .lightText : .white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(following ? Color.secondaryText : Color.clear, lineWidth: 1)
                    )
            }
            .padding(.trailing, 16)
            .padding(.bottom, 8)
        }
        .padding(.bottom, -32)
    }

    private var statsRow: some View {
        HStack(spacing: 0) {
            statCell(value: "\(theirPosts.count)", label: "Posts")
            Divider().frame(height: 40)
            statCell(value: "847", label: "Followers")
            Divider().frame(height: 40)
            statCell(value: "213", label: "Following")
            Divider().frame(height: 40)
            statCell(value: "$8.40", label: "Earnings")
            Divider().frame(height: 40)
            statCell(value: "\(setsCompleted)", label: "Completed")
        }
        .padding(.vertical, 12)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.legoCardTitle)
                .foregroundColor(.lightText)
            Text(label)
                .font(.legoCaption)
                .foregroundColor(.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func gridTile(for post: LegoPost) -> some View {
        ZStack {
            if let image = postStore.postImages[post.id] {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .aspectRatio(1, contentMode: .fill)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.legoRed.opacity(0.25))
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        Text("#\(post.legoSetNumber)")
                            .font(.legoCaption)
                            .foregroundColor(.legoYellow)
                    )
            }

            // Video badge
            if post.isVideoPost {
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "play.circle.fill")
                            .foregroundColor(.white)
                            .padding(4)
                    }
                    Spacer()
                }
            }
        }
    }

    private var emptyPostsState: some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.circle")
                .font(.system(size: 56))
                .foregroundColor(.secondaryText)
            Text("@\(username) hasn't posted yet")
                .font(.legoCardTitle)
                .foregroundColor(.lightText)
            Text("Check back later for some awesome LEGO builds!")
                .font(.legoBody)
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
        .padding(.horizontal)
    }
}

#Preview {
    NavigationStack {
        OtherProfileView(username: "brickmaster99")
    }
}

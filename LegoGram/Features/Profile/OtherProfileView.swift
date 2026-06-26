import SwiftUI

/// Displays another user's LEGO profile page.
/// Shows their stats, post grid, and Follow / Unfollow button.
/// The current user can also Block the user from this screen.
struct OtherProfileView: View {

    let username: String

    @ObservedObject private var postStore = PostStore.shared
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage("settings_kidSafeMode") private var kidSafeMode = false
    @State private var showingBlockAlert = false
    @State private var showingBlockedConfirm = false
    @State private var showingMessageThread = false
    @State private var dmConversation: DMConversation?
    @State private var isStartingConversation = false
    @State private var showReportConfirm = false
    @State private var selectedPost: LegoPost?
    @State private var profileUser: User?

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
                        HStack(spacing: 6) {
                            Text("@\(username)")
                                .font(.legoScreenTitle)
                                .foregroundColor(.lightText)
                            AdminBadge(uid: targetUserId, size: 16)
                        }

                        Text("Brick fan sharing builds on BrickFeed 🧱")
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
                                Button { selectedPost = post } label: {
                                    gridTile(for: post)
                                }
                                .buttonStyle(.plain)
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
        .task(id: targetUserId) {
            guard !targetUserId.isEmpty else { return }
            profileUser = try? await FirebaseService.shared.fetchUser(userId: targetUserId)
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Section("Report this user") {
                        Button("Inappropriate content") { submitReport(reason: "Inappropriate content") }
                        Button("Bullying or harassment") { submitReport(reason: "Bullying or harassment") }
                        Button("Spam") { submitReport(reason: "Spam") }
                        Button("Impersonation") { submitReport(reason: "Impersonation") }
                    }
                    Section {
                        Button(role: .destructive) {
                            showingBlockAlert = true
                        } label: {
                            Label("Block @\(username)", systemImage: "hand.raised.fill")
                        }
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
                postStore.blockUser(userId: targetUserId, username: username,
                                    reason: "Blocked from profile")
                showingBlockedConfirm = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Blocking this user will instantly hide all of their posts, comments, and messages from you. The block persists across devices and app restarts.")
        }
        .blockConfirmationAlert(username: username, isPresented: $showingBlockedConfirm)
        .reportConfirmationAlert(isPresented: $showReportConfirm)
        // Two destinations on the same stack, driven by independent state:
        // a tapped thumbnail (item:) opens PostDetailView, and the Message
        // button (isPresented:) opens the DM thread. Both live here at the
        // top level so they coexist cleanly.
        .navigationDestination(item: $selectedPost) { post in
            PostDetailView(post: post)
        }
        .navigationDestination(isPresented: $showingMessageThread) {
            if let conv = dmConversation {
                DirectMessageThreadView(conversation: conv)
            }
        }
    }

    /// Resolves the userId for the displayed username from the post store.
    /// Empty string if no post found — Firestore block still gets written
    /// using the username-only path in PostStore.
    private var targetUserId: String {
        postStore.posts.first(where: { $0.username == username })?.userId ?? ""
    }

    /// The recipient uid to open a DM with. Prefers the fetched user doc
    /// (`profileUser`), falling back to the post-derived `targetUserId`.
    /// Empty only if neither is available yet, in which case the Message
    /// button is disabled rather than firing with a placeholder uid.
    private var messageRecipientId: String {
        if let id = profileUser?.id, !id.isEmpty { return id }
        return targetUserId
    }

    /// Opens (or creates) a real, persisted DM conversation with this user.
    ///
    /// Mirrors `NewMessageView.startConversation` — it routes through
    /// `FirebaseService.getOrCreateConversation` using the recipient's REAL
    /// uid, so the conversation document is written to Firestore with both
    /// participant_ids and actually reaches the recipient. The returned
    /// conversation is inserted into `DMStore.shared.conversations` (keyed on
    /// the Firestore conversation id) BEFORE navigating, so the thread's
    /// `sendMessage(in: convId)` can find it and the very first message
    /// persists instead of being dropped.
    private func startConversation() {
        let recipientId = messageRecipientId
        guard !recipientId.isEmpty, !isStartingConversation else { return }
        isStartingConversation = true

        Task {
            let currentUserId   = UserSession.shared.uid
            let currentUsername = UserSession.shared.username
            do {
                let convId = try await FirebaseService.shared.getOrCreateConversation(
                    currentUserId:   currentUserId,
                    currentUsername: currentUsername,
                    otherUserId:     recipientId,
                    otherUsername:   username
                )
                await MainActor.run {
                    // Reuse an already-loaded conversation (keeps its messages);
                    // otherwise insert a fresh one keyed on the real convId.
                    let conv: DMConversation
                    if let existing = DMStore.shared.conversations.first(where: { $0.id == convId }) {
                        conv = existing
                    } else {
                        conv = DMConversation(
                            id: convId,
                            otherUserId: recipientId,
                            otherUsername: username,
                            messages: []
                        )
                        DMStore.shared.conversations.append(conv)
                    }
                    dmConversation = conv
                    isStartingConversation = false
                    showingMessageThread = true
                }
            } catch {
                // Network fallback: still open a store-backed conversation keyed
                // on the real recipient uid so it can persist once back online.
                await MainActor.run {
                    dmConversation = DMStore.shared.conversation(with: username, userId: recipientId)
                    isStartingConversation = false
                    showingMessageThread = true
                }
            }
        }
    }

    private func submitReport(reason: String) {
        showReportConfirm = true
        Task {
            let uid = UserSession.shared.uid
            let reporterUsername = UserSession.shared.username
            guard !uid.isEmpty else { return }
            try? await FirebaseService.shared.reportContent(
                contentType:        "user",
                contentId:          targetUserId.isEmpty ? username : targetUserId,
                reportedUserId:     targetUserId,
                reportedUsername:   username,
                reportedBy:         uid,
                reportedByUsername: reporterUsername,
                reason:             reason
            )
        }
    }

    // MARK: - Sub-Views

    private var coverPhoto: some View {
        ZStack(alignment: .bottomLeading) {
            if let bgURL = profileUser?.backgroundURL, !bgURL.isEmpty, let url = URL(string: bgURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                            .frame(height: 160).clipped()
                    default:
                        gradientBanner
                    }
                }
                .frame(height: 160)
            } else {
                gradientBanner
            }
        }
    }

    private var gradientBanner: some View {
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
            Group {
                if let avatarURL = profileUser?.avatarURL, !avatarURL.isEmpty,
                   let url = URL(string: avatarURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().scaledToFill()
                                .frame(width: 90, height: 90)
                                .clipShape(Circle())
                        default:
                            initialLetterAvatar
                        }
                    }
                    .frame(width: 90, height: 90)
                } else {
                    initialLetterAvatar
                }
            }
            .overlay(Circle().stroke(Color.darkBackground, lineWidth: 4))
            .offset(y: -40)
            .padding(.leading, 16)

            Spacer()

            HStack(spacing: 8) {
                // Follow / Unfollow
                Button {
                    // Prefer the freshly-fetched profile doc id (reliable even
                    // when the user has no post in the loaded feed); fall back to
                    // the post-derived uid. Routes through the shared helper so
                    // Firestore counters + subcollections + both in-memory
                    // mechanisms all update together.
                    let uid = profileUser?.id ?? targetUserId
                    guard !uid.isEmpty else { return }
                    let shouldFollow = !postStore.isFollowing(username)
                    Task {
                        await postStore.performFollow(targetUid: uid, username: username, shouldFollow: shouldFollow)
                    }
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

                // Message button (available unless Safe Mode is on)
                if !kidSafeMode {
                    Button {
                        startConversation()
                    } label: {
                        Group {
                            if isStartingConversation {
                                ProgressView()
                                    .tint(.legoYellow)
                                    .frame(width: 16, height: 16)
                            } else {
                                Image(systemName: "message.fill")
                                    .font(.system(size: 14, weight: .bold))
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(Color.cardBackground)
                        .foregroundColor(.legoYellow)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.legoYellow.opacity(0.5), lineWidth: 1)
                        )
                    }
                    // Don't fire with an empty recipient uid (profile doc not
                    // loaded yet / user has no posts) — that produced a fake,
                    // non-persisting "other-user" conversation.
                    .disabled(messageRecipientId.isEmpty || isStartingConversation)
                    .opacity(messageRecipientId.isEmpty ? 0.5 : 1)
                }
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
            statCell(value: "\(profileUser?.followerCount ?? 0)", label: "Followers")
            Divider().frame(height: 40)
            statCell(value: "\(profileUser?.followingCount ?? 0)", label: "Following")
            Divider().frame(height: 40)
            statCell(value: "\(setsCompleted)", label: "Completed")
        }
        .padding(.vertical, 12)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }

    private var initialLetterAvatar: some View {
        Circle()
            .fill(Color.cardBackground)
            .frame(width: 90, height: 90)
            .overlay(
                Text(String(username.prefix(1)).uppercased())
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.legoYellow)
            )
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
            Color.clear
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    Group {
                        if let image = postStore.postImages[post.id] {
                            Image(uiImage: image).resizable().scaledToFill()
                        } else if !post.imageURL.isEmpty, let url = URL(string: post.imageURL) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let img): img.resizable().scaledToFill()
                                case .empty:
                                    ZStack {
                                        Color.legoRed.opacity(0.2)
                                        ProgressView().tint(.legoYellow).scaleEffect(0.7)
                                    }
                                default: setNumberPlaceholder(for: post)
                                }
                            }
                        } else if post.isCustomBuild {
                            ZStack {
                                Color.blue.opacity(0.22)
                                VStack(spacing: 4) {
                                    Image(systemName: "hammer.fill")
                                        .font(.system(size: 20)).foregroundColor(.legoYellow)
                                    Text(post.customBuildName.isEmpty ? "Custom" : post.customBuildName)
                                        .font(.legoCaption).foregroundColor(.legoYellow)
                                        .multilineTextAlignment(.center).lineLimit(2).padding(.horizontal, 4)
                                }
                            }
                        } else if let url = LegoSetDatabase.set(for: post.legoSetNumber)?.setImageURL {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let img): img.resizable().scaledToFill()
                                case .empty:
                                    ZStack {
                                        Color.legoRed.opacity(0.2)
                                        ProgressView().tint(.legoYellow).scaleEffect(0.7)
                                    }
                                default: setNumberPlaceholder(for: post)
                                }
                            }
                        } else {
                            setNumberPlaceholder(for: post)
                        }
                    }
                    .clipped()
                }
                .clipped()

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

    private func setNumberPlaceholder(for post: LegoPost) -> some View {
        ZStack {
            Color.legoRed.opacity(0.25)
            Text("#\(post.legoSetNumber)").font(.legoCaption).foregroundColor(.legoYellow)
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
            Text("Check back later for some awesome brick builds!")
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

import SwiftUI

/// The Profile screen — your personal LEGO portfolio page!
/// Sprint 3 upgrades: Sets Completed stat, iPad 4-column grid, bad word filter on bio.
struct ProfileView: View {

    @AppStorage("profile_displayName") private var displayName = "blockmasterjames"
    @AppStorage("profile_bio")         private var bio         = "Building one brick at a time 🧱 | LEGO fan since 2010"
    @AppStorage("profile_username")    private var username    = "blockmasterjames"

    @State private var showingEditProfile = false
    @State private var showingSettings    = false

    @ObservedObject private var postStore = PostStore.shared
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var myPosts: [LegoPost] {
        postStore.posts.filter { $0.userId == "current-user" || $0.username == "brickmaster99" }
    }

    private var setsCompleted: Int {
        Set(myPosts.map { $0.legoSetNumber }).count
    }

    private var gridColumns: [GridItem] {
        let count = horizontalSizeClass == .regular ? 4 : 3
        return Array(repeating: GridItem(.flexible(), spacing: 2), count: count)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {

                        // MARK: Cover Photo
                        coverPhoto

                        // MARK: Avatar + Edit Button
                        avatarRow

                        // MARK: Username & Bio
                        VStack(alignment: .leading, spacing: 6) {
                            Text("@\(username)")
                                .font(.legoScreenTitle)
                                .foregroundColor(.lightText)

                            if !displayName.isEmpty {
                                Text(displayName)
                                    .font(.legoCardTitle)
                                    .foregroundColor(.legoYellow)
                            }

                            Text(BadWordFilter.filter(bio))
                                .font(.legoBody)
                                .foregroundColor(.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.top, 48)
                        .padding(.bottom, 16)

                        // MARK: Stats Row (5 stats: Posts / Followers / Following / Earnings / Completed)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 0) {
                                statCell(value: "\(myPosts.count)", label: "Posts")
                                Divider().frame(height: 40)
                                statCell(value: "1.2k",   label: "Followers")
                                Divider().frame(height: 40)
                                statCell(value: "348",    label: "Following")
                                Divider().frame(height: 40)
                                statCell(value: "$12.40", label: "Earnings")
                                Divider().frame(height: 40)
                                statCell(value: "\(setsCompleted)", label: "Completed")
                            }
                            .padding(.vertical, 12)
                        }
                        .background(Color.cardBackground)
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)

                        // MARK: Post Grid (3-col iPhone, 4-col iPad)
                        if myPosts.isEmpty {
                            emptyPostsState
                        } else {
                            LazyVGrid(columns: gridColumns, spacing: 2) {
                                ForEach(myPosts) { post in
                                    gridTile(for: post)
                                }
                            }
                        }

                        Color.clear.frame(height: 80)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingSettings = true } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.legoYellow)
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditProfile) { EditProfileView() }
        .sheet(isPresented: $showingSettings) { SettingsView() }
    }

    // MARK: - Sub-Views

    private var coverPhoto: some View {
        ZStack(alignment: .bottomLeading) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.legoRed, Color.legoYellow.opacity(0.6)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
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

    private var avatarRow: some View {
        HStack(alignment: .bottom) {
            Circle()
                .fill(Color.cardBackground)
                .frame(width: 90, height: 90)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.secondaryText)
                )
                .overlay(Circle().stroke(Color.darkBackground, lineWidth: 4))
                .offset(y: -40)
                .padding(.leading, 16)

            Spacer()

            Button { showingEditProfile = true } label: {
                Text("Edit Profile")
                    .font(.legoCaption)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.cardBackground)
                    .foregroundColor(.lightText)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondaryText, lineWidth: 1))
            }
            .padding(.trailing, 16)
            .padding(.bottom, 8)
        }
        .padding(.bottom, -32)
    }

    private var emptyPostsState: some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.circle")
                .font(.system(size: 56))
                .foregroundColor(.secondaryText)
            Text("No posts yet")
                .font(.legoCardTitle)
                .foregroundColor(.lightText)
            Text("Share your first LEGO build using the + button!")
                .font(.legoBody)
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
        .padding(.horizontal)
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

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.legoCardTitle)
                .foregroundColor(.lightText)
            Text(label)
                .font(.legoCaption)
                .foregroundColor(.secondaryText)
        }
        .frame(minWidth: 68)
        .padding(.horizontal, 4)
    }
}

#Preview {
    ProfileView()
}

import SwiftUI

/// The Profile screen — your personal LEGO portfolio page!
/// Shows your avatar, username, bio, stats, and a grid of every post you've shared.
/// Tap "Edit Profile" to change your name or bio. Tap the gear icon for Settings.
struct ProfileView: View {

    // Profile data — written by EditProfileView, read here
    @AppStorage("profile_displayName") private var displayName = "blockmasterjames"
    @AppStorage("profile_bio")         private var bio         = "Building one brick at a time 🧱 | LEGO fan since 2010"
    @AppStorage("profile_username")    private var username    = "blockmasterjames"

    // Sheets
    @State private var showingEditProfile = false
    @State private var showingSettings    = false

    // Posts that belong to the current user
    @ObservedObject private var postStore = PostStore.shared

    private var myPosts: [LegoPost] {
        // Show posts the user created this session, plus the seed placeholder for "brickmaster99"
        postStore.posts.filter { $0.userId == "current-user" || $0.username == "brickmaster99" }
    }

    private let gridColumns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

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

                            Text(bio)
                                .font(.legoBody)
                                .foregroundColor(.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.top, 48)
                        .padding(.bottom, 16)

                        // MARK: Stats Row
                        HStack(spacing: 0) {
                            statCell(value: "\(myPosts.count)", label: "Posts")
                            Divider().frame(height: 40)
                            statCell(value: "1.2k",   label: "Followers")
                            Divider().frame(height: 40)
                            statCell(value: "348",    label: "Following")
                            Divider().frame(height: 40)
                            statCell(value: "$12.40", label: "Earnings")
                        }
                        .padding(.vertical, 12)
                        .background(Color.cardBackground)
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)

                        // MARK: Post Grid
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
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.legoYellow)
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }

    // MARK: - Sub-Views

    private var coverPhoto: some View {
        ZStack(alignment: .bottomLeading) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.legoRed, Color.legoYellow.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 160)

            // Decorative LEGO stud pattern
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
            // Avatar circle
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

            // Edit Profile button
            Button {
                showingEditProfile = true
            } label: {
                Text("Edit Profile")
                    .font(.legoCaption)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.cardBackground)
                    .foregroundColor(.lightText)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondaryText, lineWidth: 1)
                    )
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
    }

    // MARK: - Stat Cell

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
}

#Preview {
    ProfileView()
}

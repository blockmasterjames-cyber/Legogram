import SwiftUI
import PhotosUI

/// The Profile screen — your personal LEGO portfolio page.
/// Sprint 6 upgrades:
/// Feature 1: Tapping the avatar opens the photo picker immediately.
/// Feature 2: Avatar saved to FileManager so it persists between launches.
/// Feature 3: Picking a background photo shows CropView before saving.
/// Feature 4: Every post tile in the grid is tappable → PostDetailView.
struct ProfileView: View {

    @AppStorage("profile_displayName")   private var displayName   = "blockmasterjames"
    @AppStorage("profile_bio")           private var bio           = "Building one brick at a time 🧱 | LEGO fan since 2010"
    @AppStorage("profile_username")      private var username      = "blockmasterjames"
    @AppStorage("profile_hasBackground") private var hasBackground = false
    @AppStorage("profile_hasAvatar")     private var hasAvatar     = false

    @State private var showingEditProfile  = false
    @State private var showingSettings     = false
    @State private var backgroundImage: UIImage?
    @State private var avatarImage: UIImage?

    // Background picker + crop
    @State private var selectedBgItem: PhotosPickerItem?
    @State private var showingBgPicker    = false
    @State private var showingCropView    = false
    @State private var imageToCrop: UIImage?

    // Avatar picker (Feature 1 & 2)
    @State private var selectedAvatarItem: PhotosPickerItem?
    @State private var showingAvatarPicker = false

    // Navigation to post detail (Feature 4)
    @State private var selectedPost: LegoPost?

    @ObservedObject private var postStore = PostStore.shared
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var myPosts: [LegoPost] {
        postStore.posts.filter { $0.userId == "current-user" || $0.username == "brickmaster99" }
    }

    private var setsCompleted: Int {
        Set(myPosts.filter { !$0.isCustomBuild }.map { $0.legoSetNumber }).count
    }

    private var gridColumns: [GridItem] {
        let count = horizontalSizeClass == .regular ? 4 : 3
        return Array(repeating: GridItem(.flexible(), spacing: 2), count: count)
    }

    // MARK: - FileManager URLs

    private var backgroundPhotoURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("profile_background.jpg")
    }

    private var avatarPhotoURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("profile_avatar.jpg")
    }

    // MARK: - Persistence

    private func saveBackground(_ image: UIImage) {
        if let data = image.jpegData(compressionQuality: 0.80) {
            try? data.write(to: backgroundPhotoURL)
            hasBackground = true
        }
    }

    private func loadBackground() {
        guard hasBackground else { return }
        if let data = try? Data(contentsOf: backgroundPhotoURL),
           let img  = UIImage(data: data) { backgroundImage = img }
    }

    private func saveAvatar(_ image: UIImage) {
        if let data = image.jpegData(compressionQuality: 0.85) {
            try? data.write(to: avatarPhotoURL)
            hasAvatar = true
        }
    }

    private func loadAvatar() {
        guard hasAvatar else { return }
        if let data = try? Data(contentsOf: avatarPhotoURL),
           let img  = UIImage(data: data) { avatarImage = img }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        coverPhoto
                        avatarRow
                        userInfoSection
                        statsGrid
                        postGrid
                        Color.clear.frame(height: 80)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingSettings = true } label: {
                        Image(systemName: "gearshape.fill").foregroundColor(.legoYellow)
                    }
                }
            }
            // Feature 4: navigate to post detail when tile tapped
            .navigationDestination(item: $selectedPost) { post in
                PostDetailView(post: post)
            }
        }
        .sheet(isPresented: $showingEditProfile) { EditProfileView() }
        .sheet(isPresented: $showingSettings)    { SettingsView() }
        // CropView for background photo (Feature 3)
        .fullScreenCover(isPresented: $showingCropView) {
            if let img = imageToCrop {
                CropView(
                    image: img,
                    onDone: { cropped in
                        backgroundImage   = cropped
                        saveBackground(cropped)
                        showingCropView   = false
                        imageToCrop       = nil
                    },
                    onCancel: {
                        showingCropView = false
                        imageToCrop     = nil
                    }
                )
            }
        }
        // Background photo picker
        .photosPicker(isPresented: $showingBgPicker,
                      selection: $selectedBgItem,
                      matching: .images)
        .onChange(of: selectedBgItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let img  = UIImage(data: data) {
                    imageToCrop     = img
                    showingCropView = true
                }
            }
        }
        // Avatar photo picker (Features 1 & 2)
        .photosPicker(isPresented: $showingAvatarPicker,
                      selection: $selectedAvatarItem,
                      matching: .images)
        .onChange(of: selectedAvatarItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let img  = UIImage(data: data) {
                    avatarImage = img
                    saveAvatar(img)        // Feature 2: persist immediately
                }
            }
        }
        .onAppear {
            loadBackground()
            loadAvatar()
        }
    }

    // MARK: - Cover Photo (tappable background)

    private var coverPhoto: some View {
        ZStack(alignment: .bottomLeading) {
            if let bg = backgroundImage {
                Image(uiImage: bg)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 160)
                    .clipped()
            } else {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.legoRed, Color.legoYellow.opacity(0.6)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 160)
                    .overlay(
                        HStack(spacing: 20) {
                            ForEach(0..<8, id: \.self) { _ in
                                Circle().fill(.white.opacity(0.15)).frame(width: 24, height: 24)
                            }
                        }
                        .padding(.bottom, 16).padding(.leading, 12),
                        alignment: .bottomLeading
                    )
            }
            // Camera hint (bottom-right corner)
            VStack {
                HStack {
                    Spacer()
                    ZStack {
                        Circle().fill(Color.black.opacity(0.45)).frame(width: 36, height: 36)
                        Image(systemName: "camera.fill")
                            .font(.system(size: 16)).foregroundColor(.white)
                    }
                    .padding(8)
                }
                Spacer()
            }
            .frame(height: 160)
        }
        .frame(height: 160)
        .onTapGesture { showingBgPicker = true }
    }

    // MARK: - Avatar Row
    // Feature 1: tapping the avatar opens the photo picker immediately

    private var avatarRow: some View {
        HStack(alignment: .bottom) {

            // Tappable avatar (Feature 1)
            Button { showingAvatarPicker = true } label: {
                ZStack(alignment: .bottomTrailing) {
                    Circle()
                        .fill(Color.cardBackground)
                        .frame(width: 90, height: 90)
                        .overlay(
                            Group {
                                if let avatar = avatarImage {
                                    Image(uiImage: avatar)
                                        .resizable()
                                        .scaledToFill()
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 44))
                                        .foregroundColor(.secondaryText)
                                }
                            }
                        )
                        .overlay(Circle().stroke(Color.darkBackground, lineWidth: 4))

                    // Camera badge in bottom-right
                    Circle()
                        .fill(Color.legoRed)
                        .frame(width: 26, height: 26)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 11)).foregroundColor(.white)
                        )
                        .offset(x: 2, y: 2)
                }
            }
            .buttonStyle(.plain)
            .offset(y: -40)
            .padding(.leading, 16)

            Spacer()

            // Edit Profile button (name/bio only — avatar is now tappable directly)
            Button { showingEditProfile = true } label: {
                Text("Edit Profile")
                    .font(.legoCaption)
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(Color.cardBackground)
                    .foregroundColor(.lightText)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondaryText, lineWidth: 1))
            }
            .padding(.trailing, 16).padding(.bottom, 8)
        }
        .padding(.bottom, -32)
    }

    // MARK: - User Info

    private var userInfoSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("@\(username)")
                .font(.legoScreenTitle).foregroundColor(.lightText)
            if !displayName.isEmpty {
                Text(displayName)
                    .font(.legoCardTitle).foregroundColor(.legoYellow)
            }
            Text(BadWordFilter.filter(bio))
                .font(.legoBody).foregroundColor(.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.top, 48)
        .padding(.bottom, 16)
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                statCell(value: "\(myPosts.count)", label: "Posts")
                Divider().frame(height: 40)
                statCell(value: "1.2k",  label: "Followers")
                Divider().frame(height: 40)
                statCell(value: "348",   label: "Following")
            }
            .padding(.vertical, 10)

            Divider().background(Color.secondaryText.opacity(0.3))

            HStack(spacing: 0) {
                statCell(value: "$12.40",          label: "Earnings")
                Divider().frame(height: 40)
                statCell(value: "\(setsCompleted)", label: "Completed")
            }
            .padding(.vertical, 10)
        }
        .background(Color.cardBackground)
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }

    // MARK: - Post Grid (Feature 4: every tile is tappable)

    @ViewBuilder
    private var postGrid: some View {
        if myPosts.isEmpty {
            emptyPostsState
        } else {
            LazyVGrid(columns: gridColumns, spacing: 2) {
                ForEach(myPosts) { post in
                    Button { selectedPost = post } label: {
                        gridTile(for: post)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Empty Posts

    private var emptyPostsState: some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.circle")
                .font(.system(size: 56)).foregroundColor(.secondaryText)
            Text("No posts yet")
                .font(.legoCardTitle).foregroundColor(.lightText)
            Text("Share your first LEGO build using the + button!")
                .font(.legoBody).foregroundColor(.secondaryText).multilineTextAlignment(.center)
        }
        .padding(.top, 40).padding(.horizontal)
    }

    // MARK: - Grid Tile

    @ViewBuilder
    private func gridTile(for post: LegoPost) -> some View {
        ZStack {
            Color.clear
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    Group {
                        if let image = postStore.postImages[post.id] {
                            Image(uiImage: image).resizable().scaledToFill()
                        } else if post.isCustomBuild {
                            // Custom build placeholder
                            ZStack {
                                Color.blue.opacity(0.22)
                                VStack(spacing: 4) {
                                    Image(systemName: "hammer.fill")
                                        .font(.system(size: 20)).foregroundColor(.legoYellow)
                                    Text(post.customBuildName.isEmpty ? "Custom" : post.customBuildName)
                                        .font(.legoCaption).foregroundColor(.legoYellow)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2).padding(.horizontal, 4)
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
                            .foregroundColor(.white).padding(4)
                    }
                    Spacer()
                }
            }

            // Custom build badge
            if post.isCustomBuild {
                VStack {
                    Spacer()
                    HStack {
                        Text("Custom")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Color.blue)
                            .cornerRadius(4)
                            .padding(4)
                        Spacer()
                    }
                }
            }
        }
    }

    private func setNumberPlaceholder(for post: LegoPost) -> some View {
        ZStack {
            Color.legoRed.opacity(0.25)
            Text("#\(post.legoSetNumber)")
                .font(.legoCaption).foregroundColor(.legoYellow)
        }
    }

    // MARK: - Stat Cell

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.legoCardTitle).foregroundColor(.lightText)
            Text(label).font(.legoCaption).foregroundColor(.secondaryText)
        }
        .frame(minWidth: 68).padding(.horizontal, 4)
    }
}

#Preview {
    ProfileView()
}

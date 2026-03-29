import SwiftUI
import PhotosUI

/// The Profile screen — your personal LEGO portfolio page.
/// Sprint 9: All stats come from real Firestore data via UserSession. No fake/hardcoded numbers.
struct ProfileView: View {

    @ObservedObject private var userSession = UserSession.shared
    @AppStorage("profile_hasBackground") private var hasBackground = false
    @AppStorage("profile_hasAvatar")     private var hasAvatar     = false
    @AppStorage("settings_kidSafeMode")  private var kidSafeMode:  Bool = true

    @State private var showingEditProfile  = false
    @State private var showingSettings     = false
    @State private var backgroundImage: UIImage?
    @State private var avatarImage: UIImage?

    // Background picker
    @State private var selectedBgItem: PhotosPickerItem?
    @State private var showingBgPicker    = false
    @State private var isLoadingBg        = false

    // Avatar picker
    @State private var selectedAvatarItem: PhotosPickerItem?
    @State private var showingAvatarPicker = false

    // Navigation to post detail
    @State private var selectedPost: LegoPost?

    // Sign out
    @State private var showingSignOutConfirm = false

    @ObservedObject private var postStore = PostStore.shared
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var currentUser: User? { userSession.currentUser }

    private var username: String { currentUser?.username ?? "" }
    private var displayName: String { currentUser?.displayName ?? "" }
    private var bio: String { currentUser?.bio ?? "" }

    private var myPosts: [LegoPost] {
        let uid = userSession.uid
        let uname = username
        return postStore.posts.filter { $0.userId == uid || (!uname.isEmpty && $0.username == uname) }
    }

    private var setsCompleted: Int {
        Set(myPosts.filter { !$0.isCustomBuild }.map { $0.legoSetNumber }).count
    }

    private var gridColumns: [GridItem] {
        let count = horizontalSizeClass == .regular ? 4 : 3
        return Array(repeating: GridItem(.flexible(), spacing: 2), count: count)
    }

    // MARK: - FileManager URLs

    private static let documentsDirectory: URL = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
    }()

    private var backgroundPhotoURL: URL {
        Self.documentsDirectory.appendingPathComponent("profile_background.jpg")
    }

    private var avatarPhotoURL: URL {
        Self.documentsDirectory.appendingPathComponent("profile_avatar.jpg")
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
                        signOutSection
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
            .navigationDestination(item: $selectedPost) { post in
                PostDetailView(post: post)
            }
        }
        .sheet(isPresented: $showingEditProfile) { EditProfileView() }
        .sheet(isPresented: $showingSettings)    { SettingsView() }
        .photosPicker(isPresented: $showingBgPicker,
                      selection: $selectedBgItem,
                      matching: .images)
        .onChange(of: selectedBgItem) { _, newItem in
            guard let newItem, !isLoadingBg else { return }
            isLoadingBg = true
            Task {
                defer { Task { @MainActor in isLoadingBg = false } }
                guard let data = try? await newItem.loadTransferable(type: Data.self),
                      let img  = UIImage(data: data) else { return }
                await MainActor.run {
                    backgroundImage = img
                    saveBackground(img)
                }
            }
        }
        .photosPicker(isPresented: $showingAvatarPicker,
                      selection: $selectedAvatarItem,
                      matching: .images)
        .onChange(of: selectedAvatarItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let img  = UIImage(data: data) {
                    avatarImage = img
                    saveAvatar(img)
                }
            }
        }
        .alert("Sign Out", isPresented: $showingSignOutConfirm) {
            Button("Sign Out", role: .destructive) { performSignOut() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out of BrickFeed?")
        }
        .onAppear {
            loadBackground()
            loadAvatar()
        }
    }

    // MARK: - Cover Photo

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

    private var avatarRow: some View {
        HStack(alignment: .bottom) {

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
            HStack(spacing: 8) {
                Text("@\(username)")
                    .font(.legoScreenTitle).foregroundColor(.lightText)
                // Kid Safe Mode badge
                if currentUser?.isKidAccount == true || kidSafeMode {
                    HStack(spacing: 3) {
                        Image(systemName: "shield.checkmark.fill")
                            .font(.system(size: 10))
                        Text("Kid Safe")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.successGreen)
                    .cornerRadius(6)
                }
            }
            if !displayName.isEmpty {
                Text(displayName)
                    .font(.legoCardTitle).foregroundColor(.legoYellow)
            }
            if !bio.isEmpty {
                Text(BadWordFilter.filter(bio))
                    .font(.legoBody).foregroundColor(.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.top, 48)
        .padding(.bottom, 16)
    }

    // MARK: - Stats Grid (real data only)

    private var statsGrid: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                statCell(value: "\(currentUser?.postCount ?? myPosts.count)", label: "Posts")
                Divider().frame(height: 40)
                statCell(value: "\(currentUser?.followerCount ?? 0)", label: "Followers")
                Divider().frame(height: 40)
                statCell(value: "\(currentUser?.followingCount ?? 0)", label: "Following")
            }
            .padding(.vertical, 10)

            Divider().background(Color.secondaryText.opacity(0.3))

            HStack(spacing: 0) {
                statCell(value: String(format: "$%.2f", currentUser?.totalEarnings ?? 0), label: "Earnings")
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

    // MARK: - Post Grid

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
            Text("Share your first Brick build using the + button!")
                .font(.legoBody).foregroundColor(.secondaryText).multilineTextAlignment(.center)
        }
        .padding(.top, 40).padding(.horizontal)
    }

    // MARK: - Sign Out Section

    private var signOutSection: some View {
        Button { showingSignOutConfirm = true } label: {
            HStack {
                Image(systemName: "arrow.right.square.fill")
                    .foregroundColor(.legoRed)
                Text("Sign Out")
                    .font(.legoBody).foregroundColor(.legoRed)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.legoCaption).foregroundColor(.secondaryText)
            }
            .padding(.horizontal).padding(.vertical, 14)
            .background(Color.cardBackground).cornerRadius(12)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.top, 24)
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

    // MARK: - Sign Out

    private func performSignOut() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
                   ?? FileManager.default.temporaryDirectory
        try? FileManager.default.removeItem(at: docs.appendingPathComponent("profile_avatar.jpg"))
        try? FileManager.default.removeItem(at: docs.appendingPathComponent("profile_background.jpg"))

        hasAvatar     = false
        hasBackground = false

        // Clear AppStorage profile keys
        UserDefaults.standard.removeObject(forKey: "profile_displayName")
        UserDefaults.standard.removeObject(forKey: "profile_username")
        UserDefaults.standard.removeObject(forKey: "profile_bio")
        UserDefaults.standard.removeObject(forKey: "settings_kidSafeMode")
        UserDefaults.standard.removeObject(forKey: "settings_notifications")
        UserDefaults.standard.removeObject(forKey: "dm_ageVerified")

        userSession.clear()
        PostStore.shared.followingUsernames.removeAll()

        do {
            try AuthService.shared.signOut()
        } catch {
            print("[ProfileView] Firebase signOut error: \(error.localizedDescription)")
        }
    }
}

#Preview {
    ProfileView()
}

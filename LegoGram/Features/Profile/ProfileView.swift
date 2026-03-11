import SwiftUI
import PhotosUI

/// The Profile screen — your personal LEGO portfolio page!
/// Sprint 5 upgrades:
/// • Background photo (tap cover to set from photo library, persists between launches)
/// • Profile grid shows real LEGO set images from Brickset CDN
/// • Keyboard dismissal
struct ProfileView: View {

    @AppStorage("profile_displayName") private var displayName = "blockmasterjames"
    @AppStorage("profile_bio")         private var bio         = "Building one brick at a time 🧱 | LEGO fan since 2010"
    @AppStorage("profile_username")    private var username    = "blockmasterjames"
    @AppStorage("profile_hasBackground") private var hasBackground = false

    @State private var showingEditProfile = false
    @State private var showingSettings    = false
    @State private var backgroundImage: UIImage?
    @State private var selectedBgItem: PhotosPickerItem?
    @State private var showingBgPicker = false

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

    // MARK: - Background Photo Persistence

    private var backgroundPhotoURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("profile_background.jpg")
    }

    private func saveBackgroundPhoto(_ image: UIImage) {
        if let data = image.jpegData(compressionQuality: 0.75) {
            try? data.write(to: backgroundPhotoURL)
            hasBackground = true
        }
    }

    private func loadBackgroundPhoto() {
        guard hasBackground else { return }
        if let data = try? Data(contentsOf: backgroundPhotoURL),
           let img = UIImage(data: data) {
            backgroundImage = img
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {

                        // MARK: Cover Photo (tappable)
                        coverPhoto

                        // MARK: Avatar + Edit Button
                        avatarRow

                        // MARK: Username & Bio
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

                        // MARK: Stats
                        statsGrid

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
                    Button { showingSettings = true } label: {
                        Image(systemName: "gearshape.fill").foregroundColor(.legoYellow)
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditProfile) { EditProfileView() }
        .sheet(isPresented: $showingSettings) { SettingsView() }
        .photosPicker(isPresented: $showingBgPicker, selection: $selectedBgItem, matching: .images)
        .onChange(of: selectedBgItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    backgroundImage = img
                    saveBackgroundPhoto(img)
                }
            }
        }
        .onAppear { loadBackgroundPhoto() }
    }

    // MARK: - Cover Photo (Feature 9: tappable background)

    private var coverPhoto: some View {
        ZStack(alignment: .bottomLeading) {
            // Background: custom photo or gradient
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
                        .padding(.bottom, 16)
                        .padding(.leading, 12),
                        alignment: .bottomLeading
                    )
            }

            // Camera hint overlay (bottom-right)
            VStack {
                HStack {
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(Color.black.opacity(0.45))
                            .frame(width: 36, height: 36)
                        Image(systemName: "camera.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
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
            Circle()
                .fill(Color.cardBackground)
                .frame(width: 90, height: 90)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 44)).foregroundColor(.secondaryText)
                )
                .overlay(Circle().stroke(Color.darkBackground, lineWidth: 4))
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

    // MARK: - Stats Grid

    private var statsGrid: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                statCell(value: "\(myPosts.count)", label: "Posts")
                Divider().frame(height: 40)
                statCell(value: "1.2k", label: "Followers")
                Divider().frame(height: 40)
                statCell(value: "348", label: "Following")
            }
            .padding(.vertical, 10)

            Divider().background(Color.secondaryText.opacity(0.3))

            HStack(spacing: 0) {
                statCell(value: "$12.40", label: "Earnings")
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

    // MARK: - Grid Tile (Sprint 5: real LEGO set images)

    @ViewBuilder
    private func gridTile(for post: LegoPost) -> some View {
        ZStack {
            Color.clear
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    Group {
                        if let image = postStore.postImages[post.id] {
                            // User's own uploaded photo
                            Image(uiImage: image)
                                .resizable().scaledToFill()
                        } else if let imageURL = LegoSetDatabase.set(for: post.legoSetNumber)?.setImageURL {
                            // Official LEGO set image from Brickset CDN
                            AsyncImage(url: imageURL) { phase in
                                switch phase {
                                case .success(let img):
                                    img.resizable().scaledToFill()
                                case .empty:
                                    ZStack {
                                        Color.legoRed.opacity(0.2)
                                        ProgressView().tint(.legoYellow).scaleEffect(0.7)
                                    }
                                case .failure:
                                    setNumberPlaceholder(for: post)
                                @unknown default:
                                    setNumberPlaceholder(for: post)
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
        .frame(minWidth: 68)
        .padding(.horizontal, 4)
    }
}

#Preview {
    ProfileView()
}

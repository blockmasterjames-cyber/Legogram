import SwiftUI
import PhotosUI
import AVKit

/// The New Post screen — where you share your amazing LEGO build with everyone!
/// Sprint 3 adds: video upload (≤60 sec), LEGO set auto-complete dropdown,
/// bad word filter on descriptions, and smarter set name lookup from the database.
struct NewPostView: View {

    // MARK: - State

    @State private var selectedImage: UIImage?
    @State private var selectedVideoURL: URL?
    @State private var legoSetNumber = ""
    @State private var description   = ""

    @State private var showingCamera        = false
    @State private var showingLibrary       = false
    @State private var showingVideoPicker   = false
    @State private var showingCameraAlert   = false
    @State private var showingVideoTooLong  = false
    @State private var isPosting            = false
    @State private var videoTooLong         = false

    // Auto-complete
    @State private var autocompleteSuggestions: [LegoSet] = []
    @State private var selectedSet: LegoSet?

    // MARK: - Computed

    private var canPost: Bool {
        (selectedImage != nil || selectedVideoURL != nil) &&
        !legoSetNumber.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var isVideoSelected: Bool { selectedVideoURL != nil }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        // MARK: Screen Title
                        Text("New Post")
                            .font(.legoScreenTitle)
                            .foregroundColor(.lightText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.top, 8)

                        // MARK: Media Area
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.cardBackground)
                                .frame(height: 260)

                            if let image = selectedImage {
                                photoPreview(image: image)
                            } else if let videoURL = selectedVideoURL {
                                videoPreview(url: videoURL)
                            } else {
                                mediaPlaceholder
                            }
                        }
                        .frame(height: 260)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)

                        // MARK: LEGO Set Number + Auto-Complete
                        VStack(alignment: .leading, spacing: 8) {
                            Label("LEGO Set Number", systemImage: "number.circle.fill")
                                .font(.legoCardTitle)
                                .foregroundColor(.legoYellow)

                            TextField("e.g. 75192", text: $legoSetNumber)
                                .keyboardType(.numberPad)
                                .foregroundColor(.lightText)
                                .font(.legoBody)
                                .padding(14)
                                .background(Color.cardBackground)
                                .cornerRadius(12)
                                .onChange(of: legoSetNumber) { _, newValue in
                                    selectedSet = nil
                                    autocompleteSuggestions = LegoSetDatabase.autocomplete(setNumber: newValue)
                                }

                            // Auto-complete dropdown
                            if !autocompleteSuggestions.isEmpty && selectedSet == nil {
                                VStack(spacing: 0) {
                                    ForEach(autocompleteSuggestions) { set in
                                        Button {
                                            legoSetNumber = set.setNumber
                                            selectedSet = set
                                            autocompleteSuggestions = []
                                        } label: {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(set.name)
                                                        .font(.legoBody)
                                                        .foregroundColor(.lightText)
                                                    Text("#\(set.setNumber)  ·  \(set.theme)")
                                                        .font(.legoCaption)
                                                        .foregroundColor(.secondaryText)
                                                }
                                                Spacer()
                                                Image(systemName: "checkmark.circle")
                                                    .foregroundColor(.legoYellow)
                                            }
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 10)
                                            .background(Color.cardBackground)
                                        }
                                        .buttonStyle(.plain)
                                        Divider().background(Color.secondaryText.opacity(0.3))
                                    }
                                }
                                .background(Color.cardBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.legoYellow.opacity(0.5), lineWidth: 1)
                                )
                            }

                            // Selected set confirmation
                            if let set = selectedSet {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.successGreen)
                                    Text("\(set.name) — \(set.theme) · \(set.pieceCount) pieces")
                                        .font(.legoCaption)
                                        .foregroundColor(.successGreen)
                                }
                                .padding(.top, 4)
                            }
                        }
                        .padding(.horizontal)

                        // MARK: Description
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Description", systemImage: "text.alignleft")
                                .font(.legoCardTitle)
                                .foregroundColor(.legoYellow)

                            TextField("Tell us about your build...", text: $description, axis: .vertical)
                                .lineLimit(4, reservesSpace: true)
                                .foregroundColor(.lightText)
                                .font(.legoBody)
                                .padding(14)
                                .background(Color.cardBackground)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)

                        // MARK: Post Button
                        Button { submitPost() } label: {
                            HStack(spacing: 10) {
                                if isPosting {
                                    ProgressView().tint(.white)
                                    Text("Posting…").font(.legoCardTitle)
                                } else {
                                    Image(systemName: "paperplane.fill")
                                    Text("Post Your Build!").font(.legoCardTitle)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(canPost ? Color.legoRed : Color.legoRed.opacity(0.4))
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .animation(.easeInOut(duration: 0.15), value: canPost)
                        }
                        .disabled(!canPost || isPosting)
                        .padding(.horizontal)

                        Color.clear.frame(height: 80)
                    }
                    .padding(.top)
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraPicker(selectedImage: $selectedImage).ignoresSafeArea()
        }
        .sheet(isPresented: $showingLibrary) {
            PhotoLibraryPicker(selectedImage: $selectedImage).ignoresSafeArea()
        }
        .sheet(isPresented: $showingVideoPicker) {
            VideoPicker(selectedVideoURL: $selectedVideoURL, videoTooLong: $videoTooLong)
                .ignoresSafeArea()
        }
        .alert("Camera Not Available", isPresented: $showingCameraAlert) {
            Button("Choose from Library") { showingLibrary = true }
            Button("OK", role: .cancel) {}
        } message: {
            Text("This device doesn't have a camera. Pick a photo from your library instead.")
        }
        .alert("Video Too Long", isPresented: $videoTooLong) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("For kid safety, videos must be 60 seconds or less. Please pick a shorter video!")
        }
    }

    // MARK: - Sub-Views

    private func photoPreview(image: UIImage) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 260)
                .clipped()

            Button {
                withAnimation { selectedImage = nil }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white, Color.black.opacity(0.5))
                    .padding(10)
            }
        }
    }

    private func videoPreview(url: URL) -> some View {
        ZStack(alignment: .topTrailing) {
            VideoPlayer(player: AVPlayer(url: url))
                .frame(height: 260)
                .disabled(true)

            Button {
                withAnimation { selectedVideoURL = nil }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white, Color.black.opacity(0.5))
                    .padding(10)
            }
        }
    }

    /// Empty media area with Camera, Library, and Video buttons.
    private var mediaPlaceholder: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.secondaryText)

            Text("Add a photo or video of your build")
                .font(.legoBody)
                .foregroundColor(.secondaryText)

            HStack(spacing: 12) {

                // Camera Button
                Button {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        showingCamera = true
                    } else {
                        showingCameraAlert = true
                    }
                } label: {
                    Label("Camera", systemImage: "camera.fill")
                        .font(.legoCaption)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.legoRed)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)

                // Photo Library Button
                Button {
                    showingLibrary = true
                } label: {
                    Label("Library", systemImage: "photo.on.rectangle")
                        .font(.legoCaption)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.cardBackground)
                        .foregroundColor(.lightText)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.secondaryText, lineWidth: 1))
                }
                .buttonStyle(.plain)

                // Video Button (Sprint 3 — max 60 seconds)
                Button {
                    showingVideoPicker = true
                } label: {
                    Label("Video", systemImage: "video.fill")
                        .font(.legoCaption)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.legoYellow.opacity(0.2))
                        .foregroundColor(.legoYellow)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.legoYellow, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            Text("Videos must be under 60 seconds")
                .font(.legoCaption)
                .foregroundColor(.secondaryText)
        }
    }

    // MARK: - Actions

    private func submitPost() {
        guard selectedImage != nil || selectedVideoURL != nil else { return }
        isPosting = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            let setNum = legoSetNumber.trimmingCharacters(in: .whitespaces)
            let setName = selectedSet?.name ?? LegoSetDatabase.set(for: setNum)?.name ?? "Set #\(setNum)"
            let storeURL = selectedSet?.legoStoreURL ??
                           LegoSetDatabase.set(for: setNum)?.legoStoreURL ??
                           "https://www.lego.com/en-us/search?q=\(setNum)"
            let retailPrice = selectedSet?.retailPrice ?? LegoSetDatabase.set(for: setNum)?.retailPrice ?? 0.0
            let earn = (retailPrice * 0.004).rounded(toPlaces: 2)

            let filteredDesc = BadWordFilter.filter(description.trimmingCharacters(in: .whitespaces))

            let newPost = LegoPost(
                id: UUID().uuidString,
                userId: "current-user",
                username: "blockmasterjames",
                imageURL: "",
                videoURL: "",
                legoSetNumber: setNum,
                legoSetName: setName,
                description: filteredDesc,
                likeCount: 0,
                commentCount: 0,
                buyLink: storeURL,
                affiliateLink: "",
                estimatedEarnings: earn,
                postedDate: Date(),
                tags: []
            )

            PostStore.shared.addPost(newPost, image: selectedImage, videoURL: selectedVideoURL)

            selectedImage    = nil
            selectedVideoURL = nil
            legoSetNumber    = ""
            description      = ""
            selectedSet      = nil
            isPosting        = false

            AppState.shared.selectedTab = .home
        }
    }
}

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

#Preview {
    NewPostView()
}

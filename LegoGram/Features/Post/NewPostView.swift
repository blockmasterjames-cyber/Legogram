import SwiftUI
import PhotosUI
import AVKit

/// The New Post screen — share your amazing LEGO build with everyone!
/// Supports up to 10 photos in a carousel, custom build toggle, and set search.
struct NewPostView: View {

    // MARK: - State

    @State private var selectedImages: [UIImage] = []   // Up to 10 photos
    @State private var selectedVideoURL: URL?
    @State private var description   = ""
    @State private var isPosting     = false
    @State private var carouselPage  = 0

    // Pickers
    @State private var showingCamera         = false
    @State private var showingLibrary        = false
    @State private var showingMultiPicker    = false
    @State private var showingVideoPicker    = false
    @State private var showingCameraAlert    = false
    @State private var videoTooLong          = false
    @State private var multiPickerItems: [PhotosPickerItem] = []

    // Feature 7: searchable set field
    @State private var setSearchText           = ""
    @State private var setSearchResults: [LegoSet] = []
    @State private var selectedSet: LegoSet?
    @State private var showingSetDropdown      = false

    // Feature 8: custom build
    @State private var isCustomBuild     = false
    @State private var customBuildName   = ""

    // Feature 9: focus states
    @FocusState private var descriptionFocused: Bool
    @FocusState private var setSearchFocused:   Bool
    @FocusState private var customNameFocused:  Bool

    // MARK: - Computed

    private var hasMedia: Bool { !selectedImages.isEmpty || selectedVideoURL != nil }

    private var canPost: Bool {
        guard hasMedia else { return false }
        if isCustomBuild {
            return !customBuildName.trimmingCharacters(in: .whitespaces).isEmpty
        } else {
            return selectedSet != nil ||
                   !setSearchText.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                ScrollViewReader { scrollProxy in
                    ScrollView {
                        VStack(spacing: 24) {

                            Text("New Post")
                                .font(.legoScreenTitle)
                                .foregroundColor(.lightText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                                .padding(.top, 8)

                            // Media Area
                            mediaArea

                            // Set / Custom Build
                            VStack(alignment: .leading, spacing: 12) {
                                customBuildToggle
                                if isCustomBuild {
                                    customBuildNameField
                                } else {
                                    setSearchField
                                }
                            }
                            .padding(.horizontal)

                            // Description
                            descriptionField
                                .id("description-field")

                            // Post Button
                            postButton
                                .id("post-button")

                            Color.clear.frame(height: 80)
                        }
                        .padding(.top)
                    }
                    .onChange(of: descriptionFocused) { _, focused in
                        if focused {
                            withAnimation {
                                scrollProxy.scrollTo("description-field", anchor: .center)
                            }
                        }
                    }
                    .onTapGesture {
                        hideKeyboard()
                        showingSetDropdown = false
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        descriptionFocused = false
                        setSearchFocused   = false
                        customNameFocused  = false
                        showingSetDropdown = false
                    }
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.legoRed)
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraPicker(selectedImage: Binding(
                get: { selectedImages.first },
                set: { if let img = $0 { addImage(img) } }
            )).ignoresSafeArea()
        }
        .sheet(isPresented: $showingLibrary) {
            PhotoLibraryPicker(selectedImage: Binding(
                get: { selectedImages.first },
                set: { if let img = $0 { addImage(img) } }
            )).ignoresSafeArea()
        }
        .sheet(isPresented: $showingVideoPicker) {
            VideoPicker(selectedVideoURL: $selectedVideoURL, videoTooLong: $videoTooLong)
                .ignoresSafeArea()
        }
        .photosPicker(
            isPresented: $showingMultiPicker,
            selection: $multiPickerItems,
            maxSelectionCount: 10,
            matching: .images
        )
        .onChange(of: multiPickerItems) { _, newItems in
            loadMultiPickerImages(newItems)
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

    // MARK: - Media Area

    private var mediaArea: some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cardBackground)
                    .frame(height: 260)

                if !selectedImages.isEmpty {
                    photoCarouselPreview
                } else if let videoURL = selectedVideoURL {
                    videoPreview(url: videoURL)
                } else {
                    mediaPlaceholder
                }
            }
            .frame(height: 260)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)

            // Photo count indicator + Add More button
            if !selectedImages.isEmpty && selectedVideoURL == nil {
                HStack(spacing: 12) {
                    Text("\(selectedImages.count)/10 photo\(selectedImages.count == 1 ? "" : "s")")
                        .font(.legoCaption).foregroundColor(.secondaryText)

                    if selectedImages.count < 10 {
                        Button {
                            showingMultiPicker = true
                        } label: {
                            Label("Add More", systemImage: "plus.circle.fill")
                                .font(.legoCaption)
                                .foregroundColor(.legoYellow)
                        }
                    }

                    Spacer()

                    Button {
                        withAnimation { selectedImages.removeAll() }
                    } label: {
                        Label("Clear All", systemImage: "trash")
                            .font(.legoCaption).foregroundColor(.legoRed)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
    }

    // MARK: - Photo Carousel Preview

    private var photoCarouselPreview: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $carouselPage) {
                ForEach(Array(selectedImages.enumerated()), id: \.offset) { idx, image in
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: image)
                            .resizable().scaledToFill()
                            .frame(height: 260).clipped()

                        Button {
                            withAnimation { selectedImages.remove(at: idx as Int) }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(.white, Color.black.opacity(0.5))
                                .padding(8)
                        }
                    }
                    .tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Dots indicator
            if selectedImages.count > 1 {
                HStack(spacing: 6) {
                    ForEach(0..<selectedImages.count, id: \.self) { idx in
                        Circle()
                            .fill(idx == carouselPage ? Color.legoYellow : Color.white.opacity(0.5))
                            .frame(width: idx == carouselPage ? 8 : 6,
                                   height: idx == carouselPage ? 8 : 6)
                            .animation(.spring(response: 0.3), value: carouselPage)
                    }
                }
                .padding(.bottom, 10)
            }
        }
    }

    // MARK: - Custom Build Toggle

    private var customBuildToggle: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isCustomBuild.toggle()
                if isCustomBuild {
                    setSearchText      = ""
                    setSearchResults   = []
                    selectedSet        = nil
                    showingSetDropdown = false
                } else {
                    customBuildName = ""
                }
            }
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isCustomBuild ? Color.blue : Color.cardBackground)
                        .frame(width: 26, height: 26)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(isCustomBuild ? Color.blue : Color.secondaryText, lineWidth: 1.5)
                        )
                    if isCustomBuild {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Custom Build")
                        .font(.legoCardTitle)
                        .foregroundColor(isCustomBuild ? .white : .lightText)
                    Text("Not based on an official set")
                        .font(.legoCaption)
                        .foregroundColor(.secondaryText)
                }

                Spacer()

                if isCustomBuild {
                    Text("Custom Build")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(Color.blue)
                        .cornerRadius(5)
                }
            }
            .padding(12)
            .background(isCustomBuild ? Color.blue.opacity(0.15) : Color.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isCustomBuild ? Color.blue.opacity(0.6) : Color.secondaryText.opacity(0.3),
                            lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Custom Build Name Field

    private var customBuildNameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Custom Build Name", systemImage: "hammer.fill")
                .font(.legoCardTitle)
                .foregroundColor(.legoYellow)

            TextField("e.g. My Space Castle, Rainbow Dragon…", text: $customBuildName)
                .foregroundColor(.lightText)
                .font(.legoBody)
                .padding(14)
                .background(Color.cardBackground)
                .cornerRadius(12)
                .focused($customNameFocused)
                .submitLabel(.done)
                .onSubmit { customNameFocused = false }
        }
    }

    // MARK: - Set Search Field

    private var setSearchField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Brick Set", systemImage: "magnifyingglass.circle.fill")
                .font(.legoCardTitle)
                .foregroundColor(.legoYellow)

            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondaryText)
                    .font(.system(size: 15))

                TextField("Set name or number (e.g. Falcon or 75192)", text: $setSearchText)
                    .foregroundColor(.lightText)
                    .font(.legoBody)
                    .autocorrectionDisabled()
                    .focused($setSearchFocused)
                    .submitLabel(.search)
                    .onChange(of: setSearchText) { _, newValue in
                        selectedSet = nil
                        if newValue.trimmingCharacters(in: .whitespaces).isEmpty {
                            setSearchResults   = []
                            showingSetDropdown = false
                        } else {
                            setSearchResults   = LegoSetDatabase.search(newValue)
                            showingSetDropdown = !setSearchResults.isEmpty
                        }
                    }
                    .onSubmit {
                        setSearchFocused   = false
                        showingSetDropdown = false
                    }

                if !setSearchText.isEmpty {
                    Button {
                        setSearchText      = ""
                        setSearchResults   = []
                        selectedSet        = nil
                        showingSetDropdown = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondaryText)
                    }
                }
            }
            .padding(12)
            .background(Color.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(setSearchFocused ? Color.legoYellow.opacity(0.6) : Color.clear, lineWidth: 1.5)
            )

            if showingSetDropdown && selectedSet == nil {
                VStack(spacing: 0) {
                    ForEach(setSearchResults.prefix(6)) { set in
                        Button {
                            selectedSet        = set
                            setSearchText      = set.name
                            setSearchResults   = []
                            showingSetDropdown = false
                            setSearchFocused   = false
                            hideKeyboard()
                        } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(set.name)
                                        .font(.legoBody)
                                        .foregroundColor(.lightText)
                                        .lineLimit(1)
                                    Text("#\(set.setNumber)  ·  \(set.theme)")
                                        .font(.legoCaption)
                                        .foregroundColor(.secondaryText)
                                }
                                Spacer()
                                Image(systemName: "checkmark.circle")
                                    .foregroundColor(.legoYellow)
                                    .font(.system(size: 16))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.cardBackground)
                        }
                        .buttonStyle(.plain)

                        if set.setNumber != setSearchResults.prefix(6).last?.setNumber {
                            Divider().background(Color.secondaryText.opacity(0.3))
                        }
                    }
                }
                .background(Color.cardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.legoYellow.opacity(0.4), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
            }

            if let set = selectedSet {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.successGreen)
                    Text("\(set.name)  ·  \(set.theme)  ·  \(set.pieceCount) pcs")
                        .font(.legoCaption)
                        .foregroundColor(.successGreen)
                }
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Description Field

    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Description", systemImage: "text.alignleft")
                .font(.legoCardTitle)
                .foregroundColor(.legoYellow)

            TextField("Tell us about your build…", text: $description, axis: .vertical)
                .lineLimit(4, reservesSpace: true)
                .foregroundColor(.lightText)
                .font(.legoBody)
                .padding(14)
                .background(Color.cardBackground)
                .cornerRadius(12)
                .focused($descriptionFocused)
        }
        .padding(.horizontal)
    }

    // MARK: - Post Button

    private var postButton: some View {
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
    }

    // MARK: - Media Sub-Views

    private func videoPreview(url: URL) -> some View {
        ZStack(alignment: .topTrailing) {
            VideoPlayer(player: AVPlayer(url: url))
                .frame(height: 260).disabled(true)

            Button { withAnimation { selectedVideoURL = nil } } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white, Color.black.opacity(0.5))
                    .padding(10)
            }
        }
    }

    private var mediaPlaceholder: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 48)).foregroundColor(.secondaryText)

            Text("Add up to 10 photos or a video of your build")
                .font(.legoBody).foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                Button {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        showingCamera = true
                    } else {
                        showingCameraAlert = true
                    }
                } label: {
                    Label("Camera", systemImage: "camera.fill")
                        .font(.legoCaption)
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .background(Color.legoRed).foregroundColor(.white)
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)

                Button { showingMultiPicker = true } label: {
                    Label("Photos", systemImage: "photo.on.rectangle.angled")
                        .font(.legoCaption)
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .background(Color.cardBackground).foregroundColor(.lightText)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.secondaryText, lineWidth: 1))
                }
                .buttonStyle(.plain)

                Button { showingVideoPicker = true } label: {
                    Label("Video", systemImage: "video.fill")
                        .font(.legoCaption)
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .background(Color.legoYellow.opacity(0.2))
                        .foregroundColor(.legoYellow)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.legoYellow, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            Text("Videos must be under 60 seconds · Up to 10 photos")
                .font(.legoCaption).foregroundColor(.secondaryText)
        }
    }

    // MARK: - Helpers

    private func addImage(_ image: UIImage) {
        if selectedImages.count < 10 {
            selectedImages.append(image)
        }
    }

    private func loadMultiPickerImages(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        Task {
            var newImages: [UIImage] = []
            for item in items.prefix(10) {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    newImages.append(img)
                }
            }
            await MainActor.run {
                selectedImages = newImages
                multiPickerItems = []
            }
        }
    }

    // MARK: - Submit Post

    private func submitPost() {
        guard hasMedia else { return }
        isPosting = true

        Task {
            let filteredDesc    = BadWordFilter.filter(description.trimmingCharacters(in: .whitespaces))
            let currentUid      = UserSession.shared.uid
            let currentUsername = UserSession.shared.username
            let postId          = UUID().uuidString

            var imageURLStrings: [String] = []
            var primaryImageURL = ""

            // Upload all selected photos
            for (idx, image) in selectedImages.enumerated() {
                if let imageData = image.jpegData(compressionQuality: 0.80) {
                    do {
                        let path = "posts/\(postId)/image_\(idx).jpg"
                        let url = try await FirebaseService.shared.uploadImage(
                            imageData: imageData, path: path)
                        imageURLStrings.append(url)
                        if idx == 0 { primaryImageURL = url }
                    } catch {
                        print("[NewPostView] Image \(idx) upload error: \(error)")
                    }
                }
            }

            var videoURLString = ""
            // (Video upload placeholder — video URLs handled similarly)

            let newPost: LegoPost
            if isCustomBuild {
                let name = customBuildName.trimmingCharacters(in: .whitespaces)
                newPost = LegoPost(
                    id:              postId,
                    userId:          currentUid,
                    username:        currentUsername,
                    imageURL:        primaryImageURL,
                    videoURL:        videoURLString,
                    legoSetNumber:   "",
                    legoSetName:     name,
                    description:     filteredDesc,
                    likeCount:       0,
                    commentCount:    0,
                    buyLink:         "",
                    postedDate:      Date(),
                    tags:            [],
                    isCustomBuild:   true,
                    customBuildName: name,
                    imageURLs:       imageURLStrings
                )
            } else {
                let setNum   = selectedSet?.setNumber ?? setSearchText.trimmingCharacters(in: .whitespaces)
                let setName  = selectedSet?.name ?? LegoSetDatabase.set(for: setNum)?.name ?? "Set #\(setNum)"
                let storeURL = selectedSet?.legoStoreURL
                    ?? LegoSetDatabase.set(for: setNum)?.legoStoreURL
                    ?? "https://www.lego.com/en-us/search?q=\(setNum)"

                newPost = LegoPost(
                    id:            postId,
                    userId:        currentUid,
                    username:      currentUsername,
                    imageURL:      primaryImageURL,
                    videoURL:      videoURLString,
                    legoSetNumber: setNum,
                    legoSetName:   setName,
                    description:   filteredDesc,
                    likeCount:     0,
                    commentCount:  0,
                    buyLink:       storeURL,
                    postedDate:    Date(),
                    tags:          [],
                    imageURLs:     imageURLStrings
                )
            }

            PostStore.shared.addPost(newPost,
                                     image: selectedImages.first,
                                     videoURL: selectedVideoURL)

            do {
                try await FirebaseService.shared.publishPost(newPost)
            } catch {
                print("[NewPostView] Firestore save error: \(error)")
            }

            await MainActor.run {
                selectedImages     = []
                selectedVideoURL   = nil
                setSearchText      = ""
                setSearchResults   = []
                selectedSet        = nil
                showingSetDropdown = false
                description        = ""
                isCustomBuild      = false
                customBuildName    = ""
                isPosting          = false
                multiPickerItems   = []
                AppState.shared.selectedTab = .home
            }
        }
    }
}

#Preview {
    NewPostView()
}

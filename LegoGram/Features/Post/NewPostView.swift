import SwiftUI
import PhotosUI

/// The New Post screen — where you share your amazing LEGO build with everyone!
/// Pick a photo with the camera or photo library, enter the set number and a description,
/// then tap Post. The post appears at the top of the Home feed right away.
struct NewPostView: View {

    // MARK: - State

    @State private var selectedImage: UIImage?
    @State private var legoSetNumber = ""
    @State private var description   = ""

    @State private var showingCamera      = false
    @State private var showingLibrary     = false
    @State private var showingCameraAlert = false   // shown on simulator (no camera)
    @State private var isPosting          = false
    @State private var showingSuccess     = false

    // MARK: - Computed

    /// The Post button is only enabled when the user has chosen a photo AND typed a set number.
    private var canPost: Bool {
        selectedImage != nil && !legoSetNumber.trimmingCharacters(in: .whitespaces).isEmpty
    }

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

                        // MARK: Photo Area
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.cardBackground)
                                .frame(height: 260)

                            if let image = selectedImage {
                                photoPreview(image: image)
                            } else {
                                photoPlaceholder
                            }
                        }
                        .frame(height: 260)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)

                        // MARK: LEGO Set Number
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
                        Button {
                            submitPost()
                        } label: {
                            HStack(spacing: 10) {
                                if isPosting {
                                    ProgressView()
                                        .tint(.white)
                                    Text("Posting…")
                                        .font(.legoCardTitle)
                                } else {
                                    Image(systemName: "paperplane.fill")
                                    Text("Post Your Build!")
                                        .font(.legoCardTitle)
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

                        // Bottom padding so the last field isn't hidden behind the tab bar
                        Color.clear.frame(height: 80)
                    }
                    .padding(.top)
                }
            }
        }
        // Camera sheet
        .sheet(isPresented: $showingCamera) {
            CameraPicker(selectedImage: $selectedImage)
                .ignoresSafeArea()
        }
        // Photo library sheet
        .sheet(isPresented: $showingLibrary) {
            PhotoLibraryPicker(selectedImage: $selectedImage)
                .ignoresSafeArea()
        }
        // Friendly alert for simulator / no-camera devices
        .alert("Camera Not Available", isPresented: $showingCameraAlert) {
            Button("Choose from Library") { showingLibrary = true }
            Button("OK", role: .cancel) {}
        } message: {
            Text("This device doesn't have a camera, or camera access was denied. You can pick a photo from your library instead, or allow camera access in Settings.")
        }
    }

    // MARK: - Sub-Views

    /// Live photo preview with an X button to remove the photo.
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

    /// Empty photo area with camera and library buttons.
    private var photoPlaceholder: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.secondaryText)

            Text("Add a photo of your build")
                .font(.legoBody)
                .foregroundColor(.secondaryText)

            HStack(spacing: 16) {

                // Camera Button
                Button {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        showingCamera = true
                    } else {
                        showingCameraAlert = true
                    }
                } label: {
                    Label("Camera", systemImage: "camera.fill")
                        .font(.legoBody)
                        .padding(.horizontal, 20)
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
                        .font(.legoBody)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.cardBackground)
                        .foregroundColor(.lightText)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.secondaryText, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Actions

    private func submitPost() {
        guard let image = selectedImage else { return }
        isPosting = true

        // Small artificial delay so the spinner is visible and feels intentional.
        // In Sprint 3 this becomes the real Firebase upload await.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            let setNum = legoSetNumber.trimmingCharacters(in: .whitespaces)
            let newPost = LegoPost(
                id: UUID().uuidString,
                userId: "current-user",
                username: "blockmasterjames",
                imageURL: "",
                legoSetNumber: setNum,
                legoSetName: "Set #\(setNum)",
                description: description.trimmingCharacters(in: .whitespaces),
                likeCount: 0,
                commentCount: 0,
                buyLink: "https://www.lego.com/en-us/search?q=\(setNum)",
                affiliateLink: "",
                estimatedEarnings: 0.0,
                postedDate: Date(),
                tags: []
            )

            PostStore.shared.addPost(newPost, image: image)

            // Reset the form
            selectedImage  = nil
            legoSetNumber  = ""
            description    = ""
            isPosting      = false

            // Navigate to the Home tab to see the new post
            AppState.shared.selectedTab = .home
        }
    }
}

#Preview {
    NewPostView()
}

import SwiftUI
import PhotosUI

/// The Edit Profile screen — update display name, bio, and profile avatar.
/// Avatar uploads to Firebase Storage (users/{uid}/avatar.jpg) for persistent cross-device display.
struct EditProfileView: View {

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var userSession = UserSession.shared

    @State private var draftDisplayName = ""
    @State private var draftBio         = ""

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingLibrary    = false
    @State private var isUploadingAvatar = false
    @State private var previewAvatar: UIImage?

    @State private var isSaving = false
    @State private var saveError: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        avatarSection.padding(.top, 8)

                        formField(label: "Display Name", icon: "person.fill",
                                  placeholder: "Your name", text: $draftDisplayName)

                        VStack(alignment: .leading, spacing: 8) {
                            Label("Bio", systemImage: "text.alignleft")
                                .font(.legoCardTitle).foregroundColor(.legoYellow)

                            TextField("Tell the world about your Brick hobby...",
                                      text: $draftBio, axis: .vertical)
                                .lineLimit(3, reservesSpace: true)
                                .foregroundColor(.lightText).font(.legoBody)
                                .padding(14).background(Color.cardBackground).cornerRadius(12)
                        }
                        .padding(.horizontal)

                        if let error = saveError {
                            Text(error)
                                .font(.legoCaption).foregroundColor(.red)
                                .multilineTextAlignment(.center).padding(.horizontal)
                        }

                        Button { saveChanges() } label: {
                            HStack(spacing: 10) {
                                if isSaving {
                                    ProgressView().tint(.white)
                                    Text("Saving...").font(.legoCardTitle)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Save Changes").font(.legoCardTitle)
                                }
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(Color.legoRed).foregroundColor(.white).cornerRadius(16)
                        }
                        .padding(.horizontal)

                        Color.clear.frame(height: 40)
                    }
                }
                .onTapGesture { hideKeyboard() }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.legoYellow)
                }
            }
        }
        .onAppear {
            draftDisplayName = userSession.displayName
            draftBio         = userSession.bio
            previewAvatar    = userSession.avatarImage
        }
        .photosPicker(isPresented: $showingLibrary, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            isUploadingAvatar = true
            Task {
                defer { Task { @MainActor in isUploadingAvatar = false } }
                guard let data = try? await newItem.loadTransferable(type: Data.self),
                      let img = UIImage(data: data) else { return }
                await MainActor.run { previewAvatar = img }
                do {
                    try await userSession.uploadAndSaveAvatar(img)
                } catch {
                    await MainActor.run { saveError = "Photo upload failed. Try again." }
                    print("[EditProfileView] Avatar upload error: \(error)")
                }
            }
        }
    }

    // MARK: - Avatar Section

    private var avatarSection: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if isUploadingAvatar {
                        ZStack {
                            Circle().fill(Color.cardBackground)
                            ProgressView().tint(.legoYellow)
                        }
                    } else if let avatar = previewAvatar ?? userSession.avatarImage {
                        Image(uiImage: avatar)
                            .resizable().scaledToFill()
                    } else {
                        ZStack {
                            Circle().fill(Color.legoRed)
                            Text(String(userSession.username.prefix(1)).uppercased())
                                .font(.system(size: 44, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.legoRed, lineWidth: 2))

                Circle()
                    .fill(Color.legoRed)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "camera.fill")
                            .font(.system(size: 15)).foregroundColor(.white)
                    )
                    .offset(x: 4, y: 4)
            }
            .onTapGesture { showingLibrary = true }

            Text("Tap to change photo")
                .font(.legoCaption).foregroundColor(.secondaryText)
        }
    }

    // MARK: - Form Field

    private func formField(label: String, icon: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(label, systemImage: icon).font(.legoCardTitle).foregroundColor(.legoYellow)
            TextField(placeholder, text: text)
                .foregroundColor(.lightText).font(.legoBody)
                .padding(14).background(Color.cardBackground).cornerRadius(12)
        }
        .padding(.horizontal)
    }

    // MARK: - Save

    private func saveChanges() {
        isSaving = true
        saveError = nil
        let trimmedName = draftDisplayName.trimmingCharacters(in: .whitespaces)
        let trimmedBio  = draftBio.trimmingCharacters(in: .whitespaces)

        Task {
            do {
                try await userSession.updateProfile(displayName: trimmedName, bio: trimmedBio)
            } catch {
                await MainActor.run { saveError = "Save failed: \(error.localizedDescription)" }
            }
            await MainActor.run {
                isSaving = false
                if saveError == nil { dismiss() }
            }
        }
    }
}

#Preview {
    EditProfileView()
}

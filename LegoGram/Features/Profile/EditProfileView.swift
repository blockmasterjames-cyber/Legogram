import SwiftUI
import PhotosUI

/// The Edit Profile screen — lets the user update their display name and bio.
/// Sprint 9: Saves changes to both Firestore (via UserSession) and AppStorage.
struct EditProfileView: View {

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var userSession = UserSession.shared

    // Local draft — only written back when the user taps Save
    @State private var draftDisplayName = ""
    @State private var draftBio         = ""

    // Avatar
    @State private var selectedAvatar: UIImage?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingLibrary   = false

    // Saving spinner
    @State private var isSaving = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        // MARK: Avatar
                        avatarSection
                            .padding(.top, 8)

                        // MARK: Display Name
                        formField(
                            label: "Display Name",
                            icon: "person.fill",
                            placeholder: "Your name",
                            text: $draftDisplayName
                        )

                        // MARK: Bio
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Bio", systemImage: "text.alignleft")
                                .font(.legoCardTitle)
                                .foregroundColor(.legoYellow)

                            TextField("Tell the world about your Brick hobby...", text: $draftBio, axis: .vertical)
                                .lineLimit(3, reservesSpace: true)
                                .foregroundColor(.lightText)
                                .font(.legoBody)
                                .padding(14)
                                .background(Color.cardBackground)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)

                        // MARK: Save Button
                        Button {
                            saveChanges()
                        } label: {
                            HStack(spacing: 10) {
                                if isSaving {
                                    ProgressView().tint(.white)
                                    Text("Saving...").font(.legoCardTitle)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Save Changes").font(.legoCardTitle)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.legoRed)
                            .foregroundColor(.white)
                            .cornerRadius(16)
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
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.legoYellow)
                }
            }
        }
        .onAppear {
            draftDisplayName = userSession.displayName
            draftBio         = userSession.bio
        }
        .photosPicker(isPresented: $showingLibrary, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    selectedAvatar = img
                }
            }
        }
    }

    // MARK: - Avatar Section

    private var avatarSection: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if let avatar = selectedAvatar {
                        Image(uiImage: avatar)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.secondaryText)
                    }
                }
                .frame(width: 100, height: 100)
                .background(Color.cardBackground)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.legoRed, lineWidth: 2))

                Circle()
                    .fill(Color.legoRed)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "camera.fill")
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                    )
                    .offset(x: 4, y: 4)
            }
            .onTapGesture { showingLibrary = true }

            Text("Tap to change photo")
                .font(.legoCaption)
                .foregroundColor(.secondaryText)
        }
    }

    // MARK: - Reusable Form Field

    private func formField(
        label: String,
        icon: String,
        placeholder: String,
        text: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(label, systemImage: icon)
                .font(.legoCardTitle)
                .foregroundColor(.legoYellow)

            TextField(placeholder, text: text)
                .foregroundColor(.lightText)
                .font(.legoBody)
                .padding(14)
                .background(Color.cardBackground)
                .cornerRadius(12)
        }
        .padding(.horizontal)
    }

    // MARK: - Save Action

    private func saveChanges() {
        isSaving = true
        let trimmedName = draftDisplayName.trimmingCharacters(in: .whitespaces)
        let trimmedBio  = draftBio.trimmingCharacters(in: .whitespaces)

        Task {
            do {
                try await userSession.updateProfile(displayName: trimmedName, bio: trimmedBio)
            } catch {
                print("[EditProfileView] Save error: \(error.localizedDescription)")
            }
            isSaving = false
            dismiss()
        }
    }
}

#Preview {
    EditProfileView()
}

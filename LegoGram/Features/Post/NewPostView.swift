import SwiftUI

/// The New Post screen — this is where you share your amazing LEGO build with everyone!
/// Pick a photo, enter the set number, write a description, and tap Post.
/// The camera and photo library buttons are placeholders for now — photos come in a future sprint.
struct NewPostView: View {

    @State private var legoSetNumber = ""
    @State private var description   = ""
    @State private var hasPhoto      = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        // MARK: - Screen Title
                        Text("New Post")
                            .font(.legoScreenTitle)
                            .foregroundColor(.lightText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.top, 8)

                        // MARK: - Photo Picker Placeholder
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.cardBackground)
                                .frame(height: 260)

                            if hasPhoto {
                                // Photo thumbnail will appear here when wired up
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(.successGreen)
                            } else {
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
                                            // TODO: Open camera
                                        } label: {
                                            Label("Camera", systemImage: "camera.fill")
                                                .font(.legoBody)
                                                .padding(.horizontal, 20)
                                                .padding(.vertical, 10)
                                                .background(Color.legoRed)
                                                .foregroundColor(.white)
                                                .cornerRadius(12)
                                        }

                                        // Photo Library Button
                                        Button {
                                            // TODO: Open photo library
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
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)

                        // MARK: - LEGO Set Number Field
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

                        // MARK: - Description Field
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

                        // MARK: - Post Button
                        Button {
                            // TODO: Upload post to Firebase
                        } label: {
                            HStack {
                                Image(systemName: "paperplane.fill")
                                Text("Post Your Build!")
                                    .font(.legoCardTitle)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                legoSetNumber.isEmpty
                                    ? Color.legoRed.opacity(0.4)
                                    : Color.legoRed
                            )
                            .foregroundColor(.white)
                            .cornerRadius(16)
                        }
                        .disabled(legoSetNumber.isEmpty)
                        .padding(.horizontal)

                        // Bottom padding for tab bar
                        Color.clear.frame(height: 80)
                    }
                    .padding(.top)
                }
            }
        }
    }
}

#Preview {
    NewPostView()
}

import SwiftUI
import Photos

/// A beautiful shareable card for Instagram Stories (9:16 ratio).
/// Sprint 5 — Feature 4.
/// Renders using ImageRenderer and lets the user save or share.
struct StoryShareCardView: View {

    let post: LegoPost

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var postStore = PostStore.shared
    @State private var renderedImage: UIImage?
    @State private var showingShareSheet = false
    @State private var isRendering = false
    @State private var savedSuccessfully = false
    @State private var resolvedPostImage: UIImage?

    private var legoSet: LegoSet? { LegoSetDatabase.set(for: post.legoSetNumber) }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        Text("Share to Stories")
                            .font(.legoScreenTitle)
                            .foregroundColor(.lightText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.top, 8)

                        Text("A story card will be generated and saved to your photos.")
                            .font(.legoBody)
                            .foregroundColor(.secondaryText)
                            .padding(.horizontal)

                        // Preview of the card
                        StoryCardContent(post: post, legoSet: legoSet, postImage: resolvedPostImage)
                            .frame(width: 300, height: 300 * (16.0 / 9.0))
                            .cornerRadius(20)
                            .shadow(color: .black.opacity(0.5), radius: 16, x: 0, y: 8)
                            .padding(.horizontal)

                        if savedSuccessfully {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.successGreen)
                                Text("Saved to Photos! Open Instagram and select it from your library.")
                                    .font(.legoBody)
                                    .foregroundColor(.successGreen)
                            }
                            .padding()
                            .background(Color.successGreen.opacity(0.12))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }

                        // Save to Photos
                        Button { renderAndSave() } label: {
                            HStack(spacing: 10) {
                                if isRendering {
                                    ProgressView().tint(.white)
                                    Text("Generating...").font(.legoCardTitle)
                                } else {
                                    Image(systemName: "photo.badge.arrow.down.fill")
                                    Text("Save to Photos").font(.legoCardTitle)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.legoRed)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                        }
                        .disabled(isRendering)
                        .padding(.horizontal)

                        // Share sheet
                        Button { renderAndShare() } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share via...").font(.legoCardTitle)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.cardBackground)
                            .foregroundColor(.legoYellow)
                            .cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.legoYellow, lineWidth: 1))
                        }
                        .disabled(isRendering)
                        .padding(.horizontal)

                        Color.clear.frame(height: 40)
                    }
                    .padding(.top)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }.foregroundColor(.legoYellow)
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let img = renderedImage {
                ShareSheet(activityItems: [img])
            }
        }
        .onAppear { resolvePostImage() }
    }

    // MARK: - Resolve Post Image

    /// Pre-fetches the post image so the card renderer (which is synchronous)
    /// has a real UIImage to draw instead of relying on AsyncImage.
    private func resolvePostImage() {
        // 1. User-taken photo stored in PostStore
        if let img = postStore.postImages[post.id] {
            resolvedPostImage = img
            return
        }
        // 2. Catalog image from LEGO set database
        if let imageURL = legoSet?.setImageURL {
            Task {
                do {
                    let (data, _) = try await URLSession.shared.data(from: imageURL)
                    if let img = UIImage(data: data) {
                        await MainActor.run { resolvedPostImage = img }
                    }
                } catch {
                    // Fall through — card will show placeholder
                }
            }
        }
    }

    // MARK: - Render Card

    @MainActor
    private func renderCard() -> UIImage? {
        let cardView = StoryCardContent(post: post, legoSet: legoSet, postImage: resolvedPostImage)
            .frame(width: 390, height: 390 * (16.0 / 9.0))

        let renderer = ImageRenderer(content: cardView)
        renderer.scale = 3.0
        return renderer.uiImage
    }

    private func renderAndSave() {
        isRendering = true
        Task { @MainActor in
            guard let image = renderCard() else { isRendering = false; return }
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                DispatchQueue.main.async {
                    if status == .authorized || status == .limited {
                        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                        savedSuccessfully = true
                    }
                    isRendering = false
                }
            }
        }
    }

    private func renderAndShare() {
        isRendering = true
        Task { @MainActor in
            guard let image = renderCard() else { isRendering = false; return }
            renderedImage = image
            isRendering = false
            showingShareSheet = true
        }
    }
}

// MARK: - Story Card Content (the actual renderable card)

/// The visual content of the 9:16 Instagram Story card.
/// Dark background, LEGO red/yellow accents, set image, details, and website URL.
struct StoryCardContent: View {

    let post: LegoPost
    let legoSet: LegoSet?
    /// Pre-resolved UIImage so ImageRenderer can draw a real photo synchronously.
    var postImage: UIImage? = nil

    var body: some View {
        ZStack {
            // Dark background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.08, blue: 0.12),
                    Color(red: 0.14, green: 0.05, blue: 0.05)
                ],
                startPoint: .top, endPoint: .bottom
            )

            // Red accent stripe at top
            VStack {
                Rectangle()
                    .fill(Color.legoRed)
                    .frame(height: 6)
                Spacer()
            }

            // Yellow accent stripe at bottom
            VStack {
                Spacer()
                Rectangle()
                    .fill(Color.legoYellow)
                    .frame(height: 6)
            }

            VStack(spacing: 0) {

                // MARK: Logo at top
                HStack {
                    Text("Brick")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.legoRed)
                        .cornerRadius(6)
                    Text("Feed")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(.legoYellow)
                }
                .padding(.top, 24)

                Spacer()

                // MARK: Set Image (square) — uses pre-resolved UIImage for reliable rendering
                if let uiImage = postImage {
                    Image(uiImage: uiImage)
                        .resizable().scaledToFill()
                        .frame(width: 220, height: 220)
                        .clipped()
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.legoYellow, lineWidth: 2))
                } else {
                    imagePlaceholder
                }

                Spacer().frame(height: 16)

                // MARK: Set name + Age badge
                HStack(spacing: 8) {
                    Text(legoSet?.name ?? post.legoSetName)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    if let set = legoSet {
                        Text(set.ageRating)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.darkBackground)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.legoYellow)
                            .cornerRadius(4)
                    }
                }
                .padding(.horizontal, 20)

                // Set number + theme
                if let set = legoSet {
                    Text("#\(set.setNumber)  ·  \(set.theme)")
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.top, 4)
                }

                Spacer().frame(height: 14)

                // MARK: Posted by
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.legoRed)
                        .frame(width: 26, height: 26)
                        .overlay(
                            Text(String(post.username.prefix(1)).uppercased())
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        )
                    Text("@\(post.username)")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.legoRed)
                        Text("\(post.likeCount)")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 24)

                // Description snippet
                if !post.description.isEmpty {
                    Text(BadWordFilter.filter(post.description))
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.white.opacity(0.75))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                }

                Spacer().frame(height: 14)

                // MARK: Buy Set button
                if let set = legoSet {
                    HStack(spacing: 8) {
                        Image(systemName: "cart.fill")
                            .font(.system(size: 12))
                        Text("Buy Set  ·  $\(String(format: "%.0f", set.retailPrice))")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.darkBackground)
                    .padding(.horizontal, 20).padding(.vertical, 10)
                    .background(Color.legoYellow)
                    .cornerRadius(20)
                }

                Spacer()

                // MARK: Website URL at bottom
                Text("brickfeed.app  ·  Share Your Builds!")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, 20)
            }
        }
        .clipped()
    }

    private var imagePlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.legoRed.opacity(0.3), Color.legoYellow.opacity(0.2)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .frame(width: 220, height: 220)
            VStack(spacing: 8) {
                Image(systemName: "building.2.crop.circle")
                    .font(.system(size: 40)).foregroundColor(.secondaryText)
                Text("Set #\(post.legoSetNumber)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.legoYellow)
            }
        }
    }
}

// MARK: - UIKit Share Sheet Bridge

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    StoryShareCardView(post: .placeholder)
}

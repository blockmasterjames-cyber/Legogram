import SwiftUI

/// Sprint 6 Feature 5 — Set Detail screen.
/// Shown when the user taps any set in the Popular Sets list (or search results).
/// Displays the official set image, all set details, and a ranked list of
/// LegoGram users who have posted that set, ordered by most likes first.
/// Each builder row has a Follow button and a tappable username → OtherProfileView.
struct SetDetailView: View {

    let set: LegoSet

    @ObservedObject private var postStore = PostStore.shared
    @State private var selectedUsername: String?

    /// Posts for this set, sorted highest-likes first.
    private var builderPosts: [LegoPost] {
        postStore.visiblePosts
            .filter { $0.legoSetNumber == set.setNumber && !$0.isCustomBuild }
            .sorted { $0.likeCount > $1.likeCount }
    }

    var body: some View {
        ZStack {
            Color.darkBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    setHeaderImage
                    setInfoCard
                    buildersSection
                    Color.clear.frame(height: 80)
                }
            }
        }
        .navigationTitle(set.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.cardBackground, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(item: $selectedUsername) { username in
            OtherProfileView(username: username)
        }
    }

    // MARK: - Header Image

    private var setHeaderImage: some View {
        Group {
            if let url = set.setImageURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFit()
                    case .empty:
                        ZStack {
                            Color.cardBackground
                            ProgressView().tint(.legoYellow).scaleEffect(1.3)
                        }
                    default:
                        headerPlaceholder
                    }
                }
            } else {
                headerPlaceholder
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 260)
        .background(Color.cardBackground)
    }

    private var headerPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color.legoRed.opacity(0.3), Color.legoYellow.opacity(0.2)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            VStack(spacing: 10) {
                Image(systemName: "building.2.crop.circle")
                    .font(.system(size: 64)).foregroundColor(.secondaryText)
                Text(set.name)
                    .font(.legoCardTitle).foregroundColor(.legoYellow)
                    .multilineTextAlignment(.center).padding(.horizontal)
            }
        }
    }

    // MARK: - Set Info Card

    private var setInfoCard: some View {
        VStack(alignment: .leading, spacing: 14) {

            // Name + age badge
            HStack(alignment: .top, spacing: 8) {
                Text(set.name)
                    .font(.legoScreenTitle).foregroundColor(.lightText)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                AgeRatingBadge(rating: set.ageRating)
            }

            // Set number · Theme
            HStack(spacing: 8) {
                Label("#\(set.setNumber)", systemImage: "number.circle.fill")
                    .font(.legoBody).foregroundColor(.legoYellow)
                Text("·").foregroundColor(.secondaryText)
                Text(set.theme)
                    .font(.legoBody).foregroundColor(.secondaryText)
            }

            // Piece count
            Label("\(set.pieceCount) pieces", systemImage: "square.grid.3x3.fill")
                .font(.legoBody).foregroundColor(.secondaryText)

            // Price + Buy button
            HStack {
                Text("$\(String(format: "%.2f", set.retailPrice))")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.legoYellow)

                Spacer()

                if let url = URL(string: set.legoStoreURL) {
                    Link(destination: url) {
                        Label("Buy on LEGO.com", systemImage: "cart.fill")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.darkBackground)
                            .padding(.horizontal, 14).padding(.vertical, 9)
                            .background(Color.legoYellow)
                            .cornerRadius(10)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .padding(16)
    }

    // MARK: - Builders Section

    private var buildersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Builders Who Posted This Set")
                    .font(.legoCardTitle).foregroundColor(.legoYellow)
                Spacer()
                if !builderPosts.isEmpty {
                    Text("\(builderPosts.count) builder\(builderPosts.count == 1 ? "" : "s")")
                        .font(.legoCaption).foregroundColor(.secondaryText)
                }
            }
            .padding(.horizontal, 16)

            if builderPosts.isEmpty {
                emptyBuildersState
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(builderPosts.enumerated()), id: \.element.id) { index, post in
                        builderRow(post: post, rank: index + 1)
                        if index < builderPosts.count - 1 {
                            Divider()
                                .background(Color.secondaryText.opacity(0.25))
                                .padding(.leading, 68)
                        }
                    }
                }
                .background(Color.cardBackground)
                .cornerRadius(12)
                .padding(.horizontal, 16)
            }
        }
    }

    private var emptyBuildersState: some View {
        VStack(spacing: 10) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 40)).foregroundColor(.secondaryText)
            Text("No posts yet for this set")
                .font(.legoCardTitle).foregroundColor(.lightText)
            Text("Be the first to post this build!")
                .font(.legoBody).foregroundColor(.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    // MARK: - Builder Row

    private func builderRow(post: LegoPost, rank: Int) -> some View {
        HStack(spacing: 12) {

            // Rank number
            ZStack {
                Circle()
                    .fill(rankColor(rank))
                    .frame(width: 28, height: 28)
                if rank <= 3 {
                    Image(systemName: "medal.fill")
                        .font(.system(size: 12)).foregroundColor(.white)
                } else {
                    Text("\(rank)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }

            // Avatar
            Circle()
                .fill(Color.legoRed.opacity(0.8))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(String(post.username.prefix(1)).uppercased())
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                )

            // Username + like count (tappable → OtherProfileView)
            Button { selectedUsername = post.username } label: {
                VStack(alignment: .leading, spacing: 3) {
                    Text("@\(post.username)")
                        .font(.legoCardTitle).foregroundColor(.lightText)
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 11)).foregroundColor(.legoRed)
                        Text("\(post.likeCount) likes")
                            .font(.legoCaption).foregroundColor(.secondaryText)
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            // Follow button
            Button { postStore.toggleFollow(post.username) } label: {
                let following = postStore.isFollowing(post.username)
                Text(following ? "Following" : "Follow")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(following ? .lightText : .white)
                    .padding(.horizontal, 14).padding(.vertical, 7)
                    .background(following ? Color.cardBackground : Color.legoRed)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(following ? Color.secondaryText : Color.clear, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(12)
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return Color(hex: "#FFD700")
        case 2: return Color(hex: "#C0C0C0")
        case 3: return Color(hex: "#CD7F32")
        default: return Color.cardBackground
        }
    }
}

#Preview {
    NavigationStack {
        SetDetailView(set: .placeholder)
    }
}

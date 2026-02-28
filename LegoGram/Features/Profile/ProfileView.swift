import SwiftUI

/// The Profile screen — your personal LEGO portfolio page!
/// It shows your cover photo, avatar, username, stats, and a grid of all your builds.
/// All content is placeholder for now — real user data connects in a future sprint.
struct ProfileView: View {

    /// Grid layout for the post thumbnail grid (3 equal columns)
    private let gridColumns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {

                        // MARK: - Cover Photo
                        ZStack(alignment: .bottomLeading) {
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.legoRed, Color.legoYellow.opacity(0.6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(height: 160)

                            // LEGO stud pattern overlay for flavor
                            HStack(spacing: 20) {
                                ForEach(0..<8, id: \.self) { _ in
                                    Circle()
                                        .fill(.white.opacity(0.15))
                                        .frame(width: 24, height: 24)
                                }
                            }
                            .padding(.bottom, 16)
                            .padding(.leading, 12)
                        }

                        // MARK: - Avatar + Edit Button
                        HStack(alignment: .bottom) {
                            Circle()
                                .fill(Color.cardBackground)
                                .frame(width: 90, height: 90)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 44))
                                        .foregroundColor(.secondaryText)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color.darkBackground, lineWidth: 4)
                                )
                                .offset(y: -40)
                                .padding(.leading, 16)

                            Spacer()

                            Button {
                                // TODO: Open edit profile
                            } label: {
                                Text("Edit Profile")
                                    .font(.legoCaption)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.cardBackground)
                                    .foregroundColor(.lightText)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.secondaryText, lineWidth: 1)
                                    )
                            }
                            .padding(.trailing, 16)
                            .padding(.bottom, 8)
                        }
                        .padding(.bottom, -32) // Compensate for avatar offset

                        // MARK: - Username & Bio
                        VStack(alignment: .leading, spacing: 6) {
                            Text("@blockmasterjames")
                                .font(.legoScreenTitle)
                                .foregroundColor(.lightText)

                            Text("Building one brick at a time 🧱 | LEGO fan since 2010")
                                .font(.legoBody)
                                .foregroundColor(.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.top, 48)
                        .padding(.bottom, 16)

                        // MARK: - Stats Row
                        HStack(spacing: 0) {
                            statCell(value: "24",   label: "Posts")
                            Divider().frame(height: 40).background(Color.secondaryText)
                            statCell(value: "1.2k", label: "Followers")
                            Divider().frame(height: 40).background(Color.secondaryText)
                            statCell(value: "348",  label: "Following")
                            Divider().frame(height: 40).background(Color.secondaryText)
                            statCell(value: "$12.40", label: "Earnings")
                        }
                        .padding(.vertical, 12)
                        .background(Color.cardBackground)
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)

                        // MARK: - Post Grid
                        LazyVGrid(columns: gridColumns, spacing: 2) {
                            ForEach(0..<12, id: \.self) { index in
                                Rectangle()
                                    .fill(
                                        index % 3 == 0
                                            ? Color.legoRed.opacity(0.25)
                                            : Color.cardBackground
                                    )
                                    .aspectRatio(1, contentMode: .fit)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .foregroundColor(.secondaryText.opacity(0.5))
                                    )
                            }
                        }

                        // Bottom padding for tab bar
                        Color.clear.frame(height: 80)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // TODO: Open settings / sign out
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.legoYellow)
                    }
                }
            }
        }
    }

    // MARK: - Stat Cell Helper
    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.legoCardTitle)
                .foregroundColor(.lightText)
            Text(label)
                .font(.legoCaption)
                .foregroundColor(.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ProfileView()
}

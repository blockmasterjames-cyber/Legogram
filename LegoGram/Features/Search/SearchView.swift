import SwiftUI

/// The Search screen — where you can find LEGO builds by set number.
/// Type a set number in the search bar and it will find posts about that set.
/// Right now it shows placeholder content to preview the layout.
struct SearchView: View {

    @State private var searchText = ""

    /// Placeholder popular sets — real data will come from Firebase in a future sprint.
    private let popularSets: [PopularSetPlaceholder] = [
        PopularSetPlaceholder(setNumber: "75192", name: "Millennium Falcon",    theme: "Star Wars",     posts: 1_243),
        PopularSetPlaceholder(setNumber: "10317", name: "Land Rover Classic",   theme: "Icons",         posts: 876),
        PopularSetPlaceholder(setNumber: "42151", name: "Bugatti Bolide",       theme: "Technic",       posts: 654),
        PopularSetPlaceholder(setNumber: "21325", name: "Medieval Blacksmith",  theme: "Ideas",         posts: 541),
        PopularSetPlaceholder(setNumber: "10300", name: "Back to the Future",   theme: "Icons",         posts: 498)
    ]

    /// Placeholder search-result grid tiles — real ones will be photo thumbnails.
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
                    VStack(alignment: .leading, spacing: 20) {

                        // MARK: - Screen Title
                        Text("Search")
                            .font(.legoScreenTitle)
                            .foregroundColor(.lightText)
                            .padding(.horizontal)
                            .padding(.top, 8)

                        // MARK: - Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondaryText)

                            TextField("Search by LEGO set number...", text: $searchText)
                                .foregroundColor(.lightText)
                                .font(.legoBody)
                                .autocorrectionDisabled()
                                .keyboardType(.numberPad)

                            if !searchText.isEmpty {
                                Button {
                                    searchText = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondaryText)
                                }
                            }
                        }
                        .padding(12)
                        .background(Color.cardBackground)
                        .cornerRadius(12)
                        .padding(.horizontal)

                        // MARK: - Search Results Placeholder
                        if !searchText.isEmpty {
                            Text("Results for \"\(searchText)\"")
                                .font(.legoCardTitle)
                                .foregroundColor(.lightText)
                                .padding(.horizontal)

                            LazyVGrid(columns: gridColumns, spacing: 2) {
                                ForEach(0..<9, id: \.self) { _ in
                                    Rectangle()
                                        .fill(Color.cardBackground)
                                        .aspectRatio(1, contentMode: .fit)
                                        .overlay(
                                            Image(systemName: "photo")
                                                .foregroundColor(.secondaryText)
                                        )
                                }
                            }
                            .padding(.horizontal)
                        }

                        // MARK: - Popular Sets Section
                        Text("Popular Sets")
                            .font(.legoCardTitle)
                            .foregroundColor(.lightText)
                            .padding(.horizontal)

                        VStack(spacing: 1) {
                            ForEach(popularSets) { set in
                                PopularSetRow(set: set)
                            }
                        }
                        .background(Color.cardBackground)
                        .cornerRadius(12)
                        .padding(.horizontal)

                        // Bottom padding for tab bar
                        Color.clear.frame(height: 80)
                    }
                }
            }
        }
    }
}

// MARK: - Placeholder Model
struct PopularSetPlaceholder: Identifiable {
    let id = UUID()
    let setNumber: String
    let name: String
    let theme: String
    let posts: Int
}

// MARK: - Popular Set Row
struct PopularSetRow: View {
    let set: PopularSetPlaceholder

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.legoRed.opacity(0.2))
                .frame(width: 52, height: 52)
                .overlay(
                    Text(set.setNumber)
                        .font(.legoCaption)
                        .foregroundColor(.legoYellow)
                        .multilineTextAlignment(.center)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(set.name)
                    .font(.legoCardTitle)
                    .foregroundColor(.lightText)
                Text("#\(set.setNumber) · \(set.theme)")
                    .font(.legoCaption)
                    .foregroundColor(.secondaryText)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(set.posts)")
                    .font(.legoCardTitle)
                    .foregroundColor(.legoYellow)
                Text("posts")
                    .font(.legoCaption)
                    .foregroundColor(.secondaryText)
            }
        }
        .padding(12)
        .background(Color.cardBackground)
    }
}

#Preview {
    SearchView()
}

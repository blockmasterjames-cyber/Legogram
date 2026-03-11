import SwiftUI

/// The Search screen — find LEGO sets by number OR by name.
/// Sprint 3: real search powered by LegoSetDatabase.
/// On iPad, results appear in a side-by-side layout using the extra space.
struct SearchView: View {

    @State private var searchText = ""
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var searchResults: [LegoSet] {
        LegoSetDatabase.search(searchText)
    }

    private var popularSets: [LegoSet] {
        ["75192", "71043", "10307", "76210", "21333", "42115", "60380", "76419", "21325", "76916"]
            .compactMap { LegoSetDatabase.set(for: $0) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                if horizontalSizeClass == .regular {
                    iPadLayout
                } else {
                    iPhoneLayout
                }
            }
            // Tap anywhere outside search bar to dismiss keyboard
            .onTapGesture { hideKeyboard() }
        }
    }

    // MARK: - iPhone Layout

    private var iPhoneLayout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerAndSearch
                resultsList
                Color.clear.frame(height: 80)
            }
        }
    }

    // MARK: - iPad Layout (side-by-side panels)

    private var iPadLayout: some View {
        HStack(alignment: .top, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerAndSearch
                    if !searchText.isEmpty {
                        Text("\(searchResults.count) result\(searchResults.count == 1 ? "" : "s")")
                            .font(.legoCaption)
                            .foregroundColor(.secondaryText)
                            .padding(.horizontal)
                    }
                    Color.clear.frame(height: 80)
                }
            }
            .frame(maxWidth: 360)

            Divider().background(Color.secondaryText.opacity(0.3))

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    resultsList
                    Color.clear.frame(height: 80)
                }
                .padding(.horizontal, 8)
            }
        }
    }

    // MARK: - Shared Components

    @ViewBuilder
    private var headerAndSearch: some View {
        Text("Search")
            .font(.legoScreenTitle)
            .foregroundColor(.lightText)
            .padding(.horizontal)
            .padding(.top, 8)

        // Search bar — accepts both set numbers AND set names
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondaryText)

            TextField("Set number or name (e.g. 75192 or Falcon)", text: $searchText)
                .foregroundColor(.lightText)
                .font(.legoBody)
                .autocorrectionDisabled()
                .onSubmit { hideKeyboard() }

            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondaryText)
                }
            }
        }
        .padding(12)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .padding(.horizontal)
    }

    @ViewBuilder
    private var resultsList: some View {
        if searchText.isEmpty {
            popularSetsSection
        } else if searchResults.isEmpty {
            noResultsState
        } else {
            Text("Results for \"\(searchText)\"")
                .font(.legoCardTitle)
                .foregroundColor(.lightText)
                .padding(.horizontal)

            VStack(spacing: 1) {
                ForEach(searchResults) { set in
                    SearchSetRow(set: set)
                }
            }
            .background(Color.cardBackground)
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    private var popularSetsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Popular Sets")
                .font(.legoCardTitle)
                .foregroundColor(.lightText)
                .padding(.horizontal)

            VStack(spacing: 1) {
                ForEach(popularSets) { set in
                    SearchSetRow(set: set)
                }
            }
            .background(Color.cardBackground)
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    private var noResultsState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondaryText)
            Text("No sets found for \"\(searchText)\"")
                .font(.legoCardTitle)
                .foregroundColor(.lightText)
            Text("Try a set number like 75192\nor a name like Millennium Falcon")
                .font(.legoBody)
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
        .padding(.horizontal)
    }
}

// MARK: - Search Set Row

/// One result row: real set image (AsyncImage), name, age rating badge, theme, piece count, price.
struct SearchSetRow: View {
    let set: LegoSet

    var body: some View {
        HStack(spacing: 12) {

            // Thumbnail — loads official image from Brickset CDN
            Group {
                if let url = set.setImageURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable()
                                .scaledToFill()
                                .frame(width: 64, height: 64)
                                .clipped()
                        case .failure, .empty:
                            thumbnailPlaceholder
                        @unknown default:
                            thumbnailPlaceholder
                        }
                    }
                } else {
                    thumbnailPlaceholder
                }
            }
            .frame(width: 64, height: 64)
            .cornerRadius(8)
            .clipped()

            // Set details
            VStack(alignment: .leading, spacing: 4) {
                // Name + age badge on same line
                HStack(spacing: 6) {
                    Text(set.name)
                        .font(.legoCardTitle)
                        .foregroundColor(.lightText)
                        .lineLimit(1)
                    AgeRatingBadge(rating: set.ageRating)
                }
                Text("#\(set.setNumber)  ·  \(set.theme)")
                    .font(.legoCaption)
                    .foregroundColor(.secondaryText)
                Label("\(set.pieceCount) pieces", systemImage: "square.grid.3x3.fill")
                    .font(.legoCaption)
                    .foregroundColor(.legoYellow)
            }

            Spacer()

            // Price + Shop link
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(String(format: "%.2f", set.retailPrice))")
                    .font(.legoCardTitle)
                    .foregroundColor(.legoYellow)
                if let url = URL(string: set.legoStoreURL) {
                    Link(destination: url) {
                        Text("Shop")
                            .font(.legoCaption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.legoYellow)
                            .foregroundColor(.darkBackground)
                            .cornerRadius(6)
                    }
                }
            }
        }
        .padding(12)
        .background(Color.cardBackground)
    }

    private var thumbnailPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color.legoRed.opacity(0.3), Color.legoYellow.opacity(0.2)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            VStack(spacing: 2) {
                Image(systemName: "building.2.crop.circle")
                    .font(.system(size: 18))
                    .foregroundColor(.secondaryText)
                Text(set.setNumber)
                    .font(.legoCaption)
                    .foregroundColor(.legoYellow)
                    .minimumScaleFactor(0.7)
            }
        }
    }
}

// Keep old PopularSetPlaceholder so any remaining references compile
struct PopularSetPlaceholder: Identifiable {
    let id = UUID()
    let setNumber: String
    let name: String
    let theme: String
    let posts: Int
}

#Preview {
    SearchView()
}

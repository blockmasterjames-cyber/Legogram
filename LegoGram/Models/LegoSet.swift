import Foundation

/// Represents an official LEGO set from the LEGO catalog.
/// Used to auto-fill set details when a user types a set number in the New Post screen.
/// Set data will be stored in the Firestore "lego_sets" collection.
struct LegoSet: Identifiable, Codable, Hashable {

    // MARK: - Identity
    /// Firestore document ID (same as setNumber for easy lookup).
    var id: String

    /// Official LEGO set number printed on the box, e.g. "75192".
    var setNumber: String

    /// Full product name of the set, e.g. "Millennium Falcon".
    var name: String

    // MARK: - Set Details
    /// The LEGO theme the set belongs to, e.g. "Star Wars", "Technic", "City".
    var theme: String

    /// Total number of pieces in the set.
    var pieceCount: Int

    /// Official retail price in USD.
    var retailPrice: Double

    // MARK: - Shopping
    /// Direct link to buy the set on the LEGO website.
    var buyLink: String

    // MARK: - Media
    /// URL of the official set box art image.
    var imageURL: String

    // MARK: - Metadata
    /// The year LEGO released this set.
    var releaseYear: Int

    // MARK: - Firestore Field Keys
    enum CodingKeys: String, CodingKey {
        case id
        case setNumber   = "set_number"
        case name
        case theme
        case pieceCount  = "piece_count"
        case retailPrice = "retail_price"
        case buyLink     = "buy_link"
        case imageURL    = "image_url"
        case releaseYear = "release_year"
    }
}

// MARK: - Placeholder / Preview
extension LegoSet {
    /// A fake set used in SwiftUI previews and placeholder screens.
    static let placeholder = LegoSet(
        id: "75192",
        setNumber: "75192",
        name: "Millennium Falcon",
        theme: "Star Wars",
        pieceCount: 7_541,
        retailPrice: 849.99,
        buyLink: "https://www.lego.com/en-us/product/millennium-falcon-75192",
        imageURL: "",
        releaseYear: 2017
    )
}

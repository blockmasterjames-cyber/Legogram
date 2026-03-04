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

// MARK: - Age Rating & CDN Image URL (Sprint 4)
extension LegoSet {

    /// Recommended age rating badge text for this set, based on set number.
    var ageRating: String {
        switch setNumber {
        // Star Wars — UCS / massive sets
        case "75192", "75313", "75252": return "18+"
        case "75309", "75290":          return "14+"
        case "75341":                   return "9+"
        // Technic
        case "42115", "42083":          return "18+"
        case "42110":                   return "11+"
        case "42154", "42096":          return "10+"
        case "42151":                   return "9+"
        // City
        case "60228":                   return "7+"
        case "60380", "60350",
             "60197", "60316", "60293": return "6+"
        // Creator 3-in-1
        case "31120", "31119", "31109": return "9+"
        case "31140", "31127", "31128": return "7+"
        // Ideas (all adult collector sets)
        case "21325", "21335", "21333",
             "21326", "21330", "21334": return "18+"
        // Icons (all adult collector sets)
        case "10317", "10300", "10281",
             "10280", "10307", "10295": return "18+"
        // Harry Potter
        case "76405", "76391":          return "18+"
        case "71043":                   return "16+"
        case "76419", "75969", "76388": return "9+"
        // Marvel
        case "76210", "76218", "76215": return "18+"
        case "76223":                   return "16+"
        case "76261":                   return "9+"
        case "76243":                   return "6+"
        // Speed Champions
        case "76916", "76914", "76906",
             "76920", "76917", "76911": return "9+"
        // Architecture
        case "21044", "21056", "21057",
             "21058", "21060", "21043": return "12+"
        default: return "6+"
        }
    }

    /// URL of the set's official thumbnail image.
    /// Uses the stored imageURL when present, otherwise falls back to the
    /// Brickset CDN which hosts images keyed by set number.
    var setImageURL: URL? {
        let raw = imageURL.isEmpty
            ? "https://images.brickset.com/sets/images/\(setNumber)-1.jpg"
            : imageURL
        return URL(string: raw)
    }
}

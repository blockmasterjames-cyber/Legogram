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

    /// Recommended age rating badge text for this set.
    /// Known sets are mapped explicitly; unknown sets fall back to theme-based defaults.
    var ageRating: String {
        switch setNumber {
        // Star Wars — UCS / massive sets
        case "75192", "75313", "75252": return "18+"
        case "75309", "75290":          return "14+"
        case "75341", "75365", "75336",
             "75326", "75355", "75349",
             "75351", "75304", "75330",
             "75335", "75332":          return "9+"
        case "75299", "75345":          return "6+"
        // Technic
        case "42115", "42083", "42143",
             "42100", "42141", "42156": return "18+"
        case "42110":                   return "11+"
        case "42154", "42096", "42159": return "10+"
        case "42151", "42118":          return "9+"
        // City
        case "60228":                   return "7+"
        case "60380", "60350", "60197",
             "60316", "60293", "60337",
             "60319", "60390", "60362",
             "60388", "60385":          return "6+"
        // Creator 3-in-1
        case "31120", "31119", "31109",
             "31132", "31142":          return "9+"
        case "31140", "31127", "31128",
             "31136", "31141":          return "7+"
        // Ideas (all 18+)
        case "21325", "21335", "21333", "21326",
             "21330", "21334", "21337", "21338",
             "21340", "21341":          return "18+"
        // Icons (all 18+)
        case "10317", "10300", "10281", "10280",
             "10307", "10295", "10302", "10306",
             "10308", "10316":          return "18+"
        // Harry Potter
        case "76405", "76391":          return "18+"
        case "71043":                   return "16+"
        case "76419", "75969", "76388",
             "76403", "76407", "76420",
             "76394":                   return "9+"
        // Marvel
        case "76210", "76218", "76215",
             "76191", "76251":          return "18+"
        case "76223":                   return "16+"
        case "76261", "76241", "76260": return "9+"
        case "76243":                   return "6+"
        // Speed Champions (all 9+)
        case "76916", "76914", "76906", "76920",
             "76917", "76911", "76919", "76918",
             "76900", "76921":          return "9+"
        // Architecture (all 12+)
        case "21044", "21056", "21057", "21058",
             "21060", "21043", "21045", "21046",
             "21047", "21059":          return "12+"
        // DC
        case "76240", "76252", "76161": return "18+"
        case "76271", "76285", "76224",
             "76188", "76160", "76258",
             "76183":                   return "9+"
        // Ninjago
        case "71741", "71799":          return "12+"
        case "71793", "71791", "71765",
             "71794", "71796", "71800": return "9+"
        case "71780", "71772":          return "8+"
        // Friends (all 6+)
        case "41711", "41735", "41737", "41732",
             "42617", "42634", "41715", "41687",
             "41729", "41740":          return "6+"
        // Disney
        case "43222", "43230":          return "18+"
        case "43217", "43225", "43218",
             "43219", "43224", "43228": return "9+"
        case "43220", "43214":          return "6+"
        // Mindstorms
        case "51515", "31313", "45544",
             "45678", "45345", "45300": return "10+"
        // Botanical Collection (all 18+)
        case "10289", "10309", "10313",
             "10314", "10315", "10311",
             "40524", "40646":          return "18+"
        // Art (all 18+)
        case "31203", "31201", "31205",
             "31206", "31207", "31204",
             "31202", "31208":          return "18+"
        // Classic
        case "11030", "11031", "11032",
             "10698", "10696", "11021": return "4+"
        // Monkie Kid
        case "80012", "80023", "80037": return "9+"
        case "80033", "80041", "80026",
             "80046", "80050":          return "8+"
        // Jurassic World
        case "76956", "76960", "76961",
             "76948":                   return "9+"
        case "76957", "76958", "76959",
             "76940", "76951", "76963": return "7+"
        default:
            // Theme-based fallback for any unlisted sets
            switch theme {
            case "Technic":             return pieceCount > 2000 ? "18+" : "10+"
            case "Star Wars":           return pieceCount > 3000 ? "18+" : "9+"
            case "Ideas", "Icons",
                 "Art", "Botanical Collection": return "18+"
            case "Architecture":        return "12+"
            case "Creator 3-in-1":      return "9+"
            case "Mindstorms":          return "10+"
            case "DC", "Marvel":        return pieceCount > 2000 ? "18+" : "9+"
            case "Harry Potter":        return pieceCount > 2000 ? "18+" : "9+"
            case "Disney":              return pieceCount > 2000 ? "18+" : "6+"
            case "Friends":             return "6+"
            case "City":                return "6+"
            case "Classic":             return "4+"
            case "Ninjago":             return "8+"
            case "Speed Champions":     return "9+"
            case "Monkie Kid":          return "8+"
            case "Jurassic World":      return "7+"
            default:                    return "6+"
            }
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

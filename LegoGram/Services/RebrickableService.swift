import Foundation

/// Integrates with the Rebrickable API v3 (https://rebrickable.com/api/v3/)
/// to fetch real LEGO set data including names, piece counts, and official thumbnails.
///
/// SETUP: Register at https://rebrickable.com/users/account/ to get a free API key,
/// then replace the apiKey constant below with your key.
final class RebrickableService {

    static let shared = RebrickableService()

    // MARK: - API Key
    // Replace this with your Rebrickable API key (free at rebrickable.com)
    private let apiKey = "YOUR_REBRICKABLE_API_KEY"

    private let baseURL = "https://rebrickable.com/api/v3/lego"
    private var cache: [String: [LegoSet]] = [:]

    private init() {}

    // MARK: - Search Sets

    /// Search for LEGO sets by name or number via the Rebrickable API.
    /// Results are cached locally per query.
    func searchSets(query: String) async throws -> [LegoSet] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return [] }

        // Return cached results if available
        let cacheKey = trimmed.lowercased()
        if let cached = cache[cacheKey] { return cached }

        // Guard against placeholder key
        guard apiKey != "YOUR_REBRICKABLE_API_KEY" else {
            print("[RebrickableService] API key not configured. Add your key in RebrickableService.swift")
            return []
        }

        var components = URLComponents(string: "\(baseURL)/sets/")!
        components.queryItems = [
            URLQueryItem(name: "search", value: trimmed),
            URLQueryItem(name: "page_size", value: "20"),
            URLQueryItem(name: "ordering", value: "-year"),
        ]

        guard let url = components.url else { return [] }

        var request = URLRequest(url: url)
        request.setValue("key \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw RebrickableError.badResponse
        }

        let decoded = try JSONDecoder().decode(RebrickableSetResponse.self, from: data)
        let sets = decoded.results.compactMap { legoSetFromRebrickable($0) }

        // Cache and return
        cache[cacheKey] = sets
        return sets
    }

    // MARK: - Fetch Set by Number

    /// Fetch a single set by set number (e.g., "75192").
    func fetchSet(setNumber: String) async throws -> LegoSet? {
        guard apiKey != "YOUR_REBRICKABLE_API_KEY" else { return nil }

        // Rebrickable set numbers end in "-1" for the main set variant
        let rebrickableNum = setNumber.contains("-") ? setNumber : "\(setNumber)-1"

        let url = URL(string: "\(baseURL)/sets/\(rebrickableNum)/")!
        var request = URLRequest(url: url)
        request.setValue("key \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else { return nil }

        let decoded = try JSONDecoder().decode(RebrickableSet.self, from: data)
        return legoSetFromRebrickable(decoded)
    }

    // MARK: - Conversion

    private func legoSetFromRebrickable(_ r: RebrickableSet) -> LegoSet? {
        // Strip the trailing "-1" variant suffix to get the base set number
        let cleanNumber = r.setNum.hasSuffix("-1")
            ? String(r.setNum.dropLast(2))
            : r.setNum

        // Map Rebrickable theme_id to a theme name where known
        let theme = r.themeName ?? themeFromId(r.themeId)

        return LegoSet(
            id: cleanNumber,
            setNumber: cleanNumber,
            name: r.name,
            theme: theme,
            pieceCount: r.numParts,
            retailPrice: 0.0,   // Rebrickable doesn't provide retail price
            buyLink: "https://www.lego.com/en-us/search?q=\(cleanNumber)",
            imageURL: r.setImgUrl ?? "",
            releaseYear: r.year
        )
    }

    private func themeFromId(_ id: Int) -> String {
        let themes: [Int: String] = [
            158: "Star Wars", 1: "Technic", 52: "City", 22: "Creator",
            323: "Ideas", 736: "Icons", 246: "Harry Potter",
            76: "Marvel", 117: "Speed Champions", 9: "Architecture",
            275: "DC", 435: "NINJAGO", 216: "Friends",
            546: "Disney", 11: "Mindstorms", 228: "Botanical Collection",
            751: "Art", 84: "Classic"
        ]
        return themes[id] ?? "LEGO"
    }
}

// MARK: - Errors

enum RebrickableError: LocalizedError {
    case badResponse
    var errorDescription: String? { "Rebrickable API returned an unexpected response." }
}

// MARK: - Codable Response Models

private struct RebrickableSetResponse: Decodable {
    let count: Int
    let results: [RebrickableSet]
}

private struct RebrickableSet: Decodable {
    let setNum: String
    let name: String
    let year: Int
    let themeId: Int
    let numParts: Int
    let setImgUrl: String?
    var themeName: String?

    enum CodingKeys: String, CodingKey {
        case setNum    = "set_num"
        case name
        case year
        case themeId   = "theme_id"
        case numParts  = "num_parts"
        case setImgUrl = "set_img_url"
        case themeName = "theme_name"
    }
}

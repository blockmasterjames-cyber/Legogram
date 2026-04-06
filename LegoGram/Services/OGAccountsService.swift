import Foundation
import FirebaseFirestore

/// Manages the 10 OG/seed accounts that every new user automatically follows.
/// These accounts have real posts so new users never see an empty feed.
@MainActor
final class OGAccountsService {

    static let shared = OGAccountsService()
    private let db = Firestore.firestore()
    private init() {}

    static let ogAccounts: [(id: String, username: String, displayName: String, bio: String)] = [
        ("og-brickmaster99",       "brickmaster99",        "BrickMaster99",        "Official BrickFeed OG builder. Star Wars & UCS collector."),
        ("og-legolover-emma",      "legolover_emma",       "Emma Builds",          "Icons & Ideas enthusiast. Building dreams one brick at a time."),
        ("og-marvelfan-zoe",       "marvelfan_zoe",        "Zoe Marvel Bricks",    "Marvel Super Heroes collector. Wakanda Forever!"),
        ("og-citybuilder-max",     "citybuilder_max",      "Max City Builder",     "LEGO City is my world. Building the ultimate metropolis."),
        ("og-ideasfan-lily",       "ideasfan_lily",        "Lily Ideas Fan",       "Art + LEGO = life. Ideas & Art series lover."),
        ("og-ninjafan-jake",       "ninjafan_jake",        "Jake Ninjago Fan",     "Ninjago master builder since day one."),
        ("og-disneybuilder-sara",  "disneybuilder_sara",   "Sara Disney Builder",  "Disney magic in LEGO form. Castle collector."),
        ("og-technicpro-alex",     "technicpro_alex",      "Alex Technic Pro",     "Technic & supercar builds. Engineering with bricks."),
        ("og-botanicalkim",        "botanicalbuilder_kim", "Kim Botanical",        "LEGO Botanical Collection fan. Flowers that never wilt!"),
        ("og-speedkid-ryan",       "speedkid_ryan",        "Ryan Speed Kid",       "Speed Champions racer. Every car, every set.")
    ]

    /// OG posts — seed content with no earnings fields (points system used instead).
    static let ogPosts: [LegoPost] = [
        LegoPost(id: "og-post-001", userId: "og-brickmaster99", username: "brickmaster99",
                 imageURL: "", legoSetNumber: "75192", legoSetName: "Millennium Falcon",
                 description: "Took me 3 weeks but it was worth every brick!",
                 likeCount: 342, commentCount: 3,
                 buyLink: "https://www.lego.com/en-us/product/millennium-falcon-75192",
                 postedDate: Date().addingTimeInterval(-7200), tags: ["starwars", "ucs"]),

        LegoPost(id: "og-post-002", userId: "og-brickmaster99", username: "brickmaster99",
                 imageURL: "", legoSetNumber: "10307", legoSetName: "Eiffel Tower",
                 description: "10,001 pieces later and she stands tall! The most satisfying build ever.",
                 likeCount: 512, commentCount: 4,
                 buyLink: "https://www.lego.com/en-us/product/eiffel-tower-10307",
                 postedDate: Date().addingTimeInterval(-14400), tags: ["icons"]),

        LegoPost(id: "og-post-003", userId: "og-legolover-emma", username: "legolover_emma",
                 imageURL: "", legoSetNumber: "10300", legoSetName: "Back to the Future Time Machine",
                 description: "Classic! Every LEGO fan needs this one.",
                 likeCount: 218, commentCount: 2,
                 buyLink: "https://www.lego.com/en-us/product/back-to-the-future-time-machine-10300",
                 postedDate: Date().addingTimeInterval(-21600), tags: ["icons"]),

        LegoPost(id: "og-post-004", userId: "og-marvelfan-zoe", username: "marvelfan_zoe",
                 imageURL: "", legoSetNumber: "76215", legoSetName: "Black Panther",
                 description: "Wakanda Forever! This build is stunning on my shelf!",
                 likeCount: 411, commentCount: 2,
                 buyLink: "https://www.lego.com/en-us/product/black-panther-76215",
                 postedDate: Date().addingTimeInterval(-28800), tags: ["marvel"]),

        LegoPost(id: "og-post-005", userId: "og-citybuilder-max", username: "citybuilder_max",
                 imageURL: "", legoSetNumber: "60380", legoSetName: "Downtown",
                 description: "My LEGO city just got its best building yet!",
                 likeCount: 167, commentCount: 2,
                 buyLink: "https://www.lego.com/en-us/product/downtown-60380",
                 postedDate: Date().addingTimeInterval(-36000), tags: ["city"]),

        LegoPost(id: "og-post-006", userId: "og-ideasfan-lily", username: "ideasfan_lily",
                 imageURL: "", legoSetNumber: "21333", legoSetName: "Vincent van Gogh - The Starry Night",
                 description: "Art + LEGO = perfect combo. This masterpiece took 5 evenings!",
                 likeCount: 893, commentCount: 2,
                 buyLink: "https://www.lego.com/en-us/product/vincent-van-gogh-the-starry-night-21333",
                 postedDate: Date().addingTimeInterval(-43200), tags: ["ideas", "art"]),

        LegoPost(id: "og-post-007", userId: "og-ninjafan-jake", username: "ninjafan_jake",
                 imageURL: "", legoSetNumber: "71741", legoSetName: "NINJAGO City Gardens",
                 description: "The most detailed Ninjago set I've ever built! Worth every penny.",
                 likeCount: 634, commentCount: 5,
                 buyLink: "https://www.lego.com/en-us/product/ninjago-city-gardens-71741",
                 postedDate: Date().addingTimeInterval(-50400), tags: ["ninjago"]),

        LegoPost(id: "og-post-008", userId: "og-disneybuilder-sara", username: "disneybuilder_sara",
                 imageURL: "", legoSetNumber: "43222", legoSetName: "Disney Castle",
                 description: "Dreams do come true — in LEGO! Building this was pure magic.",
                 likeCount: 755, commentCount: 8,
                 buyLink: "https://www.lego.com/en-us/product/disney-castle-43222",
                 postedDate: Date().addingTimeInterval(-57600), tags: ["disney"]),

        LegoPost(id: "og-post-009", userId: "og-technicpro-alex", username: "technicpro_alex",
                 imageURL: "", legoSetNumber: "42143", legoSetName: "Ferrari Daytona SP3",
                 description: "The Ferrari Daytona SP3 is absolutely stunning. Technic at its finest!",
                 likeCount: 687, commentCount: 7,
                 buyLink: "https://www.lego.com/en-us/product/ferrari-daytona-sp3-42143",
                 postedDate: Date().addingTimeInterval(-64800), tags: ["technic"]),

        LegoPost(id: "og-post-010", userId: "og-botanicalkim", username: "botanicalbuilder_kim",
                 imageURL: "", legoSetNumber: "10313", legoSetName: "Wildflower Bouquet",
                 description: "Perfect desk decoration. These LEGO flowers never wilt!",
                 likeCount: 430, commentCount: 3,
                 buyLink: "https://www.lego.com/en-us/product/wildflower-bouquet-10313",
                 postedDate: Date().addingTimeInterval(-72000), tags: ["botanical"]),

        LegoPost(id: "og-post-011", userId: "og-brickmaster99", username: "brickmaster99",
                 imageURL: "", legoSetNumber: "76210", legoSetName: "Hulkbuster",
                 description: "Added this beast to my display shelf. Iron Man fans — this is a must buy!",
                 likeCount: 289, commentCount: 2,
                 buyLink: "https://www.lego.com/en-us/product/hulkbuster-76210",
                 postedDate: Date().addingTimeInterval(-79200), tags: ["marvel"]),

        LegoPost(id: "og-post-012", userId: "og-speedkid-ryan", username: "speedkid_ryan",
                 imageURL: "", legoSetNumber: "76918", legoSetName: "McLaren Solus GT & F1 LM",
                 description: "Two McLarens for the price of one set! Love Speed Champions.",
                 likeCount: 198, commentCount: 2,
                 buyLink: "https://www.lego.com/en-us/product/mclaren-solus-gt-mclaren-f1-lm-76918",
                 postedDate: Date().addingTimeInterval(-86400), tags: ["speedchampions"])
    ]

    static let ogUsernames: Set<String> = Set(ogAccounts.map { $0.username })

    func setupNewUser(userId: String) async {
        for account in Self.ogAccounts {
            PostStore.shared.followingUsernames.insert(account.username)
        }
        PostStore.shared.posts = Self.ogPosts

        for account in Self.ogAccounts {
            do {
                try await FirebaseService.shared.followUser(
                    currentUserId: userId,
                    targetUserId: account.id
                )
            } catch {
                print("[OGAccountsService] Could not follow \(account.username): \(error.localizedDescription)")
            }
        }
    }

    func loadOGPostsIfNeeded() {
        let store = PostStore.shared
        let hasRealPosts = store.posts.contains { !$0.id.hasPrefix("og-") }
        if store.posts.isEmpty || !hasRealPosts {
            let userPosts = store.posts.filter {
                !$0.id.hasPrefix("og-") && !$0.id.hasPrefix("preview-")
            }
            store.posts = userPosts + Self.ogPosts
        }
    }
}

import Foundation

/// Represents a single LEGO build post shared by a user.
/// Each post maps to a document in the Firestore "posts" collection.
struct LegoPost: Identifiable, Codable, Hashable {

    // MARK: - Identity
    var id: String
    var userId: String
    var username: String

    // MARK: - Photo / Video
    var imageURL: String
    var videoURL: String

    // MARK: - LEGO Set Info
    var legoSetNumber: String
    var legoSetName: String
    var description: String

    // MARK: - Engagement
    var likeCount: Int
    var commentCount: Int

    // MARK: - Shopping (affiliate earnings removed — replaced with points system)
    var buyLink: String

    // MARK: - Metadata
    var postedDate: Date
    var tags: [String]

    // MARK: - Custom Build
    var isCustomBuild: Bool
    var customBuildName: String

    // MARK: - Computed
    var isVideoPost: Bool { !videoURL.isEmpty }

    // MARK: - Firestore Field Keys
    enum CodingKeys: String, CodingKey {
        case id
        case userId         = "user_id"
        case username
        case imageURL       = "image_url"
        case videoURL       = "video_url"
        case legoSetNumber  = "lego_set_number"
        case legoSetName    = "lego_set_name"
        case description
        case likeCount      = "like_count"
        case commentCount   = "comment_count"
        case buyLink        = "buy_link"
        case postedDate     = "posted_date"
        case tags
        case isCustomBuild  = "is_custom_build"
        case customBuildName = "custom_build_name"
    }

    // MARK: - Custom Decoder (handles old Firestore docs that lack new fields)
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id              = try c.decode(String.self,   forKey: .id)
        userId          = try c.decode(String.self,   forKey: .userId)
        username        = try c.decode(String.self,   forKey: .username)
        imageURL        = try c.decode(String.self,   forKey: .imageURL)
        videoURL        = (try? c.decode(String.self, forKey: .videoURL)) ?? ""
        legoSetNumber   = try c.decode(String.self,   forKey: .legoSetNumber)
        legoSetName     = try c.decode(String.self,   forKey: .legoSetName)
        description     = try c.decode(String.self,   forKey: .description)
        likeCount       = try c.decode(Int.self,      forKey: .likeCount)
        commentCount    = try c.decode(Int.self,      forKey: .commentCount)
        buyLink         = (try? c.decode(String.self, forKey: .buyLink)) ?? ""
        postedDate      = try c.decode(Date.self,     forKey: .postedDate)
        tags            = (try? c.decode([String].self, forKey: .tags)) ?? []
        isCustomBuild   = (try? c.decode(Bool.self,   forKey: .isCustomBuild)) ?? false
        customBuildName = (try? c.decode(String.self, forKey: .customBuildName)) ?? ""
    }

    // MARK: - Convenience Init
    init(id: String, userId: String, username: String, imageURL: String,
         videoURL: String = "", legoSetNumber: String, legoSetName: String,
         description: String, likeCount: Int, commentCount: Int,
         buyLink: String = "", postedDate: Date, tags: [String],
         isCustomBuild: Bool = false, customBuildName: String = "") {
        self.id              = id
        self.userId          = userId
        self.username        = username
        self.imageURL        = imageURL
        self.videoURL        = videoURL
        self.legoSetNumber   = legoSetNumber
        self.legoSetName     = legoSetName
        self.description     = description
        self.likeCount       = likeCount
        self.commentCount    = commentCount
        self.buyLink         = buyLink
        self.postedDate      = postedDate
        self.tags            = tags
        self.isCustomBuild   = isCustomBuild
        self.customBuildName = customBuildName
    }
}

// MARK: - Placeholder / Preview
extension LegoPost {
    static let placeholder = LegoPost(
        id: "preview-post-001",
        userId: "preview-user-001",
        username: "brickmaster99",
        imageURL: "",
        videoURL: "",
        legoSetNumber: "75192",
        legoSetName: "Millennium Falcon",
        description: "Took me 3 weeks but it was worth every brick! 🚀",
        likeCount: 342,
        commentCount: 47,
        buyLink: "https://www.lego.com/en-us/product/millennium-falcon-75192",
        postedDate: Date(),
        tags: ["starwars", "ucs", "millennium falcon"]
    )
}

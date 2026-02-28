import Foundation
import FirebaseFirestore
import FirebaseStorage

/// FirebaseService handles all reading and writing to the cloud database (Firestore)
/// and cloud file storage (Firebase Storage).
///
/// Think of Firestore like a giant online filing cabinet where all the app's
/// posts, users, and LEGO set info is stored safely in the cloud.
final class FirebaseService: ObservableObject {

    // MARK: - Singleton
    /// One shared instance used across the whole app.
    static let shared = FirebaseService()

    // MARK: - Firebase References
    private let db      = Firestore.firestore()
    private let storage = Storage.storage()

    private init() {}

    // MARK: - Collection Names
    private enum Collection {
        static let users    = "users"
        static let posts    = "posts"
        static let legoSets = "lego_sets"
    }

    // =========================================================================
    // MARK: - User Operations
    // =========================================================================

    /// Fetches a user document from Firestore by their UID.
    /// - Parameter userId: The Firebase Auth UID.
    /// - Returns: A `User` object, or throws an error if not found.
    func fetchUser(userId: String) async throws -> User {
        let snapshot = try await db
            .collection(Collection.users)
            .document(userId)
            .getDocument()

        guard let data = snapshot.data() else {
            throw FirebaseServiceError.documentNotFound
        }
        return try decodeDocument(data: data, id: snapshot.documentID)
    }

    /// Saves (or updates) a user document in Firestore.
    /// - Parameter user: The `User` object to save.
    func saveUser(_ user: User) async throws {
        let data = try encodeModel(user)
        try await db
            .collection(Collection.users)
            .document(user.id)
            .setData(data, merge: true)
    }

    // =========================================================================
    // MARK: - Post Operations
    // =========================================================================

    /// Fetches the most recent posts for the home feed.
    /// - Parameter limit: Maximum number of posts to return (default 20).
    /// - Returns: An array of `LegoPost` objects sorted newest-first.
    func fetchFeedPosts(limit: Int = 20) async throws -> [LegoPost] {
        let snapshot = try await db
            .collection(Collection.posts)
            .order(by: "posted_date", descending: true)
            .limit(to: limit)
            .getDocuments()

        return try snapshot.documents.compactMap { doc in
            try decodeDocument(data: doc.data(), id: doc.documentID)
        }
    }

    /// Uploads a new post document to Firestore.
    /// - Parameter post: The `LegoPost` to publish.
    func publishPost(_ post: LegoPost) async throws {
        let data = try encodeModel(post)
        try await db
            .collection(Collection.posts)
            .document(post.id)
            .setData(data)
    }

    // =========================================================================
    // MARK: - LEGO Set Operations
    // =========================================================================

    /// Looks up an official LEGO set by its set number.
    /// - Parameter setNumber: e.g. "75192"
    /// - Returns: A `LegoSet` object, or nil if the set isn't in the database yet.
    func fetchLegoSet(setNumber: String) async throws -> LegoSet? {
        let snapshot = try await db
            .collection(Collection.legoSets)
            .whereField("set_number", isEqualTo: setNumber)
            .limit(to: 1)
            .getDocuments()

        guard let doc = snapshot.documents.first else { return nil }
        return try decodeDocument(data: doc.data(), id: doc.documentID)
    }

    // =========================================================================
    // MARK: - Storage Operations
    // =========================================================================

    /// Uploads a photo to Firebase Storage and returns the public download URL.
    /// - Parameters:
    ///   - imageData: Raw JPEG data of the image.
    ///   - path: Storage path, e.g. "posts/user123/photo.jpg".
    /// - Returns: The public download URL string.
    func uploadImage(imageData: Data, path: String) async throws -> String {
        let ref = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await ref.putDataAsync(imageData, metadata: metadata)
        let url = try await ref.downloadURL()
        return url.absoluteString
    }

    // =========================================================================
    // MARK: - Encode / Decode Helpers
    // =========================================================================

    private func encodeModel<T: Encodable>(_ model: T) throws -> [String: Any] {
        let data = try JSONEncoder().encode(model)
        guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw FirebaseServiceError.encodingFailed
        }
        return dict
    }

    private func decodeDocument<T: Decodable>(data: [String: Any], id: String) throws -> T {
        var mutableData = data
        mutableData["id"] = id
        let jsonData = try JSONSerialization.data(withJSONObject: mutableData)
        return try JSONDecoder().decode(T.self, from: jsonData)
    }
}

// MARK: - Errors
enum FirebaseServiceError: LocalizedError {
    case documentNotFound
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .documentNotFound: return "The requested document was not found."
        case .encodingFailed:   return "Failed to encode the data model."
        }
    }
}

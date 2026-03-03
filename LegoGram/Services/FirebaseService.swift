import Foundation

/// FirebaseService handles all reading and writing to the cloud database (Firestore)
/// and cloud file storage (Firebase Storage).
///
/// NOTE: Firebase has been temporarily removed. These are placeholder
/// implementations that print messages. Real Firebase integration will be
/// added back in Sprint 3.
final class FirebaseService: ObservableObject {

    // MARK: - Singleton
    static let shared = FirebaseService()

    private init() {
        print("[FirebaseService] Initialized (Firebase temporarily removed — Sprint 3 will restore it)")
    }

    // =========================================================================
    // MARK: - User Operations
    // =========================================================================

    func fetchUser(userId: String) async throws -> User {
        print("[FirebaseService] fetchUser – Firebase temporarily removed. userId: \(userId)")
        return User.placeholder
    }

    func saveUser(_ user: User) async throws {
        print("[FirebaseService] saveUser – Firebase temporarily removed. userId: \(user.id)")
    }

    // =========================================================================
    // MARK: - Post Operations
    // =========================================================================

    func fetchFeedPosts(limit: Int = 20) async throws -> [LegoPost] {
        print("[FirebaseService] fetchFeedPosts – Firebase temporarily removed.")
        return []
    }

    func publishPost(_ post: LegoPost) async throws {
        print("[FirebaseService] publishPost – Firebase temporarily removed. postId: \(post.id)")
    }

    // =========================================================================
    // MARK: - LEGO Set Operations
    // =========================================================================

    func fetchLegoSet(setNumber: String) async throws -> LegoSet? {
        print("[FirebaseService] fetchLegoSet – Firebase temporarily removed. setNumber: \(setNumber)")
        return nil
    }

    // =========================================================================
    // MARK: - Storage Operations
    // =========================================================================

    func uploadImage(imageData: Data, path: String) async throws -> String {
        print("[FirebaseService] uploadImage – Firebase temporarily removed. path: \(path)")
        return ""
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

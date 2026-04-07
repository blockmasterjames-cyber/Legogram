import Foundation
import FirebaseAuth

// MARK: - Direct Message Models (Sprint 5 — Feature 11)

struct DMMessage: Identifiable, Codable {
    let id: String
    let senderId: String
    let senderUsername: String
    let text: String
    let sentDate: Date

    var isFromCurrentUser: Bool { senderId == Auth.auth().currentUser?.uid }

    var timeAgo: String {
        let diff = Date().timeIntervalSince(sentDate)
        switch diff {
        case ..<60:        return "Just now"
        case ..<3600:      return "\(Int(diff / 60))m ago"
        case ..<86400:     return "\(Int(diff / 3600))h ago"
        default:           return "\(Int(diff / 86400))d ago"
        }
    }
}

struct DMConversation: Identifiable, Codable {
    let id: String
    let otherUserId: String
    let otherUsername: String
    var messages: [DMMessage]

    var lastMessagePreview: String {
        messages.last?.text ?? "No messages yet"
    }

    var lastMessageDate: Date {
        messages.last?.sentDate ?? Date()
    }
}

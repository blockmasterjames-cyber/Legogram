import Foundation

// MARK: - Direct Message Models (Sprint 5 — Feature 11)

/// A single message inside a DM conversation.
struct DMMessage: Identifiable, Codable {
    let id: String
    let senderId: String
    let senderUsername: String
    let text: String
    let sentDate: Date

    /// True when this message was sent by the current user.
    var isFromCurrentUser: Bool { senderId == "current-user" }

    /// Human-readable "time ago" label.
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

/// One conversation thread between the current user and another builder.
struct DMConversation: Identifiable, Codable {
    let id: String
    let otherUserId: String
    let otherUsername: String
    var messages: [DMMessage]

    /// Most recent message text for the conversation list preview.
    var lastMessagePreview: String {
        messages.last?.text ?? "No messages yet"
    }

    /// Date of the most recent message.
    var lastMessageDate: Date {
        messages.last?.sentDate ?? Date()
    }
}

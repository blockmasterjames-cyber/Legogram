import SwiftUI

// MARK: - DM Store (Sprint 5 — Feature 11)

/// Manages all Direct Message conversations and messages for the current user.
/// Sprint 9: Removed all fake/seed conversations. Starts empty.
@MainActor
final class DMStore: ObservableObject {

    static let shared = DMStore()

    @Published var conversations: [DMConversation] = []

    private init() {}

    // MARK: - Send Message

    /// Appends a new (filtered) message to the conversation and moves the conversation to the top.
    func sendMessage(text: String, in conversationId: String) {
        let filtered = BadWordFilter.filter(text.trimmingCharacters(in: .whitespaces))
        guard !filtered.isEmpty else { return }

        let msg = DMMessage(
            id: UUID().uuidString,
            senderId: UserSession.shared.uid,
            senderUsername: UserSession.shared.username,
            text: filtered,
            sentDate: Date()
        )

        guard let idx = conversations.firstIndex(where: { $0.id == conversationId }) else { return }
        conversations[idx].messages.append(msg)

        // Move most-recently-active conversation to top
        let updated = conversations.remove(at: idx)
        conversations.insert(updated, at: 0)
    }

    // MARK: - Start / Get Conversation

    /// Returns the existing conversation with a user or creates a new one.
    func conversation(with username: String, userId: String = "other-user") -> DMConversation {
        if let existing = conversations.first(where: { $0.otherUsername == username }) {
            return existing
        }
        let newConv = DMConversation(
            id: UUID().uuidString,
            otherUserId: userId,
            otherUsername: username,
            messages: []
        )
        conversations.append(newConv)
        return newConv
    }
}

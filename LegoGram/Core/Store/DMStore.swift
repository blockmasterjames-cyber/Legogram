import SwiftUI

// MARK: - DM Store (Sprint 5 — Feature 11)

/// Manages all Direct Message conversations and messages for the current user.
@MainActor
final class DMStore: ObservableObject {

    static let shared = DMStore()

    @Published var conversations: [DMConversation] = DMStore.seedConversations

    private init() {}

    // MARK: - Send Message

    /// Appends a new (filtered) message to the conversation and moves the conversation to the top.
    func sendMessage(text: String, in conversationId: String) {
        let filtered = BadWordFilter.filter(text.trimmingCharacters(in: .whitespaces))
        guard !filtered.isEmpty else { return }

        let msg = DMMessage(
            id: UUID().uuidString,
            senderId: "current-user",
            senderUsername: "blockmasterjames",
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

    // MARK: - Seed Conversations

    static let seedConversations: [DMConversation] = [
        DMConversation(
            id: "conv-001",
            otherUserId: "u2",
            otherUsername: "legolover_emma",
            messages: [
                DMMessage(id: "m1", senderId: "u2", senderUsername: "legolover_emma",
                          text: "Hey! Love your Millennium Falcon build!",
                          sentDate: Date().addingTimeInterval(-7200)),
                DMMessage(id: "m2", senderId: "current-user", senderUsername: "blockmasterjames",
                          text: "Thanks! It took 3 weeks but was totally worth it 🚀",
                          sentDate: Date().addingTimeInterval(-7000)),
                DMMessage(id: "m3", senderId: "u2", senderUsername: "legolover_emma",
                          text: "Do you recommend the UCS version over the regular one?",
                          sentDate: Date().addingTimeInterval(-6800)),
            ]
        ),
        DMConversation(
            id: "conv-002",
            otherUserId: "u3",
            otherUsername: "technicjane",
            messages: [
                DMMessage(id: "m4", senderId: "u3", senderUsername: "technicjane",
                          text: "Did you see the new Technic Ferrari? It looks amazing!",
                          sentDate: Date().addingTimeInterval(-86400)),
                DMMessage(id: "m5", senderId: "current-user", senderUsername: "blockmasterjames",
                          text: "Yes! Already ordered mine 🏎️",
                          sentDate: Date().addingTimeInterval(-80000)),
            ]
        ),
        DMConversation(
            id: "conv-003",
            otherUserId: "u4",
            otherUsername: "hogwartsbuilder",
            messages: [
                DMMessage(id: "m6", senderId: "u4", senderUsername: "hogwartsbuilder",
                          text: "Which Harry Potter set should I get first?",
                          sentDate: Date().addingTimeInterval(-172800)),
            ]
        ),
    ]
}

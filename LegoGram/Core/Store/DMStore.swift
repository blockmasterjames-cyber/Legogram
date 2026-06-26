import SwiftUI
import FirebaseFirestore

// MARK: - DM Store (Sprint 5 — Feature 11)

/// Manages all Direct Message conversations and messages for the current user.
/// Backed by Firestore — `loadFromFirestore` fetches conversations + every
/// message in each conversation so the thread view can render without any
/// further round-trips. Local writes still go through `sendMessage` for an
/// instant UI update; the Firestore write is performed by FirebaseService.
@MainActor
final class DMStore: ObservableObject {

    static let shared = DMStore()

    @Published var conversations: [DMConversation] = []
    @Published var isLoading: Bool = false

    private let db = Firestore.firestore()
    private init() {}

    // MARK: - Firestore Loading

    /// Fetches every conversation the current user participates in, plus every
    /// message in each conversation, and publishes them to `conversations`.
    /// Safe to call repeatedly — replaces the current array.
    func loadFromFirestore(currentUserId: String) async {
        guard !currentUserId.isEmpty else {
            print("[DMStore] loadFromFirestore aborted — empty currentUserId")
            return
        }
        isLoading = true
        defer { isLoading = false }

        do {
            let convSnap = try await db.collection("conversations")
                .whereField("participant_ids", arrayContains: currentUserId)
                .order(by: "last_message_date", descending: true)
                .getDocuments()

            var loaded: [DMConversation] = []
            for doc in convSnap.documents {
                let data = doc.data()
                let participantIds = data["participant_ids"] as? [String] ?? []
                let participantUsernames = data["participant_usernames"] as? [String] ?? []
                guard let otherIdx = participantIds.firstIndex(where: { $0 != currentUserId }) else { continue }
                let otherUserId   = participantIds[otherIdx]
                let otherUsername = participantUsernames.indices.contains(otherIdx)
                    ? participantUsernames[otherIdx]
                    : participantUsernames.first(where: { $0 != UserSession.shared.username }) ?? ""

                let msgsSnap = try await db.collection("conversations").document(doc.documentID)
                    .collection("messages")
                    .order(by: "sent_date")
                    .getDocuments()
                let messages: [DMMessage] = msgsSnap.documents.map { mDoc in
                    let mData = mDoc.data()
                    return DMMessage(
                        id: mDoc.documentID,
                        senderId: mData["sender_id"] as? String ?? "",
                        senderUsername: mData["sender_username"] as? String ?? "",
                        text: mData["text"] as? String ?? "",
                        sentDate: (mData["sent_date"] as? Timestamp)?.dateValue() ?? Date()
                    )
                }

                loaded.append(DMConversation(
                    id: doc.documentID,
                    otherUserId: otherUserId,
                    otherUsername: otherUsername,
                    messages: messages
                ))
            }
            conversations = loaded
            print("[DMStore] Loaded \(loaded.count) conversations from Firestore.")
        } catch {
            print("[DMStore] loadFromFirestore failed: \(error.localizedDescription)")
        }
    }

    /// Fetches the messages subcollection for a SINGLE conversation and merges
    /// them into the locally-held conversation.
    ///
    /// Why this exists: opening a thread directly from a profile / New Message
    /// builds the local `DMConversation` with `messages: []` (the bulk
    /// `loadFromFirestore` only runs from the Messages list). Without this, a
    /// conversation that already has history in Firestore renders empty. Calling
    /// this on thread-open pulls that history regardless of whether the list was
    /// ever visited this session.
    ///
    /// Merge strategy: Firestore is the source of truth for everything that has
    /// been persisted. Local message ids are assigned independently of the
    /// Firestore document ids, so we can't dedupe purely by id; instead we keep
    /// the fetched set and re-append only local messages that are NEWER than the
    /// newest fetched message (a just-sent message whose Firestore write is
    /// still in flight), which avoids both dropping in-flight sends and
    /// double-showing already-persisted ones.
    func loadMessages(for conversationId: String) async {
        guard !conversationId.isEmpty else { return }
        do {
            let msgsSnap = try await db.collection("conversations").document(conversationId)
                .collection("messages")
                .order(by: "sent_date")
                .getDocuments()

            let fetched: [DMMessage] = msgsSnap.documents.map { mDoc in
                let mData = mDoc.data()
                return DMMessage(
                    id: mDoc.documentID,
                    senderId: mData["sender_id"] as? String ?? "",
                    senderUsername: mData["sender_username"] as? String ?? "",
                    text: mData["text"] as? String ?? "",
                    sentDate: (mData["sent_date"] as? Timestamp)?.dateValue() ?? Date()
                )
            }

            guard let idx = conversations.firstIndex(where: { $0.id == conversationId }) else {
                // Conversation isn't locally known yet — nothing to merge into.
                return
            }

            let existing = conversations[idx].messages
            let fetchedIds = Set(fetched.map(\.id))
            let newestFetchedDate = fetched.last?.sentDate ?? .distantPast
            let inFlight = existing.filter {
                !fetchedIds.contains($0.id) && $0.sentDate > newestFetchedDate
            }

            var merged = fetched + inFlight
            merged.sort { $0.sentDate < $1.sentDate }
            conversations[idx].messages = merged
        } catch {
            print("[DMStore] loadMessages(for:) failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Send Message

    /// Appends a new (filtered) message to the conversation locally for an
    /// instant UI update, then writes it to Firestore. Moves the conversation
    /// to the top of the list.
    func sendMessage(text: String, in conversationId: String) {
        print("🔵DMDEBUG [store] sendMessage called — conversationId=\(conversationId), text=\(text)")
        let filtered = BadWordFilter.filter(text.trimmingCharacters(in: .whitespaces))
        print("🔵DMDEBUG [store] filtered text=\(filtered) isEmpty=\(filtered.isEmpty)")
        guard !filtered.isEmpty else { return }

        let senderId = UserSession.shared.uid
        let senderUsername = UserSession.shared.username

        let msg = DMMessage(
            id: UUID().uuidString,
            senderId: senderId,
            senderUsername: senderUsername,
            text: filtered,
            sentDate: Date()
        )

        print("🔵DMDEBUG [store] looking for conversationId=\(conversationId) — store has ids: \(conversations.map { $0.id })")
        guard let idx = conversations.firstIndex(where: { $0.id == conversationId }) else {
            print("🔵DMDEBUG [store] ❌ GUARD FAILED — no conversation with id=\(conversationId) — DROPPING MESSAGE")
            return
        }
        conversations[idx].messages.append(msg)
        print("🔵DMDEBUG [store] ✅ appending message to conv id=\(conversationId) — messages count now=\(conversations[idx].messages.count)")

        // Move most-recently-active conversation to top
        let updated = conversations.remove(at: idx)
        conversations.insert(updated, at: 0)

        // Persist to Firestore so the message survives reload and is visible
        // to the other participant.
        Task {
            print("🔵DMDEBUG [store] firestore write starting for convId=\(conversationId)")
            do {
                try await FirebaseService.shared.sendDMMessage(
                    conversationId: conversationId,
                    senderId: senderId,
                    senderUsername: senderUsername,
                    text: filtered
                )
                print("🔵DMDEBUG [store] firestore write OK")
            } catch {
                print("🔵DMDEBUG [store] firestore write ERROR: \(error)")
                print("[DMStore] Failed to persist message to Firestore: \(error.localizedDescription)")
            }
        }
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

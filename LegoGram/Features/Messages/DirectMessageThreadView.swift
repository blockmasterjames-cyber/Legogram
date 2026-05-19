import SwiftUI

/// The message thread view for a DM conversation.
/// Sprint 5 — Feature 11.
/// Current user's messages on the right in LEGO red, other person's on left in dark gray.
/// Bad word filter applied to all outgoing messages.
struct DirectMessageThreadView: View {

    let conversation: DMConversation

    @ObservedObject private var dmStore = DMStore.shared
    @ObservedObject private var postStore = PostStore.shared
    @State private var messageText = ""
    @State private var showReportConfirm = false
    @State private var showBlockConfirm  = false
    @State private var lastReportReason = ""
    @FocusState private var inputFocused: Bool

    private var liveConversation: DMConversation {
        dmStore.conversations.first(where: { $0.id == conversation.id }) ?? conversation
    }

    var body: some View {
        ZStack {
            Color.darkBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Messages scroll area
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(liveConversation.messages) { message in
                                MessageBubble(
                                    message: message,
                                    canReport: !message.isFromCurrentUser,
                                    onReport: { reason in submitMessageReport(message: message, reason: reason) }
                                )
                                .id(message.id)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .onAppear {
                        scrollToBottom(proxy: proxy)
                    }
                    .onChange(of: liveConversation.messages.count) { _, _ in
                        withAnimation { scrollToBottom(proxy: proxy) }
                    }
                    // Tap to dismiss keyboard
                    .onTapGesture { hideKeyboard() }
                }

                // Input bar
                inputBar
            }
        }
        .navigationTitle("@\(conversation.otherUsername)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.cardBackground, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Section("Report this conversation") {
                        Button("Inappropriate content") { submitThreadReport(reason: "Inappropriate content") }
                        Button("Bullying or harassment") { submitThreadReport(reason: "Bullying or harassment") }
                        Button("Spam") { submitThreadReport(reason: "Spam") }
                    }
                    Section {
                        Button(role: .destructive) {
                            showBlockConfirm = true
                        } label: {
                            Label("Block @\(conversation.otherUsername)",
                                  systemImage: "hand.raised.fill")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.legoYellow)
                }
            }
        }
        .alert("Report submitted", isPresented: $showReportConfirm) {
            Button("OK") {}
        } message: {
            Text("Thanks for keeping BrickFeed safe! Our team will review this report (reason: \(lastReportReason)) within 24 hours.")
        }
        .alert("Block @\(conversation.otherUsername)?", isPresented: $showBlockConfirm) {
            Button("Block", role: .destructive) {
                postStore.blockUser(userId: conversation.otherUserId,
                                    username: conversation.otherUsername,
                                    reason: "Blocked from DM thread")
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All of @\(conversation.otherUsername)'s messages, posts, and comments will be hidden immediately.")
        }
    }

    // MARK: - Report Helpers

    private func submitThreadReport(reason: String) {
        lastReportReason = reason
        showReportConfirm = true
        Task {
            let uid = UserSession.shared.uid
            let reporterUsername = UserSession.shared.username
            guard !uid.isEmpty else { return }
            try? await FirebaseService.shared.reportContent(
                contentType:        "dm_thread",
                contentId:          conversation.id,
                reportedUserId:     conversation.otherUserId,
                reportedUsername:   conversation.otherUsername,
                reportedBy:         uid,
                reportedByUsername: reporterUsername,
                reason:             reason,
                contextText:        liveConversation.messages.last?.text ?? ""
            )
        }
    }

    private func submitMessageReport(message: DMMessage, reason: String) {
        lastReportReason = reason
        showReportConfirm = true
        Task {
            let uid = UserSession.shared.uid
            let reporterUsername = UserSession.shared.username
            guard !uid.isEmpty else { return }
            try? await FirebaseService.shared.reportContent(
                contentType:        "dm_message",
                contentId:          message.id,
                reportedUserId:     message.senderId,
                reportedUsername:   message.senderUsername,
                reportedBy:         uid,
                reportedByUsername: reporterUsername,
                reason:             reason,
                contextText:        message.text
            )
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastId = liveConversation.messages.last?.id {
            proxy.scrollTo(lastId, anchor: .bottom)
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Type a message...", text: $messageText, axis: .vertical)
                .lineLimit(4)
                .foregroundColor(.lightText)
                .font(.legoBody)
                .padding(12)
                .background(Color.cardBackground)
                .cornerRadius(20)
                .focused($inputFocused)
                .onSubmit { sendMessage() }

            Button { sendMessage() } label: {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(messageText.trimmingCharacters(in: .whitespaces).isEmpty
                                ? Color.legoRed.opacity(0.4) : Color.legoRed)
                    .clipShape(Circle())
            }
            .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            Color.darkBackground.opacity(0.97)
                .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: -3)
        )
    }

    private func sendMessage() {
        let trimmed = messageText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        dmStore.sendMessage(text: trimmed, in: conversation.id)
        messageText = ""
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: DMMessage
    var canReport: Bool = false
    var onReport: ((String) -> Void)? = nil

    var body: some View {
        HStack {
            if message.isFromCurrentUser { Spacer(minLength: 60) }

            VStack(alignment: message.isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.legoBody)
                    .foregroundColor(message.isFromCurrentUser ? .white : .lightText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(message.isFromCurrentUser ? Color.legoRed : Color.cardBackground)
                    .cornerRadius(18, corners: message.isFromCurrentUser
                                  ? [.topLeft, .topRight, .bottomLeft]
                                  : [.topLeft, .topRight, .bottomRight])
                    .contextMenu {
                        if canReport, let onReport {
                            Section("Report this message") {
                                Button("Inappropriate content") { onReport("Inappropriate content") }
                                Button("Bullying or harassment") { onReport("Bullying or harassment") }
                                Button("Spam") { onReport("Spam") }
                            }
                        }
                    }

                Text(message.timeAgo)
                    .font(.legoCaption)
                    .foregroundColor(.secondaryText)
                    .padding(.horizontal, 4)
            }

            if !message.isFromCurrentUser { Spacer(minLength: 60) }
        }
    }
}

// MARK: - Rounded Corner Helper

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    NavigationStack {
        DirectMessageThreadView(conversation: DMConversation(
            id: "preview-conv",
            otherUserId: "other-user",
            otherUsername: "brickmaster99",
            messages: [
                DMMessage(id: "1", senderId: "me", senderUsername: "you",
                          text: "Hey! Love your Falcon build! 🚀", sentDate: Date()),
                DMMessage(id: "2", senderId: "other-user", senderUsername: "brickmaster99",
                          text: "Thanks! Took 3 weeks 😄", sentDate: Date())
            ]
        ))
    }
}

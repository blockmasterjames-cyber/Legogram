import SwiftUI

/// The Direct Messages entry point.
/// Kid Safe Mode ON → friendly block popup
/// Kid Safe Mode OFF → DM list with compose button (no age gate)
struct DirectMessageListView: View {

    @AppStorage("settings_kidSafeMode") private var kidSafeMode = false

    @ObservedObject private var dmStore = DMStore.shared
    @ObservedObject private var appState = AppState.shared
    @Environment(\.dismiss) private var dismiss

    @State private var showingNewMessage = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                if kidSafeMode {
                    kidSafeModeBlockView
                } else {
                    conversationList
                }
            }
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.cardBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.legoYellow)
                    }
                }

                if !kidSafeMode {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingNewMessage = true
                        } label: {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 18))
                                .foregroundColor(.legoYellow)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingNewMessage) {
                NewMessageView()
            }
        }
        .task { await loadConversations() }
    }

    private func loadConversations() async {
        let uid = UserSession.shared.uid
        guard !uid.isEmpty else { return }
        await dmStore.loadFromFirestore(currentUserId: uid)
    }

    // MARK: - Kid Safe Mode Block

    private var kidSafeModeBlockView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 64))
                .foregroundColor(.legoYellow)

            VStack(spacing: 10) {
                Text("Direct Messages Off")
                    .font(.legoScreenTitle)
                    .foregroundColor(.lightText)
                    .multilineTextAlignment(.center)

                Text("Direct Messages are turned off in Kid Safe Mode.\n\nAsk a parent or guardian to turn off Kid Safe Mode in Settings if you are old enough.")
                    .font(.legoBody)
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            VStack(spacing: 12) {
                Button { dismiss() } label: {
                    Text("Close")
                        .font(.legoCardTitle)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.cardBackground)
                        .foregroundColor(.lightText)
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.secondaryText, lineWidth: 1))
                }

                Button {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        AppState.shared.selectedTab = .profile
                        AppState.shared.openSettings = true
                    }
                } label: {
                    Text("Go To Settings")
                        .font(.legoCardTitle)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.legoYellow)
                        .foregroundColor(.darkBackground)
                        .cornerRadius(14)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .padding()
    }

    // MARK: - Conversation List

    private var conversationList: some View {
        Group {
            if dmStore.conversations.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 64)).foregroundColor(.secondaryText)
                    Text("No messages yet")
                        .font(.legoCardTitle).foregroundColor(.lightText)
                    Text("Tap the ✏️ button above to start a conversation!")
                        .font(.legoBody).foregroundColor(.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button {
                        showingNewMessage = true
                    } label: {
                        Label("Start a Conversation", systemImage: "square.and.pencil")
                            .font(.legoCardTitle)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.legoYellow)
                            .foregroundColor(.darkBackground)
                            .cornerRadius(14)
                    }
                    .padding(.horizontal, 40)
                    Spacer()
                }
            } else {
                List {
                    ForEach(dmStore.conversations) { conversation in
                        NavigationLink(destination: DirectMessageThreadView(conversation: conversation)) {
                            ConversationRow(conversation: conversation)
                        }
                        .listRowBackground(Color.cardBackground)
                    }
                }
                .listStyle(.plain)
                .background(Color.darkBackground)
                .scrollContentBackground(.hidden)
            }
        }
    }
}

// MARK: - Conversation Row

struct ConversationRow: View {
    let conversation: DMConversation

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.legoRed)
                .frame(width: 48, height: 48)
                .overlay(
                    Text(String(conversation.otherUsername.prefix(1)).uppercased())
                        .font(.legoCardTitle).foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text("@\(conversation.otherUsername)")
                    .font(.legoCardTitle).foregroundColor(.lightText)
                Text(conversation.lastMessagePreview)
                    .font(.legoBody).foregroundColor(.secondaryText)
                    .lineLimit(1)
            }

            Spacer()

            Text(conversation.lastMessageDate.timeAgoShort)
                .font(.legoCaption).foregroundColor(.secondaryText)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Date Extension

private extension Date {
    var timeAgoShort: String {
        let diff = Date().timeIntervalSince(self)
        switch diff {
        case ..<60:        return "now"
        case ..<3600:      return "\(Int(diff / 60))m"
        case ..<86400:     return "\(Int(diff / 3600))h"
        default:           return "\(Int(diff / 86400))d"
        }
    }
}

#Preview {
    DirectMessageListView()
}

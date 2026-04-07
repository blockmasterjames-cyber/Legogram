import SwiftUI
import WebKit

/// The Settings screen — accessible from the gear icon on the Profile tab.
struct SettingsView: View {

    @Environment(\.dismiss) private var dismiss

    @AppStorage("settings_kidSafeMode")    private var kidSafeMode:     Bool = true
    @AppStorage("settings_notifications") private var notificationsOn:  Bool = true
    @AppStorage("dm_ageVerified")          private var ageVerified:      Bool = false

    @ObservedObject private var userSession = UserSession.shared

    @State private var showingSignOutConfirm    = false
    @State private var showingDeleteConfirm     = false
    @State private var showingDeleteFinalConfirm = false
    @State private var isDeletingAccount        = false
    @State private var deleteError: String?

    @State private var showingPrivacyPolicy       = false
    @State private var showingTermsOfService      = false
    @State private var showingParentalApproval    = false

    private var isKidAccount: Bool {
        userSession.currentUser?.isKidAccount ?? false
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                if isDeletingAccount {
                    VStack(spacing: 20) {
                        ProgressView().tint(.legoYellow).scaleEffect(1.5)
                        Text("Deleting your account…")
                            .font(.legoBody).foregroundColor(.secondaryText)
                        Text("This may take a moment. Please don't close the app.")
                            .font(.legoCaption).foregroundColor(.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {

                            kidSafetySection
                            accountSection
                            preferencesSection
                            legalSection
                            accountActionsSection

                            Text("BrickFeed · v1.0.0")
                                .font(.legoCaption)
                                .foregroundColor(.secondaryText)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 4)

                            Color.clear.frame(height: 80)
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .navigationTitle("Settings")
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
            }
            .sheet(isPresented: $showingParentalApproval) {
                ParentalApprovalView(kidSafeMode: $kidSafeMode)
            }
            .alert("Sign Out", isPresented: $showingSignOutConfirm) {
                Button("Sign Out", role: .destructive) { performSignOut() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to sign out of BrickFeed?")
            }
            .alert("Delete Account", isPresented: $showingDeleteConfirm) {
                Button("Yes, Delete My Account", role: .destructive) {
                    showingDeleteFinalConfirm = true
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete your account, all your posts, and all your data. This cannot be undone!")
            }
            .alert("Final Confirmation", isPresented: $showingDeleteFinalConfirm) {
                Button("Delete Forever", role: .destructive) { performDeleteAccount() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you absolutely sure? Your account and all data will be gone forever.")
            }
            .alert("Error", isPresented: .init(
                get: { deleteError != nil },
                set: { if !$0 { deleteError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(deleteError ?? "")
            }
            .sheet(isPresented: $showingPrivacyPolicy) {
                SafariWebView(url: URL(string: "https://blockmasterjames-cyber.github.io/brickfeed-legal/privacy.html")!)
            }
            .sheet(isPresented: $showingTermsOfService) {
                SafariWebView(url: URL(string: "https://blockmasterjames-cyber.github.io/brickfeed-legal/terms.html")!)
            }
        }
    }

    // MARK: - Kid Safety Section

    private var kidSafetySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("KID SAFETY")
                .font(.legoCaption).foregroundColor(.secondaryText).padding(.horizontal)

            VStack(spacing: 0) {
                // Kid Safe Mode toggle — under-13 requires parental approval to turn OFF
                alignedToggleRow(
                    label: "Kid Safe Mode",
                    icon: "shield.checkmark.fill",
                    tint: .successGreen,
                    isOn: Binding(
                        get: { kidSafeMode },
                        set: { newValue in
                            if !newValue && isKidAccount {
                                showingParentalApproval = true
                            } else {
                                kidSafeMode = newValue
                            }
                        }
                    ),
                    highlighted: kidSafeMode
                )

                Divider()
                    .background(Color.secondaryText.opacity(0.2))
                    .padding(.horizontal, 16)

                // Limit DMs — age-gated direct messages
                alignedToggleRow(
                    label: "Limit Direct Messages",
                    icon: "message.badge.fill",
                    tint: .legoYellow,
                    isOn: Binding(
                        get: { !ageVerified },
                        set: { newValue in ageVerified = !newValue }
                    ),
                    highlighted: false
                )

                Divider()
                    .background(Color.secondaryText.opacity(0.2))
                    .padding(.horizontal, 16)

                // Bad Word Filter — always ON, display as disabled toggle
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: "text.badge.xmark")
                        .font(.system(size: 18))
                        .foregroundColor(.successGreen)
                        .frame(width: 24)
                    Text("Bad Word Filter")
                        .font(.legoBody)
                        .foregroundColor(.lightText)
                    Spacer()
                    Toggle("", isOn: .constant(true))
                        .tint(.successGreen)
                        .labelsHidden()
                        .disabled(true)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .background(Color.cardBackground)
            .cornerRadius(12)

            if isKidAccount && kidSafeMode {
                infoRow(icon: "lock.shield.fill", color: .successGreen,
                        text: "Kid Safe Mode is required for your account. A parent must approve turning it off.")
            } else {
                infoRow(icon: "info.circle", color: .legoYellow,
                        text: kidSafeMode
                              ? "Kid Safe Mode is ON — only verified kid-friendly content is shown."
                              : "Turn on Kid Safe Mode to limit content to verified kid-friendly posts.")
            }

            infoRow(icon: "text.badge.xmark", color: .successGreen,
                    text: "Bad Word Filter is always ON — inappropriate words are replaced with *** automatically.")
        }
        .padding(.horizontal)
    }

    /// A consistently-aligned toggle row with icon, label left and toggle right.
    private func alignedToggleRow(
        label: String,
        icon: String,
        tint: Color,
        isOn: Binding<Bool>,
        highlighted: Bool
    ) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(tint)
                .frame(width: 24)
            Text(label)
                .font(.legoBody)
                .foregroundColor(.lightText)
            Spacer()
            Toggle("", isOn: isOn)
                .tint(tint)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(highlighted ? tint.opacity(0.06) : Color.clear)
    }

    // MARK: - Account Section

    private var accountSection: some View {
        settingsSection("Account") {
            labelRow(label: "Display Name",
                     value: userSession.currentUser?.displayName ?? "", icon: "person.fill")
            labelRow(label: "Username",
                     value: "@\(userSession.currentUser?.username ?? "")", icon: "at")
        }
    }

    // MARK: - Preferences Section

    private var preferencesSection: some View {
        settingsSection("Preferences") {
            toggleRow(label: "Push Notifications", icon: "bell.fill",
                      tint: .legoYellow, isOn: $notificationsOn)
                .onChange(of: notificationsOn) { _, newValue in
                    if newValue {
                        Task { await NotificationManager.shared.requestPermission() }
                    }
                }
        }
    }

    // MARK: - Legal Section

    private var legalSection: some View {
        settingsSection("Legal") {
            actionRow(label: "Privacy Policy", icon: "hand.raised.fill", color: .legoYellow) {
                showingPrivacyPolicy = true
            }
            actionRow(label: "Terms of Service", icon: "doc.text.fill", color: .legoYellow) {
                showingTermsOfService = true
            }
        }
    }

    // MARK: - Account Actions Section

    private var accountActionsSection: some View {
        settingsSection("Account Actions") {
            actionRow(label: "Sign Out", icon: "arrow.right.square.fill", color: .legoRed) {
                showingSignOutConfirm = true
            }
            actionRow(label: "Delete My Account", icon: "trash.fill", color: .red) {
                showingDeleteConfirm = true
            }
        }
    }

    // MARK: - Section Builder

    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.legoCaption).foregroundColor(.secondaryText).padding(.horizontal)
            VStack(spacing: 8) { content() }
        }
        .padding(.horizontal)
    }

    // MARK: - Row Helpers

    private func labelRow(label: String, value: String, icon: String) -> some View {
        HStack {
            Label(label, systemImage: icon).font(.legoBody).foregroundColor(.lightText)
            Spacer()
            Text(value).font(.legoBody).foregroundColor(.secondaryText)
        }
        .padding(.horizontal).padding(.vertical, 14)
        .background(Color.cardBackground).cornerRadius(12)
    }

    private func infoRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundColor(color).font(.system(size: 16))
            Text(text).font(.legoCaption).foregroundColor(.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal).padding(.vertical, 10)
        .background(Color.cardBackground).cornerRadius(12)
    }

    private func actionRow(label: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon).foregroundColor(color)
                Text(label).font(.legoBody).foregroundColor(color)
                Spacer()
                Image(systemName: "chevron.right").font(.legoCaption).foregroundColor(.secondaryText)
            }
            .padding(.horizontal).padding(.vertical, 14)
            .background(Color.cardBackground).cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    private func toggleRow(label: String, icon: String, tint: Color, isOn: Binding<Bool>) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(tint)
                .frame(width: 24)
            Text(label)
                .font(.legoBody)
                .foregroundColor(.lightText)
            Spacer()
            Toggle("", isOn: isOn)
                .tint(tint)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.cardBackground)
        .cornerRadius(12)
    }

    // MARK: - Sign Out

    private func performSignOut() {
        UserDefaults.standard.removeObject(forKey: "profile_displayName")
        UserDefaults.standard.removeObject(forKey: "profile_username")
        UserDefaults.standard.removeObject(forKey: "profile_bio")
        UserDefaults.standard.removeObject(forKey: "settings_kidSafeMode")
        UserDefaults.standard.removeObject(forKey: "settings_notifications")
        UserDefaults.standard.removeObject(forKey: "dm_ageVerified")

        UserSession.shared.clear()
        PostStore.shared.followingUsernames.removeAll()
        PostStore.shared.posts.removeAll()

        do {
            try AuthService.shared.signOut()
            dismiss()
        } catch {
            print("[SettingsView] Firebase signOut error: \(error.localizedDescription)")
        }
    }

    // MARK: - Delete Account

    private func performDeleteAccount() {
        guard let userId = AuthService.shared.userId else { return }
        isDeletingAccount = true

        Task {
            do {
                try await FirebaseService.shared.deleteAccount(userId: userId)

                // Clean up local state
                await MainActor.run {
                    UserDefaults.standard.removeObject(forKey: "profile_displayName")
                    UserDefaults.standard.removeObject(forKey: "profile_username")
                    UserDefaults.standard.removeObject(forKey: "profile_bio")
                    UserDefaults.standard.removeObject(forKey: "settings_kidSafeMode")
                    UserDefaults.standard.removeObject(forKey: "dm_ageVerified")
                    UserDefaults.standard.removeObject(forKey: "hasSeenOnboarding")

                    UserSession.shared.clear()
                    PostStore.shared.posts.removeAll()
                    PostStore.shared.followingUsernames.removeAll()

                    AuthService.shared.isSignedIn = false
                    isDeletingAccount = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isDeletingAccount = false
                    deleteError = "Account deletion failed: \(error.localizedDescription). Please try again or contact support."
                }
            }
        }
    }
}

// MARK: - Safari Web View (for privacy/terms URLs)

import SafariServices

struct SafariWebView: UIViewControllerRepresentable {
    let url: URL
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        let vc = SFSafariViewController(url: url, configuration: config)
        return vc
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// MARK: - Legacy LegalWebView (kept for backward compatibility with bundled HTML)

struct LegalWebView: View {
    let filename: String
    let title: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            LegalHTMLView(filename: filename)
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarColorScheme(.dark)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Done") { dismiss() }.foregroundColor(.legoYellow)
                    }
                }
        }
    }
}

struct LegalHTMLView: UIViewRepresentable {
    let filename: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.18, alpha: 1)
        if let url = Bundle.main.url(forResource: filename, withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

#Preview {
    SettingsView()
}

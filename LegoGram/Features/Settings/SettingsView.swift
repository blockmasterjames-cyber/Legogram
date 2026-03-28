import SwiftUI

/// The Settings screen — accessible from the gear icon on the Profile tab.
/// Sprint 3: Kid Safe Mode is prominently featured, version updated.
struct SettingsView: View {

    @Environment(\.dismiss) private var dismiss

    @AppStorage("profile_displayName")        private var displayName           = ""
    @AppStorage("profile_username")           private var username              = ""
    @AppStorage("profile_bio")                private var bio                   = ""
    @AppStorage("profile_hasAvatar")          private var hasAvatar:            Bool = false
    @AppStorage("profile_hasBackground")      private var hasBackground:        Bool = false
    @AppStorage("settings_kidSafeMode")       private var kidSafeMode:          Bool = true
    @AppStorage("settings_notifications")     private var notificationsOn:      Bool = true
    @AppStorage("dm_ageVerified")             private var ageVerified:          Bool = false

    @State private var showingSignOutConfirm = false
    @State private var showingDeleteConfirm  = false
    @State private var showingPrivacyPolicy  = false
    @State private var showingTermsOfService = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {

                        // MARK: Kid Safety — prominent at top (Sprint 3)
                        kidSafetySection

                        // MARK: Account Section
                        settingsSection("Account") {
                            infoRow(label: "Display Name", value: displayName,    icon: "person.fill")
                            infoRow(label: "Username",     value: "@\(username)", icon: "at")
                            infoRow(label: "Email",        value: "••••@••••.com", icon: "envelope.fill")

                            actionRow(label: "Change Password", icon: "lock.fill", color: .legoYellow) {}
                        }

                        // MARK: Preferences Section
                        settingsSection("Preferences") {
                            toggleRow(label: "Notifications", icon: "bell.fill",
                                      tint: .legoYellow, isOn: $notificationsOn)
                        }

                        // MARK: Legal
                        settingsSection("Legal") {
                            actionRow(label: "Privacy Policy", icon: "hand.raised.fill", color: .legoYellow) {
                                showingPrivacyPolicy = true
                            }
                            actionRow(label: "Terms of Service", icon: "doc.text.fill", color: .legoYellow) {
                                showingTermsOfService = true
                            }
                        }

                        // MARK: Account Actions
                        settingsSection("Account Actions") {
                            actionRow(label: "Sign Out", icon: "arrow.right.square.fill", color: .legoRed) {
                                showingSignOutConfirm = true
                            }
                            actionRow(label: "Delete Account", icon: "trash.fill", color: .red) {
                                showingDeleteConfirm = true
                            }
                        }

                        // Version footer
                        Text("BrickFeed · Sprint 8 Build")
                            .font(.legoCaption)
                            .foregroundColor(.secondaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 4)

                        Color.clear.frame(height: 80)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }.foregroundColor(.legoYellow)
                }
            }
            .alert("Sign Out", isPresented: $showingSignOutConfirm) {
                Button("Sign Out", role: .destructive) { performSignOut() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to sign out of BrickFeed?")
            }
            .alert("Delete Account", isPresented: $showingDeleteConfirm) {
                Button("Delete Forever", role: .destructive) { dismiss() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete your account and all your posts. This cannot be undone!")
            }
            .sheet(isPresented: $showingPrivacyPolicy) {
                LegalWebView(filename: "PrivacyPolicy", title: "Privacy Policy")
            }
            .sheet(isPresented: $showingTermsOfService) {
                LegalWebView(filename: "TermsOfService", title: "Terms of Service")
            }
        }
    }

    // MARK: - Kid Safety Section

    private var kidSafetySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("KID SAFETY")
                .font(.legoCaption)
                .foregroundColor(.secondaryText)
                .padding(.horizontal)

            VStack(spacing: 1) {
                // Kid Safe Mode toggle
                toggleRow(label: "Kid Safe Mode", icon: "shield.checkmark.fill",
                          tint: .successGreen, isOn: $kidSafeMode)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(kidSafeMode ? Color.successGreen.opacity(0.4) : Color.clear, lineWidth: 1.5)
                    )

                // Explanation row
                HStack(spacing: 10) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.legoYellow)
                        .font(.system(size: 16))
                    Text(kidSafeMode
                         ? "Kid Safe Mode is ON — only verified kid-friendly content is shown."
                         : "Turn on Kid Safe Mode to limit content to verified kid-friendly posts.")
                        .font(.legoCaption)
                        .foregroundColor(.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color.cardBackground)
                .cornerRadius(12)

                // Bad word filter info
                HStack(spacing: 10) {
                    Image(systemName: "text.badge.xmark")
                        .foregroundColor(.legoYellow)
                        .font(.system(size: 16))
                    Text("Bad Word Filter is always ON — inappropriate words are replaced with *** automatically.")
                        .font(.legoCaption)
                        .foregroundColor(.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color.cardBackground)
                .cornerRadius(12)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Section Builder

    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.legoCaption)
                .foregroundColor(.secondaryText)
                .padding(.horizontal)

            VStack(spacing: 1) { content() }
        }
        .padding(.horizontal)
    }

    // MARK: - Row Helpers

    private func infoRow(label: String, value: String, icon: String) -> some View {
        HStack {
            Label(label, systemImage: icon)
                .font(.legoBody).foregroundColor(.lightText)
            Spacer()
            Text(value)
                .font(.legoBody).foregroundColor(.secondaryText)
        }
        .padding(.horizontal).padding(.vertical, 14)
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
        Toggle(isOn: isOn) {
            Label(label, systemImage: icon)
                .font(.legoBody).foregroundColor(.lightText)
        }
        .tint(tint)
        .padding(.horizontal).padding(.vertical, 12)
        .background(Color.cardBackground).cornerRadius(12)
    }

    // MARK: - Sign Out

    private func performSignOut() {
        // Delete saved profile images from disk
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
                   ?? FileManager.default.temporaryDirectory
        try? FileManager.default.removeItem(at: docs.appendingPathComponent("profile_avatar.jpg"))
        try? FileManager.default.removeItem(at: docs.appendingPathComponent("profile_background.jpg"))

        // Reset local AppStorage keys
        displayName     = ""
        username        = ""
        bio             = ""
        hasAvatar       = false
        hasBackground   = false
        kidSafeMode     = true
        notificationsOn = true
        ageVerified     = false

        // Sign out via Firebase Auth — ContentView's auth state listener
        // automatically navigates to LoginView when the user becomes nil.
        do {
            try AuthService.shared.signOut()
        } catch {
            print("[SettingsView] Firebase signOut error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Legal Web View

/// Displays a bundled HTML file (Privacy Policy or Terms of Service) using WKWebView.
import WebKit

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

import SwiftUI

/// The Settings screen — accessible from the gear icon on the Profile tab.
/// Lets the user update account info, toggle Kid Safe Mode and Notifications,
/// sign out, or delete their account.
struct SettingsView: View {

    @Environment(\.dismiss) private var dismiss

    // Profile info (read-only here; edited via EditProfileView)
    @AppStorage("profile_displayName") private var displayName = "blockmasterjames"
    @AppStorage("profile_username")    private var username    = "blockmasterjames"

    // Preferences stored across app launches
    @AppStorage("settings_kidSafeMode")    private var kidSafeMode:    Bool = true
    @AppStorage("settings_notifications") private var notificationsOn: Bool = true

    // Alert state
    @State private var showingSignOutConfirm  = false
    @State private var showingDeleteConfirm   = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {

                        // MARK: Account Section
                        settingsSection("Account") {
                            infoRow(label: "Display Name", value: displayName,      icon: "person.fill")
                            infoRow(label: "Username",     value: "@\(username)",    icon: "at")
                            infoRow(label: "Email",        value: "••••@••••.com",   icon: "envelope.fill")

                            actionRow(label: "Change Password", icon: "lock.fill", color: .legoYellow) {
                                // In Sprint 3 this calls AuthService.shared.sendPasswordReset(to:)
                            }
                        }

                        // MARK: Preferences Section
                        settingsSection("Preferences") {
                            toggleRow(
                                label: "Kid Safe Mode",
                                icon: "shield.fill",
                                tint: .successGreen,
                                isOn: $kidSafeMode
                            )

                            toggleRow(
                                label: "Notifications",
                                icon: "bell.fill",
                                tint: .legoYellow,
                                isOn: $notificationsOn
                            )
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

                        // App version footer
                        Text("LegoGram · Sprint 2 Build")
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
                    Button("Done") { dismiss() }
                        .foregroundColor(.legoYellow)
                }
            }
            // Sign Out confirmation
            .alert("Sign Out", isPresented: $showingSignOutConfirm) {
                Button("Sign Out", role: .destructive) {
                    // TODO Sprint 3: try? AuthService.shared.signOut()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to sign out of LegoGram?")
            }
            // Delete Account confirmation
            .alert("Delete Account", isPresented: $showingDeleteConfirm) {
                Button("Delete Forever", role: .destructive) {
                    // TODO Sprint 3: AuthService.shared.deleteAccount()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete your account and all your posts. This cannot be undone!")
            }
        }
    }

    // MARK: - Section Builder

    private func settingsSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.legoCaption)
                .foregroundColor(.secondaryText)
                .padding(.horizontal)

            VStack(spacing: 1) {
                content()
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Row Helpers

    /// A read-only row showing a label and its current value.
    private func infoRow(label: String, value: String, icon: String) -> some View {
        HStack {
            Label(label, systemImage: icon)
                .font(.legoBody)
                .foregroundColor(.lightText)
            Spacer()
            Text(value)
                .font(.legoBody)
                .foregroundColor(.secondaryText)
        }
        .padding(.horizontal)
        .padding(.vertical, 14)
        .background(Color.cardBackground)
        .cornerRadius(12)
    }

    /// A tappable row that runs an action (e.g. Change Password, Sign Out).
    private func actionRow(
        label: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(label)
                    .font(.legoBody)
                    .foregroundColor(color)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.legoCaption)
                    .foregroundColor(.secondaryText)
            }
            .padding(.horizontal)
            .padding(.vertical, 14)
            .background(Color.cardBackground)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    /// A toggle row for boolean preferences.
    private func toggleRow(
        label: String,
        icon: String,
        tint: Color,
        isOn: Binding<Bool>
    ) -> some View {
        Toggle(isOn: isOn) {
            Label(label, systemImage: icon)
                .font(.legoBody)
                .foregroundColor(.lightText)
        }
        .tint(tint)
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
}

#Preview {
    SettingsView()
}

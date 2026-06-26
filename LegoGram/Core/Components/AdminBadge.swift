import SwiftUI

/// A blue verified-style checkmark shown next to an admin's username.
/// Renders nothing for non-admins. Admin-ness is read from the cached
/// `AdminRegistry` (the console-only `admins` collection), the same secure
/// source used for the admin gate.
struct AdminBadge: View {
    let uid: String
    var size: CGFloat = 13

    @ObservedObject private var registry = AdminRegistry.shared

    var body: some View {
        if registry.isAdmin(uid) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: size))
                .foregroundColor(.blue)
                .accessibilityLabel("Verified admin")
        }
    }
}

/// A username `Text` followed by the admin badge when the user is an admin.
/// Drop-in for places that render a plain username and want consistent badging.
struct UsernameWithBadge: View {
    let username: String
    let uid: String
    var font: Font = .legoBody
    var color: Color = .lightText
    var badgeSize: CGFloat = 13
    var spacing: CGFloat = 4

    var body: some View {
        HStack(spacing: spacing) {
            Text(username)
                .font(font)
                .foregroundColor(color)
            AdminBadge(uid: uid, size: badgeSize)
        }
    }
}

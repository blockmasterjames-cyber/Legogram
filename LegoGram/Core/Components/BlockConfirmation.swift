import SwiftUI

/// Issue 1 / Apple Guideline 1.2 — explicit confirmation of a destructive action.
///
/// Every Block entry point in the app (PostCard, PostDetailView, comment rows,
/// OtherProfileView, the DM list, and the DM thread) routes through this single
/// shared alert so the wording and behavior are identical everywhere:
///
///   • Title:   "User Blocked"
///   • Message: "@<username> has been blocked. Their content will no longer
///              appear in your feed and they won't be able to see your content."
///   • Button:  a single "OK" (.default role)
///
/// Tapping OK simply dismisses the alert and leaves the user exactly where they
/// are. No navigation is triggered: the block filter (PostStore.visiblePosts /
/// isBlocked) has already removed the blocked user's content from whatever view
/// the user is currently on, so the confirmation needs to do nothing more.
extension View {

    /// Presents the shared "User Blocked" confirmation alert.
    /// - Parameters:
    ///   - username: the username that was just blocked (drives the message).
    ///   - isPresented: binding that, when `true`, shows the alert.
    func blockConfirmationAlert(username: String, isPresented: Binding<Bool>) -> some View {
        alert("User Blocked", isPresented: isPresented) {
            Button("OK") {}
        } message: {
            Text("@\(username) has been blocked. Their content will no longer appear in your feed and they won't be able to see your content.")
        }
    }
}

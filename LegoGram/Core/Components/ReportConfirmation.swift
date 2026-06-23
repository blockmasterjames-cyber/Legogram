import SwiftUI

/// Apple Guideline 1.2 — a visible confirmation that a report was filed.
///
/// Every Report entry point in the app (the feed PostCard via HomeView,
/// PostDetailView, CommentSheetView, OtherProfileView, the DM list, and the DM
/// thread) routes through this single shared alert so the wording and behavior
/// are identical everywhere — mirroring `blockConfirmationAlert`:
///
///   • Title:   "Report Received"
///   • Message: "Thanks for reporting this. Our team will review it within 24
///              hours and take action on content that violates our guidelines."
///   • Button:  a single "OK"
///
/// The alert stays on screen until the user taps OK, so it is clearly visible
/// in a screen recording (App Review proof of the report mechanism). Tapping OK
/// simply dismisses the alert and leaves the user exactly where they are — no
/// navigation is triggered. Hiding/removing the reported content is handled by
/// the caller's existing logic (e.g. PostStore.reportPost), so this modifier
/// only provides the confirmation UI.
///
/// Note for the feed: a reported post is removed from `visiblePosts`
/// immediately, which tears down its PostCard. So the feed hosts this alert on
/// the stable HomeView (PostCard signals it via a callback) rather than on the
/// card itself — otherwise the alert would be dismissed before it could appear.
extension View {

    /// Presents the shared "Report Received" confirmation alert.
    /// - Parameter isPresented: binding that, when `true`, shows the alert.
    func reportConfirmationAlert(isPresented: Binding<Bool>) -> some View {
        alert("Report Received", isPresented: isPresented) {
            Button("OK") {}
        } message: {
            Text("Thanks for reporting this. Our team will review it within 24 hours and take action on content that violates our guidelines.")
        }
    }
}

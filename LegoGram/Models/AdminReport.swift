import Foundation

/// A moderation report, read from the `reports/{autoId}` collection by admins.
/// Reports are CREATED by `FirebaseService.reportContent` (every Report/Block
/// control in the app). A report is considered "open" unless `status` is
/// `"resolved"`. Absence of `status` means open (existing docs aren't backfilled).
struct AdminReport: Identifiable, Hashable {

    let id: String

    /// "post" | "comment" | "user" | "dm_thread" | "dm_message" | "block"
    let contentType: String
    /// Id of the reported post / comment / message / thread / user.
    let contentId: String

    /// The reported party (target).
    let reportedUserId: String
    let reportedUsername: String

    /// The reporter.
    let reportedBy: String
    let reportedByUsername: String

    let reason: String
    let contextText: String
    let reportedAt: Date

    /// nil/"" == open; "resolved" == handled.
    let status: String?
    let resolvedBy: String?
    let resolvedAt: Date?

    var isResolved: Bool { status == "resolved" }

    /// Whether "Remove Content" is a meaningful action for this report.
    /// DM content removal is out of scope for Build 1; "user"/"block" reports
    /// have no single content document to remove (use Ban / Dismiss instead).
    var canRemoveContent: Bool {
        contentType == "post" || contentType == "comment"
    }

    var contentTypeLabel: String {
        switch contentType {
        case "post":        return "Post"
        case "comment":     return "Comment"
        case "user":        return "User"
        case "dm_thread":   return "DM Thread"
        case "dm_message":  return "DM Message"
        case "block":       return "Block"
        default:            return contentType.capitalized
        }
    }

    var timeAgo: String {
        let diff = Date().timeIntervalSince(reportedAt)
        switch diff {
        case ..<60:    return "Just now"
        case ..<3600:  return "\(Int(diff / 60))m ago"
        case ..<86400: return "\(Int(diff / 3600))h ago"
        default:       return "\(Int(diff / 86400))d ago"
        }
    }
}

import Foundation
import SwiftUI

// MARK: - App Notification Model

struct AppNotification: Identifiable, Codable {
    let id: String
    let type: NotificationType
    let fromUserId: String
    let fromUsername: String
    let postId: String
    let timestamp: Date
    var isRead: Bool

    enum NotificationType: String, Codable {
        case like    = "like"
        case comment = "comment"
        case follow  = "follow"
    }

    var message: String {
        switch type {
        case .like:    return "\(fromUsername) liked your post"
        case .comment: return "\(fromUsername) commented on your post"
        case .follow:  return "\(fromUsername) started following you"
        }
    }

    var icon: String {
        switch type {
        case .like:    return "heart.fill"
        case .comment: return "bubble.right.fill"
        case .follow:  return "person.badge.plus.fill"
        }
    }

    var iconColor: Color {
        switch type {
        case .like:    return .legoRed
        case .comment: return .blue
        case .follow:  return .successGreen
        }
    }

    var timeAgo: String {
        let diff = Date().timeIntervalSince(timestamp)
        switch diff {
        case ..<60:    return "Just now"
        case ..<3600:  return "\(Int(diff / 60))m ago"
        case ..<86400: return "\(Int(diff / 3600))h ago"
        default:       return "\(Int(diff / 86400))d ago"
        }
    }
}

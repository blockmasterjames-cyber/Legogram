import SwiftUI

/// A reusable circular avatar.
///
/// Loads a user's photo from a URL and falls back to a colored initial-letter
/// circle whenever an image isn't available (empty URL, load failure, or while
/// loading). This consolidates the "show an avatar from a URL with an
/// initial-letter fallback" pattern that was previously copy-pasted inline
/// across `OtherProfileView`, `CommentRow`, and elsewhere.
///
/// The fallback styling is customizable so existing call sites keep their exact
/// look, while new call sites get a sensible shared default (a per-username
/// hash color with a white initial, matching `CommentRow`'s old `initialCircle`).
struct UserAvatar: View {
    /// Avatar image URL. `nil`/empty shows the initial-letter fallback.
    let url: String?
    /// Username used for the fallback initial (and default hash color).
    let username: String
    /// Diameter of the avatar.
    let size: CGFloat

    /// Fallback circle fill. `nil` ⇒ a stable per-username hash color (default).
    var fallbackFill: Color? = nil
    /// Initial-letter color in the fallback.
    var initialColor: Color = .white
    /// Initial-letter font. `nil` ⇒ a size-proportional rounded bold font.
    var initialFont: Font? = nil

    var body: some View {
        Group {
            if let url, !url.isEmpty, let parsed = URL(string: url) {
                AsyncImage(url: parsed) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                    default:
                        fallback
                    }
                }
                .frame(width: size, height: size)
            } else {
                fallback
            }
        }
    }

    private var fallback: some View {
        Circle()
            .fill(fallbackFill ?? Self.hashColor(for: username))
            .frame(width: size, height: size)
            .overlay(
                Text(String(username.prefix(1)).uppercased())
                    .font(initialFont ?? .system(size: size * 0.4, weight: .bold, design: .rounded))
                    .foregroundColor(initialColor)
            )
    }

    /// Stable per-username color from a small LEGO-flavored palette. Mirrors the
    /// `avatarColor(for:)` helper that used to live privately inside `CommentRow`.
    static func hashColor(for username: String) -> Color {
        let colors: [Color] = [Color.legoRed.opacity(0.8), .blue, .purple, .orange, .pink, .teal]
        let index = abs(username.hashValue) % colors.count
        return colors[index]
    }
}

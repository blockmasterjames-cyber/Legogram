import SwiftUI

/// LegoGram's official color palette.
/// Every screen in the app uses these colors so everything looks the same.
extension Color {

    // MARK: - Brand Colors
    /// Official LEGO red — used for buttons, the center tab, and highlights.
    static let legoRed = Color(hex: "#E3000B")

    /// Official LEGO yellow — used for selected tab icons and accents.
    static let legoYellow = Color(hex: "#FFD700")

    // MARK: - Background Colors
    /// The very dark background used behind all screens.
    static let darkBackground = Color(hex: "#1A1A1A")

    /// The slightly lighter dark color used for cards and list rows.
    static let cardBackground = Color(hex: "#2C2C2C")

    // MARK: - Text Colors
    /// Bright white — used for main headings and important text.
    static let lightText = Color(hex: "#FFFFFF")

    /// Muted grey — used for captions and less important information.
    static let secondaryText = Color(hex: "#A0A0A0")

    // MARK: - Status Colors
    /// Green checkmark color — used for success messages.
    static let successGreen = Color(hex: "#4CAF50")
}

// MARK: - Hex Color Initializer
extension Color {
    /// Lets us create a Color directly from a hex string like "#E3000B".
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

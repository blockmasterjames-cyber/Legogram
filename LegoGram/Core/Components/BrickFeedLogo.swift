import SwiftUI

/// BrickFeed app logo — 100% pure SwiftUI, zero image files required.
/// No asset catalog entries, no manual Xcode steps.
/// Renders a LEGO-red rounded rectangle with "Brick" in white bold text,
/// followed by "Feed" in LEGO yellow bold text.
struct BrickFeedLogo: View {

    var body: some View {
        HStack(spacing: 0) {
            Text("Brick")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(hex: "#E3000B"))
                .cornerRadius(6)

            Text("Feed")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "#FFD700"))
                .padding(.leading, 6)
        }
    }
}

#Preview {
    ZStack {
        Color(hex: "#1A1A1A")
        BrickFeedLogo()
    }
}

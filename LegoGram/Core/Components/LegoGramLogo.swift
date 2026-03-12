import SwiftUI

/// LegoGram app logo — 100% pure SwiftUI, zero image files required.
/// No asset catalog entries, no manual Xcode steps.
/// Renders a LEGO-red rounded rectangle with "LEGO" in white bold text,
/// followed by "Gram" in LEGO yellow bold text.
struct LegoGramLogo: View {

    var body: some View {
        HStack(spacing: 0) {
            Text("LEGO")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(hex: "#E3000B"))
                .cornerRadius(6)

            Text("Gram")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "#FFD700"))
                .padding(.leading, 6)
        }
    }
}

#Preview {
    ZStack {
        Color(hex: "#1A1A1A")
        LegoGramLogo()
    }
}

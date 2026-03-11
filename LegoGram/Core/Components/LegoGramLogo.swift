import SwiftUI

/// The LegoGram logo shown at the top of the Home feed.
/// Sprint 6: Drawn entirely in SwiftUI — no image asset needed, never requires manual setup.
/// Shows "LEGO" in white text on a LEGO-red rounded rectangle, followed by "Gram" in LEGO yellow.
struct LegoGramLogo: View {

    var body: some View {
        HStack(spacing: 0) {
            Text("LEGO")
                .font(.legoAppTitle)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.legoRed)
                .cornerRadius(6)

            Text("Gram")
                .font(.legoAppTitle)
                .foregroundColor(.legoYellow)
                .padding(.leading, 6)
        }
    }
}

#Preview {
    ZStack {
        Color.darkBackground
        LegoGramLogo()
    }
}

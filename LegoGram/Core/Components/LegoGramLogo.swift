import SwiftUI

/// The LegoGram logo that appears at the top of the Home screen.
/// It shows the app name in big LEGO-style colors — yellow on a red background.
struct LegoGramLogo: View {

    var body: some View {
        HStack(spacing: 0) {
            Text("LEGO")
                .font(.legoAppTitle)
                .foregroundColor(.legoYellow)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.legoRed)
                .cornerRadius(4)

            Text("Gram")
                .font(.legoAppTitle)
                .foregroundColor(.lightText)
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

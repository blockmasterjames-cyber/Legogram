import SwiftUI

/// The LegoGram logo shown at the top of the Home feed.
/// Sprint 3 — displays the official lego_gram_logo image if it exists in Assets.xcassets.
/// Falls back to the text logo automatically so the app always looks great.
struct LegoGramLogo: View {

    var body: some View {
        if UIImage(named: "lego_gram_logo") != nil {
            // Official logo image (add lego_gram_logo to Assets.xcassets to activate)
            Image("lego_gram_logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 40)
        } else {
            // Text logo fallback
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
}

#Preview {
    ZStack {
        Color.darkBackground
        LegoGramLogo()
    }
}

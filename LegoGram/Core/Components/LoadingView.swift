import SwiftUI

/// A spinning loading circle shown while the app is fetching data from the internet.
/// Like a spinning LEGO piece while you wait for your order to arrive!
struct LoadingView: View {

    var message: String = "Loading..."

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.legoYellow)
                .scaleEffect(1.5)

            Text(message)
                .font(.legoBody)
                .foregroundColor(.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.darkBackground)
    }
}

#Preview {
    LoadingView(message: "Fetching LEGO builds...")
}

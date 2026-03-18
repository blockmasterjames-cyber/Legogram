import SwiftUI

/// The first-launch onboarding experience for BrickFeed.
/// Three swipeable slides introduce the app. A Skip button appears on slides 1–2.
/// Tapping "Get Started" on slide 3 (or Skip at any time) sets the
/// @AppStorage flag so onboarding never shows again.
struct OnboardingView: View {

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0

    var body: some View {
        ZStack(alignment: .top) {
            Color.darkBackground.ignoresSafeArea()

            // Swipeable pages
            TabView(selection: $currentPage) {
                OnboardingSlide1().tag(0)
                OnboardingSlide2().tag(1)
                OnboardingSlide3 { hasSeenOnboarding = true }.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            // Skip button — only on slides 0 and 1
            if currentPage < 2 {
                HStack {
                    Spacer()
                    Button("Skip") {
                        hasSeenOnboarding = true
                    }
                    .font(.legoBody)
                    .foregroundColor(.secondaryText)
                    .padding(.horizontal, 20)
                    .padding(.top, 56)
                }
            }
        }
    }
}

// MARK: - Slide 1: Welcome

private struct OnboardingSlide1: View {
    var body: some View {
        VStack(spacing: 36) {
            Spacer()

            // Logo (scaled up)
            BrickFeedLogo()
                .scaleEffect(1.6)
                .padding(.bottom, 24)

            // Headline
            VStack(spacing: 10) {
                Text("Welcome to BrickFeed!")
                    .font(.legoScreenTitle)
                    .foregroundColor(.lightText)
                    .multilineTextAlignment(.center)

                Text("The home for Brick builders 🧱")

                    .font(.legoCardTitle)
                    .foregroundColor(.legoYellow)
                    .multilineTextAlignment(.center)
            }

            // Decorative brick row
            HStack(spacing: 12) {
                ForEach(Array(zip(
                    [Color.legoRed, Color.legoYellow, Color.blue.opacity(0.8),
                     Color.green.opacity(0.8), Color.orange.opacity(0.8)],
                    0..<5
                )), id: \.1) { color, _ in
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(color)
                            .frame(width: 44, height: 44)
                        // Stud dot
                        Circle()
                            .fill(color.opacity(0.55))
                            .frame(width: 18, height: 18)
                            .offset(y: -10)
                    }
                }
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Slide 2: Share Builds

private struct OnboardingSlide2: View {

    private let brickColors: [[Color]] = [
        [.legoRed,    .legoYellow, .legoRed,    .blue.opacity(0.8)],
        [.legoYellow, .legoRed,    .green.opacity(0.8), .legoYellow],
        [.blue.opacity(0.8), .green.opacity(0.8), .legoYellow, .legoRed],
        [.green.opacity(0.8), .blue.opacity(0.8), .legoRed, .green.opacity(0.8)],
    ]

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // LEGO brick grid illustration
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.cardBackground)
                    .frame(width: 210, height: 210)
                    .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)

                VStack(spacing: 6) {
                    ForEach(0..<4, id: \.self) { row in
                        HStack(spacing: 6) {
                            ForEach(0..<4, id: \.self) { col in
                                ZStack {
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(brickColors[row][col])
                                        .frame(width: 38, height: 38)
                                    Circle()
                                        .fill(brickColors[row][col].opacity(0.5))
                                        .frame(width: 15, height: 15)
                                        .offset(y: -8)
                                }
                            }
                        }
                    }
                }
            }

            // Text
            VStack(spacing: 10) {
                Text("Share Your Builds!")
                    .font(.legoScreenTitle)
                    .foregroundColor(.lightText)
                    .multilineTextAlignment(.center)

                Text("Snap a photo of your brick creation, tag the set number, and share it with builders around the world! Earn rewards when other fans buy the set through your post.")
                    .font(.legoBody)
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Slide 3: Safety + Get Started

private struct OnboardingSlide3: View {
    let onGetStarted: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            // Safety shield icon
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 80))
                .foregroundColor(.successGreen)

            // Headline
            VStack(spacing: 10) {
                Text("Safe & Fun For Everyone")
                    .font(.legoScreenTitle)
                    .foregroundColor(.lightText)
                    .multilineTextAlignment(.center)

                Text("BrickFeed is designed to be safe and fun for builders of all ages.")
                    .font(.legoBody)
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Safety features list
            VStack(alignment: .leading, spacing: 16) {
                safetyRow(icon: "person.badge.shield.checkmark.fill",
                          text: "Kid-friendly community only",
                          color: .successGreen)
                safetyRow(icon: "xmark.circle.fill",
                          text: "Built-in bad word filter",
                          color: .legoYellow)
                safetyRow(icon: "flag.fill",
                          text: "Report any post you see",
                          color: .legoRed)
                safetyRow(icon: "eye.slash.fill",
                          text: "Block any builder you want",
                          color: .secondaryText)
            }
            .padding(.horizontal, 40)

            Spacer()

            // Get Started button
            Button(action: onGetStarted) {
                HStack {
                    Image(systemName: "star.fill")
                    Text("Get Started!")
                        .font(.legoCardTitle)
                }
                .foregroundColor(.darkBackground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.legoYellow)
                .cornerRadius(14)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 70)
        }
        .padding(.top, 20)
    }

    private func safetyRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)
                .frame(width: 30)
            Text(text)
                .font(.legoBody)
                .foregroundColor(.lightText)
        }
    }
}

#Preview {
    OnboardingView()
}

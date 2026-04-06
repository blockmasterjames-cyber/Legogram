import SwiftUI

/// The first-launch onboarding experience for BrickFeed.
/// Three swipeable slides introduce the app. Shown once after account creation.
struct OnboardingView: View {

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0

    var body: some View {
        ZStack(alignment: .top) {
            Color.darkBackground.ignoresSafeArea()

            TabView(selection: $currentPage) {
                OnboardingSlide1().tag(0)
                OnboardingSlide2().tag(1)
                OnboardingSlide3 {
                    hasSeenOnboarding = true
                }.tag(2)
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

// MARK: - Slide 1: Welcome to BrickFeed

private struct OnboardingSlide1: View {
    var body: some View {
        VStack(spacing: 36) {
            Spacer()

            BrickFeedLogo()
                .scaleEffect(1.6)
                .padding(.bottom, 24)

            VStack(spacing: 10) {
                Text("Welcome to BrickFeed! 🧱")
                    .font(.legoScreenTitle)
                    .foregroundColor(.lightText)
                    .multilineTextAlignment(.center)

                Text("Share your LEGO builds with builders around the world")
                    .font(.legoCardTitle)
                    .foregroundColor(.legoYellow)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 12) {
                ForEach(Array(zip(
                    [Color.legoRed, Color.legoYellow, Color.blue.opacity(0.8),
                     Color.green.opacity(0.8), Color.orange.opacity(0.8)],
                    0..<5
                )), id: \.1) { color, _ in
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(color).frame(width: 44, height: 44)
                        Circle()
                            .fill(color.opacity(0.55)).frame(width: 18, height: 18)
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

// MARK: - Slide 2: Earn Points (replaces old "Earn Rewards/earnings" messaging)

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

            VStack(spacing: 10) {
                Text("Earn Points! ⭐")
                    .font(.legoScreenTitle)
                    .foregroundColor(.lightText)
                    .multilineTextAlignment(.center)

                Text("Get points for posting builds, receiving likes, and making friends in the BrickFeed community!")
                    .font(.legoBody)
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Points breakdown
            VStack(alignment: .leading, spacing: 10) {
                pointRow(icon: "photo.fill",       color: .legoRed,    text: "Post a build → +10 points")
                pointRow(icon: "heart.fill",        color: .legoRed,    text: "Get a like → +2 points")
                pointRow(icon: "bubble.right.fill", color: .legoYellow, text: "Get a comment → +5 points")
                pointRow(icon: "person.fill.badge.plus", color: .successGreen, text: "Get a follow → +1 point")
            }
            .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private func pointRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 18)).foregroundColor(color).frame(width: 24)
            Text(text).font(.legoBody).foregroundColor(.lightText)
        }
    }
}

// MARK: - Slide 3: Safety + Get Started

private struct OnboardingSlide3: View {
    let onGetStarted: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 80))
                .foregroundColor(.successGreen)

            VStack(spacing: 10) {
                Text("Stay Safe! 🛡️")
                    .font(.legoScreenTitle).foregroundColor(.lightText)
                    .multilineTextAlignment(.center)

                Text("BrickFeed is a safe place — kid safe mode protects younger builders and keeps the community fun for everyone.")
                    .font(.legoBody).foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center).padding(.horizontal)
            }

            VStack(alignment: .leading, spacing: 16) {
                safetyRow(icon: "person.badge.shield.checkmark.fill",
                          text: "Kid Safe Mode for under-13 builders", color: .successGreen)
                safetyRow(icon: "xmark.circle.fill",
                          text: "Built-in bad word filter always on", color: .legoYellow)
                safetyRow(icon: "flag.fill",
                          text: "Report any post that doesn't belong", color: .legoRed)
                safetyRow(icon: "eye.slash.fill",
                          text: "Block any builder at any time", color: .secondaryText)
            }
            .padding(.horizontal, 40)

            Spacer()

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
            Image(systemName: icon).font(.system(size: 22)).foregroundColor(color).frame(width: 30)
            Text(text).font(.legoBody).foregroundColor(.lightText)
        }
    }
}

#Preview {
    OnboardingView()
}

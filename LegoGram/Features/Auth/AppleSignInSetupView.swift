import SwiftUI

/// Shown to new Apple Sign In users who need to pick a username and enter birthday.
/// Returning Apple users go straight to the feed (never see this screen).
struct AppleSignInSetupView: View {

    @ObservedObject private var authService = AuthService.shared

    @State private var username    = ""
    @State private var birthday    = Calendar.current.date(byAdding: .year, value: -13, to: Date()) ?? Date()
    @State private var hasBirthday = false
    @State private var isLoading   = false
    @State private var errorMessage: String?
    @State private var showKidSafeMessage = false

    private var birthdayRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let oldest   = calendar.date(byAdding: .year, value: -120, to: Date()) ?? Date()
        let youngest = calendar.date(byAdding: .year, value: -4,   to: Date()) ?? Date()
        return oldest...youngest
    }

    private var isUnder13: Bool {
        guard hasBirthday else { return false }
        let age = Calendar.current.dateComponents([.year], from: birthday, to: Date()).year ?? 0
        return age < 13
    }

    var body: some View {
        ZStack {
            Color.darkBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {

                    // Logo
                    BrickFeedLogo()
                        .scaleEffect(1.2)
                        .padding(.top, 60)

                    VStack(spacing: 8) {
                        Text("One more step!")
                            .font(.legoScreenTitle).foregroundColor(.lightText)
                        Text("Pick your username and birthday to finish setting up your BrickFeed account.")
                            .font(.legoBody).foregroundColor(.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)

                    VStack(spacing: 16) {

                        // Username
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Choose a Username", systemImage: "at")
                                .font(.legoCardTitle).foregroundColor(.legoYellow)

                            HStack(spacing: 0) {
                                Text("@")
                                    .font(.legoBody).foregroundColor(.secondaryText).padding(.leading, 14)
                                TextField("username", text: $username)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .padding(.vertical, 16).padding(.horizontal, 8)
                                    .foregroundColor(.lightText)
                            }
                            .background(Color.cardBackground).cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.secondaryText.opacity(0.3), lineWidth: 1))
                        }

                        // Birthday — REQUIRED
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Birthday *", systemImage: "birthday.cake.fill")
                                .font(.legoCardTitle).foregroundColor(.legoYellow)

                            HStack(spacing: 10) {
                                Image(systemName: "birthday.cake.fill")
                                    .foregroundColor(.secondaryText).frame(width: 20).padding(.leading, 14)
                                Text("Birthday")
                                    .font(.legoBody)
                                    .foregroundColor(hasBirthday ? .lightText : .secondaryText)
                                Spacer()
                                DatePicker("", selection: $birthday, in: birthdayRange,
                                           displayedComponents: .date)
                                    .labelsHidden()
                                    .colorScheme(.dark)
                                    .onChange(of: birthday) { _, _ in
                                        hasBirthday = true
                                        withAnimation { showKidSafeMessage = isUnder13 }
                                    }
                            }
                            .padding(.vertical, 10).padding(.trailing, 14)
                            .background(Color.cardBackground).cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .stroke(hasBirthday ? Color.legoYellow.opacity(0.5) : Color.secondaryText.opacity(0.3), lineWidth: 1))

                            if !hasBirthday {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.circle")
                                        .font(.system(size: 12)).foregroundColor(.legoRed)
                                    Text("Birthday is required for your safety")
                                        .font(.system(size: 11, design: .rounded)).foregroundColor(.legoRed)
                                }
                            }

                            if showKidSafeMessage {
                                HStack(spacing: 6) {
                                    Image(systemName: "shield.checkmark.fill")
                                        .font(.system(size: 14)).foregroundColor(.successGreen)
                                    Text("Since you're under 13, Kid Safe Mode will be automatically enabled to keep you protected! 🛡️")
                                        .font(.system(size: 12, design: .rounded))
                                        .foregroundColor(.successGreen)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(10)
                                .background(Color.successGreen.opacity(0.12))
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    if let error = errorMessage {
                        Text(error)
                            .font(.legoCaption).foregroundColor(.red)
                            .multilineTextAlignment(.center).padding(.horizontal, 24)
                    }

                    // Continue Button
                    Button(action: completeSetup) {
                        Group {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Let's Go!").font(.legoCardTitle)
                                }
                                .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity).frame(height: 52)
                        .background(Color.legoRed).cornerRadius(14)
                    }
                    .disabled(isLoading || username.trimmingCharacters(in: .whitespaces).isEmpty || !hasBirthday)
                    .padding(.horizontal, 24)

                    Color.clear.frame(height: 40)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func completeSetup() {
        let trimmedUsername = username.trimmingCharacters(in: .whitespaces)
        guard !trimmedUsername.isEmpty else {
            errorMessage = "Please choose a username."; return
        }
        guard !trimmedUsername.contains(" ") else {
            errorMessage = "Username cannot contain spaces."; return
        }
        guard hasBirthday else {
            errorMessage = "Please select your birthday."; return
        }

        isLoading    = true
        errorMessage = nil

        Task {
            do {
                let displayName = UserSession.shared.displayName
                try await AuthService.shared.completeAppleSetup(
                    username: trimmedUsername,
                    displayName: displayName,
                    birthday: birthday
                )
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

#Preview {
    AppleSignInSetupView()
}

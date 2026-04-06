import SwiftUI

/// The account creation screen.
/// Birthday is required for COPPA compliance. Under-13 users get Kid Safe Mode automatically.
struct SignUpView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var displayName     = ""
    @State private var username        = ""
    @State private var email           = ""
    @State private var password        = ""
    @State private var confirmPassword = ""
    @State private var birthday        = Calendar.current.date(byAdding: .year, value: -13, to: Date()) ?? Date()
    @State private var hasBirthday     = false
    @State private var parentEmail     = ""
    @State private var isLoading       = false
    @State private var errorMessage: String?
    @State private var showKidSafeMessage = false

    @State private var showPrivacyPolicy  = false
    @State private var showTermsOfService = false

    private let privacyURL = URL(string: "https://blockmasterjames-cyber.github.io/brickfeed-legal/privacy")!
    private let termsURL   = URL(string: "https://blockmasterjames-cyber.github.io/brickfeed-legal/terms")!

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
                VStack(spacing: 24) {

                    // Logo
                    BrickFeedLogo()
                        .scaleEffect(1.2)
                        .padding(.top, 50)
                        .padding(.bottom, 4)

                    Text("Create Your Account")
                        .font(.legoCardTitle)
                        .foregroundColor(.lightText)

                    // Fields
                    VStack(spacing: 14) {

                        fieldView(placeholder: "Display Name", icon: "person.fill", text: $displayName)

                        // Username
                        HStack(spacing: 0) {
                            Text("@")
                                .font(.legoBody).foregroundColor(.secondaryText).padding(.leading, 14)
                            TextField("username", text: $username)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .padding(.vertical, 16).padding(.horizontal, 8)
                                .foregroundColor(.lightText)
                        }
                        .background(Color.cardBackground)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.secondaryText.opacity(0.3), lineWidth: 1))

                        fieldView(placeholder: "Email", icon: "envelope.fill",
                                  text: $email, keyboardType: .emailAddress)

                        // Birthday — REQUIRED
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 10) {
                                Image(systemName: "birthday.cake.fill")
                                    .foregroundColor(.secondaryText).frame(width: 20).padding(.leading, 14)
                                Text("Birthday *")
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
                            .background(Color.cardBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(hasBirthday ? Color.legoYellow.opacity(0.5) : Color.secondaryText.opacity(0.3),
                                            lineWidth: 1)
                            )

                            // Required indicator
                            if !hasBirthday {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.circle")
                                        .font(.system(size: 12)).foregroundColor(.legoRed)
                                    Text("Birthday is required — tap the date above to select yours")
                                        .font(.system(size: 11, design: .rounded))
                                        .foregroundColor(.legoRed)
                                }
                                .padding(.horizontal, 4)
                            }

                            // Kid Safe Mode notice when under 13
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

                                // Parent/guardian email — REQUIRED for under-13
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "envelope.badge.shield.half.filled.fill")
                                            .font(.system(size: 14)).foregroundColor(.legoYellow)
                                        Text("Parent / Guardian Email *")
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .foregroundColor(.legoYellow)
                                    }
                                    HStack(spacing: 10) {
                                        Image(systemName: "envelope.fill")
                                            .foregroundColor(.secondaryText).frame(width: 20).padding(.leading, 14)
                                        TextField("parent@example.com", text: $parentEmail)
                                            .keyboardType(.emailAddress)
                                            .autocapitalization(.none)
                                            .autocorrectionDisabled()
                                            .padding(.vertical, 14).padding(.trailing, 14)
                                            .foregroundColor(.lightText)
                                            .font(.legoBody)
                                    }
                                    .background(Color.cardBackground).cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.legoYellow.opacity(0.5), lineWidth: 1))

                                    Text("A welcome email explaining BrickFeed's safety features will be sent to your parent. Required for accounts under 13.")
                                        .font(.system(size: 11, design: .rounded))
                                        .foregroundColor(.secondaryText)
                                }
                                .padding(10)
                                .background(Color.legoYellow.opacity(0.06))
                                .cornerRadius(10)
                            }

                            // COPPA notice
                            HStack(spacing: 6) {
                                Image(systemName: "shield.checkmark.fill")
                                    .font(.system(size: 12)).foregroundColor(.successGreen)
                                Text("Users under 13 get Kid Safe Mode for extra protection")
                                    .font(.system(size: 11, design: .rounded))
                                    .foregroundColor(.secondaryText)
                            }
                            .padding(.horizontal, 4)
                        }

                        secureFieldView(placeholder: "Password", text: $password)
                        secureFieldView(placeholder: "Confirm Password", text: $confirmPassword)
                    }
                    .padding(.horizontal, 24)

                    // Error Message
                    if let error = errorMessage {
                        Text(error)
                            .font(.legoCaption).foregroundColor(.red)
                            .multilineTextAlignment(.center).padding(.horizontal, 24)
                    }

                    // Privacy & Terms (required before account creation)
                    VStack(spacing: 4) {
                        Text("By creating an account you agree to our")
                            .font(.legoCaption).foregroundColor(.secondaryText)
                        HStack(spacing: 4) {
                            Button("Privacy Policy") { showPrivacyPolicy = true }
                                .font(.legoCaption).foregroundColor(.legoYellow)
                            Text("and")
                                .font(.legoCaption).foregroundColor(.secondaryText)
                            Button("Terms of Service") { showTermsOfService = true }
                                .font(.legoCaption).foregroundColor(.legoYellow)
                        }
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                    // Create Account Button
                    Button(action: performSignUp) {
                        Group {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Create Account")
                                    .font(.legoCardTitle).foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity).frame(height: 52)
                        .background(Color.legoRed).cornerRadius(14)
                    }
                    .disabled(isLoading)
                    .padding(.horizontal, 24)

                    Button("Back to Login") { dismiss() }
                        .font(.legoBody).foregroundColor(.legoYellow)
                        .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showPrivacyPolicy) {
            SafariWebView(url: privacyURL)
        }
        .sheet(isPresented: $showTermsOfService) {
            SafariWebView(url: termsURL)
        }
    }

    // MARK: - Field Helpers

    private func fieldView(
        placeholder: String,
        icon: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.secondaryText).frame(width: 20).padding(.leading, 14)
            TextField(placeholder, text: text)
                .keyboardType(keyboardType)
                .autocapitalization(keyboardType == .emailAddress ? .none : .words)
                .disableAutocorrection(keyboardType == .emailAddress)
                .padding(.vertical, 16).padding(.trailing, 14)
                .foregroundColor(.lightText)
        }
        .background(Color.cardBackground).cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.secondaryText.opacity(0.3), lineWidth: 1))
    }

    private func secureFieldView(placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.fill")
                .foregroundColor(.secondaryText).frame(width: 20).padding(.leading, 14)
            SecureField(placeholder, text: text)
                .padding(.vertical, 16).padding(.trailing, 14).foregroundColor(.lightText)
        }
        .background(Color.cardBackground).cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.secondaryText.opacity(0.3), lineWidth: 1))
    }

    // MARK: - Sign Up Action

    private func performSignUp() {
        guard !displayName.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter your display name."; return
        }
        let trimmedUsername = username.trimmingCharacters(in: .whitespaces)
        guard !trimmedUsername.isEmpty else {
            errorMessage = "Please enter a username."; return
        }
        guard !trimmedUsername.contains(" ") else {
            errorMessage = "Username cannot contain spaces."; return
        }
        guard !email.isEmpty else {
            errorMessage = "Please enter your email."; return
        }
        // Birthday is REQUIRED
        guard hasBirthday else {
            errorMessage = "Please select your birthday — it is required to create an account."; return
        }
        // Parent email required for under-13
        if isUnder13 && parentEmail.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "A parent or guardian email is required for accounts under 13."; return
        }
        if isUnder13 && !parentEmail.contains("@") {
            errorMessage = "Please enter a valid parent or guardian email address."; return
        }
        // Validate display name / username for bad words
        if let nameError = BadWordFilter.validateUsername(displayName.trimmingCharacters(in: .whitespaces)) {
            errorMessage = nameError; return
        }
        if let usernameError = BadWordFilter.validateUsername(trimmedUsername) {
            errorMessage = usernameError; return
        }
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."; return
        }
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."; return
        }

        isLoading    = true
        errorMessage = nil

        Task {
            do {
                try await AuthService.shared.signUp(
                    email: email,
                    password: password,
                    username: trimmedUsername,
                    displayName: displayName.trimmingCharacters(in: .whitespaces),
                    birthday: birthday,
                    parentEmail: isUnder13 ? parentEmail.trimmingCharacters(in: .whitespaces) : ""
                )
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

#Preview {
    SignUpView()
}

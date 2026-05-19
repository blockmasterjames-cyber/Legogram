import SwiftUI
import AuthenticationServices

/// The main login screen shown when the user is not authenticated.
struct LoginView: View {

    @State private var email        = ""
    @State private var password     = ""
    @State private var isLoading    = false
    @State private var errorMessage: String?
    @State private var showSignUp          = false
    @State private var showForgotPassword  = false
    @State private var showPrivacyPolicy   = false
    @State private var showTermsOfService  = false

    private let privacyURL = URL(string: "https://blockmasterjames-cyber.github.io/brickfeed-legal/privacy")!
    private let termsURL   = URL(string: "https://blockmasterjames-cyber.github.io/brickfeed-legal/terms")!

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {

                        // MARK: Logo
                        BrickFeedLogo()
                            .scaleEffect(1.4)
                            .padding(.top, 70)
                            .padding(.bottom, 8)

                        // MARK: Fields
                        VStack(spacing: 14) {
                            TextField("Email", text: $email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .padding()
                                .background(Color.cardBackground)
                                .cornerRadius(12)
                                .foregroundColor(.lightText)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.secondaryText.opacity(0.3), lineWidth: 1)
                                )

                            SecureField("Password", text: $password)
                                .padding()
                                .background(Color.cardBackground)
                                .cornerRadius(12)
                                .foregroundColor(.lightText)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.secondaryText.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, 24)

                        // MARK: Error Message
                        if let error = errorMessage {
                            Text(error)
                                .font(.legoCaption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }

                        // MARK: Actions
                        VStack(spacing: 16) {

                            Button(action: performLogin) {
                                Group {
                                    if isLoading {
                                        ProgressView().tint(.white)
                                    } else {
                                        Text("Log In")
                                            .font(.legoCardTitle)
                                            .foregroundColor(.white)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.legoRed)
                                .cornerRadius(14)
                            }
                            .disabled(isLoading || email.isEmpty || password.isEmpty)

                            Button("Forgot Password?") {
                                showForgotPassword = true
                            }
                            .font(.legoBody)
                            .foregroundColor(.legoYellow)

                            HStack {
                                Rectangle()
                                    .fill(Color.secondaryText.opacity(0.4)).frame(height: 1)
                                Text("OR")
                                    .font(.legoCaption).foregroundColor(.secondaryText)
                                    .padding(.horizontal, 10)
                                Rectangle()
                                    .fill(Color.secondaryText.opacity(0.4)).frame(height: 1)
                            }

                            Button {
                                showSignUp = true
                            } label: {
                                Text("Create Account")
                                    .font(.legoCardTitle)
                                    .foregroundColor(.darkBackground)
                                    .frame(maxWidth: .infinity).frame(height: 52)
                                    .background(Color.legoYellow).cornerRadius(14)
                            }

                            // Sign in with Apple (required by App Store)
                            SignInWithAppleButton(.signIn) { request in
                                print("[LoginView] Sign in with Apple: preparing request…")
                                guard let hashedNonce = AuthService.shared.prepareAppleSignIn() else {
                                    print("[LoginView] Sign in with Apple ERROR: failed to generate nonce")
                                    Task { @MainActor in
                                        errorMessage = "Unable to generate a secure sign-in token. Please try again."
                                    }
                                    return
                                }
                                print("[LoginView] Sign in with Apple: nonce prepared, requesting scopes [fullName, email]")
                                request.requestedScopes = [.fullName, .email]
                                request.nonce = hashedNonce
                            } onCompletion: { result in
                                switch result {
                                case .success(let authorization):
                                    print("[LoginView] Sign in with Apple: ASAuthorization succeeded, passing to AuthService")
                                    Task { @MainActor in
                                        isLoading    = true
                                        errorMessage = nil
                                        do {
                                            try await AuthService.shared.signInWithApple(authorization: authorization)
                                            print("[LoginView] Sign in with Apple: AuthService completed successfully")
                                        } catch {
                                            print("[LoginView] Sign in with Apple ERROR: \(error.localizedDescription)")
                                            print("[LoginView] Sign in with Apple ERROR detail: \(error)")
                                            errorMessage = "Sign in with Apple failed: \(error.localizedDescription)"
                                        }
                                        isLoading = false
                                    }
                                case .failure(let error):
                                    let asError = error as? ASAuthorizationError
                                    if asError?.code == .canceled {
                                        print("[LoginView] Sign in with Apple: user canceled")
                                        return
                                    }
                                    print("[LoginView] Sign in with Apple ERROR (ASAuthorization): \(error.localizedDescription)")
                                    Task { @MainActor in
                                        errorMessage = "Apple sign-in error: \(error.localizedDescription)"
                                    }
                                }
                            }
                            .signInWithAppleButtonStyle(.white)
                            .frame(height: 52)
                            .cornerRadius(14)
                        }
                        .padding(.horizontal, 24)

                        // MARK: Privacy & Terms Links (required by Apple for pre-signup visibility)
                        HStack(spacing: 4) {
                            Text("By signing in you agree to our")
                                .font(.legoCaption)
                                .foregroundColor(.secondaryText)
                            Button("Privacy Policy") { showPrivacyPolicy = true }
                                .font(.legoCaption).foregroundColor(.legoYellow)
                            Text("and")
                                .font(.legoCaption).foregroundColor(.secondaryText)
                            Button("Terms") { showTermsOfService = true }
                                .font(.legoCaption).foregroundColor(.legoYellow)
                        }
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                        Color.clear.frame(height: 40)
                    }
                }
            }
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView()
            }
            .navigationDestination(isPresented: $showForgotPassword) {
                ForgotPasswordView()
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showPrivacyPolicy) {
            SafariWebView(url: privacyURL)
        }
        .sheet(isPresented: $showTermsOfService) {
            SafariWebView(url: termsURL)
        }
    }

    private func performLogin() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, !password.isEmpty else { return }
        isLoading    = true
        errorMessage = nil
        Task { @MainActor in
            do {
                try await AuthService.shared.signIn(email: trimmedEmail, password: password)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

#Preview {
    LoginView()
}

// MARK: - EULA Agreement Gate (Apple Guideline 1.2)
//
// Shown by ContentView whenever `eulaAccepted == false`. This is the
// EXPLICIT agreement gate Apple requires before a user can register OR
// log in — the passive "by signing in you agree" line on the login
// screen is not sufficient on its own. We surface Apple's standard EULA
// (Licensed Application End User License Agreement, Schedule 1 of the
// Apple Developer Program), our own Privacy Policy, and the in-app
// Terms of Service; the user must tap "I Agree" before LoginView is
// shown. The acceptance is persisted in UserDefaults (eulaAccepted)
// and, on first sign-in, mirrored to the user's Firestore record by
// ContentView so we have a per-user record of consent.

struct EULAAgreementView: View {

    @AppStorage("eulaAccepted") private var eulaAccepted = false

    @State private var hasCheckedAgree = false
    @State private var showPrivacy = false
    @State private var showTerms   = false
    @State private var showAppleEULA = false

    // Apple's standard licensed-application EULA (kept verbatim, summarized).
    private let appleEULAURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    private let privacyURL   = URL(string: "https://blockmasterjames-cyber.github.io/brickfeed-legal/privacy")!
    private let termsURL     = URL(string: "https://blockmasterjames-cyber.github.io/brickfeed-legal/terms")!

    var body: some View {
        ZStack {
            Color.darkBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 14) {
                    BrickFeedLogo()
                        .scaleEffect(1.2)
                        .padding(.top, 40)

                    Text("Welcome to BrickFeed")
                        .font(.legoScreenTitle)
                        .foregroundColor(.lightText)

                    Text("Before you continue, please review and agree to the terms below.")
                        .font(.legoBody)
                        .foregroundColor(.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.bottom, 16)

                // Scrollable EULA / community rules summary
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {

                        ruleHeader("Community Rules", icon: "person.3.fill")
                        rule("No objectionable content — no bullying, hate speech, harassment, sexual content, violence, or anything inappropriate for kids.")
                        rule("No spam, scams, or impersonation.")
                        rule("Be respectful — this app is built around LEGO® building and is welcoming to kids.")

                        ruleHeader("Zero Tolerance", icon: "exclamationmark.shield.fill")
                        rule("Objectionable content and abusive users are removed within 24 hours of being reported.")
                        rule("You can report any post, comment, or message using the flag icon.")
                        rule("You can block any user from their profile or from any of their content — blocking is instant and persists across devices.")

                        ruleHeader("End User License Agreement", icon: "doc.text.fill")
                        Text("BrickFeed is licensed under Apple's standard Licensed Application End User License Agreement (EULA). By tapping \"I Agree\" you accept that EULA, BrickFeed's Terms of Service, and BrickFeed's Privacy Policy.")
                            .font(.legoBody).foregroundColor(.lightText)
                            .fixedSize(horizontal: false, vertical: true)

                        VStack(spacing: 8) {
                            documentLink("View Apple's Standard EULA") { showAppleEULA = true }
                            documentLink("View BrickFeed Terms of Service") { showTerms = true }
                            documentLink("View BrickFeed Privacy Policy") { showPrivacy = true }
                        }
                        .padding(.top, 4)

                        Color.clear.frame(height: 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
                .background(Color.cardBackground)
                .cornerRadius(16)
                .padding(.horizontal, 16)

                // Agree checkbox + button
                VStack(spacing: 14) {
                    Button {
                        hasCheckedAgree.toggle()
                    } label: {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: hasCheckedAgree ? "checkmark.square.fill" : "square")
                                .font(.system(size: 22))
                                .foregroundColor(hasCheckedAgree ? .legoYellow : .secondaryText)
                            Text("I have read and agree to the End User License Agreement, Terms of Service, and Privacy Policy. I understand that BrickFeed does not tolerate objectionable content or abusive users.")
                                .font(.legoCaption)
                                .foregroundColor(.lightText)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)

                    Button {
                        eulaAccepted = true
                    } label: {
                        Text("I Agree — Continue")
                            .font(.legoCardTitle)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(hasCheckedAgree ? Color.legoRed : Color.legoRed.opacity(0.35))
                            .cornerRadius(14)
                    }
                    .disabled(!hasCheckedAgree)
                    .padding(.horizontal, 16)
                }
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showPrivacy)   { SafariWebView(url: privacyURL) }
        .sheet(isPresented: $showTerms)     { SafariWebView(url: termsURL) }
        .sheet(isPresented: $showAppleEULA) { SafariWebView(url: appleEULAURL) }
    }

    // MARK: - Helpers

    private func ruleHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).foregroundColor(.legoYellow)
            Text(title)
                .font(.legoCardTitle)
                .foregroundColor(.legoYellow)
        }
        .padding(.top, 6)
    }

    private func rule(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(.successGreen)
                .padding(.top, 2)
            Text(text)
                .font(.legoBody)
                .foregroundColor(.lightText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func documentLink(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: "arrow.up.right.square.fill")
                    .foregroundColor(.legoYellow)
                Text(label)
                    .font(.legoBody)
                    .foregroundColor(.legoYellow)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondaryText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.darkBackground)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

#Preview("EULA") {
    EULAAgreementView()
}

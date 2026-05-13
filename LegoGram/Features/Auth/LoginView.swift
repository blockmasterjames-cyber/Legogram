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

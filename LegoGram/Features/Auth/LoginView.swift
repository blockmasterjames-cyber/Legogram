import SwiftUI
import AuthenticationServices

/// The main login screen shown when the user is not authenticated.
/// Allows sign in with email/password, Sign in with Apple, navigation to sign up, and forgot password.
struct LoginView: View {

    @State private var email        = ""
    @State private var password     = ""
    @State private var isLoading    = false
    @State private var errorMessage: String?
    @State private var showSignUp          = false
    @State private var showForgotPassword  = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 36) {

                        // MARK: Logo
                        BrickFeedLogo()
                            .scaleEffect(1.4)
                            .padding(.top, 70)
                            .padding(.bottom, 8)

                        // MARK: Fields
                        VStack(spacing: 14) {
                            // Email
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

                            // Password
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

                            // Log In button
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

                            // Forgot Password link
                            Button("Forgot Password?") {
                                showForgotPassword = true
                            }
                            .font(.legoBody)
                            .foregroundColor(.legoYellow)

                            // Divider with OR
                            HStack {
                                Rectangle()
                                    .fill(Color.secondaryText.opacity(0.4))
                                    .frame(height: 1)
                                Text("OR")
                                    .font(.legoCaption)
                                    .foregroundColor(.secondaryText)
                                    .padding(.horizontal, 10)
                                Rectangle()
                                    .fill(Color.secondaryText.opacity(0.4))
                                    .frame(height: 1)
                            }

                            // Create Account button
                            Button {
                                showSignUp = true
                            } label: {
                                Text("Create Account")
                                    .font(.legoCardTitle)
                                    .foregroundColor(.darkBackground)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                                    .background(Color.legoYellow)
                                    .cornerRadius(14)
                            }

                            // Sign in with Apple (required by App Store for apps with social login)
                            SignInWithAppleButton(.signIn) { request in
                                guard let hashedNonce = AuthService.shared.prepareAppleSignIn() else {
                                    errorMessage = "Unable to generate a secure nonce. Please try again."
                                    return
                                }
                                request.requestedScopes = [.fullName, .email]
                                request.nonce = hashedNonce
                            } onCompletion: { result in
                                switch result {
                                case .success(let authorization):
                                    isLoading = true
                                    errorMessage = nil
                                    Task { @MainActor in
                                        do {
                                            try await AuthService.shared.signInWithApple(authorization: authorization)
                                        } catch {
                                            errorMessage = error.localizedDescription
                                        }
                                        isLoading = false
                                    }
                                case .failure(let error):
                                    // User cancelled (ASAuthorizationError.canceled) is not a real error
                                    if (error as? ASAuthorizationError)?.code == .canceled {
                                        return
                                    }
                                    errorMessage = error.localizedDescription
                                }
                            }
                            .signInWithAppleButtonStyle(.white)
                            .frame(height: 52)
                            .cornerRadius(14)
                        }
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
    }

    // MARK: - Login Action

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

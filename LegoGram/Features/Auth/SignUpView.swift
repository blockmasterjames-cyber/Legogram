import SwiftUI

/// The account creation screen.
/// Creates a Firebase Auth account, saves the user profile to Firestore,
/// then navigates the user directly to the main app via the auth state listener.
struct SignUpView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var displayName      = ""
    @State private var username         = ""
    @State private var email            = ""
    @State private var password         = ""
    @State private var confirmPassword  = ""
    @State private var isLoading        = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color.darkBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {

                    // MARK: Logo
                    BrickFeedLogo()
                        .scaleEffect(1.2)
                        .padding(.top, 50)
                        .padding(.bottom, 4)

                    Text("Create Your Account")
                        .font(.legoCardTitle)
                        .foregroundColor(.lightText)

                    // MARK: Fields
                    VStack(spacing: 14) {

                        // Display Name
                        fieldView(
                            placeholder: "Display Name",
                            icon: "person.fill",
                            text: $displayName
                        )

                        // Username (with @ prefix)
                        HStack(spacing: 0) {
                            Text("@")
                                .font(.legoBody)
                                .foregroundColor(.secondaryText)
                                .padding(.leading, 14)
                            TextField("username", text: $username)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .padding(.vertical, 16)
                                .padding(.horizontal, 8)
                                .foregroundColor(.lightText)
                        }
                        .background(Color.cardBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.secondaryText.opacity(0.3), lineWidth: 1)
                        )

                        // Email
                        fieldView(
                            placeholder: "Email",
                            icon: "envelope.fill",
                            text: $email,
                            keyboardType: .emailAddress
                        )

                        // Password
                        secureFieldView(placeholder: "Password", text: $password)

                        // Confirm Password
                        secureFieldView(placeholder: "Confirm Password", text: $confirmPassword)
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

                    // MARK: Create Account Button
                    Button(action: performSignUp) {
                        Group {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Create Account")
                                    .font(.legoCardTitle)
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.legoRed)
                        .cornerRadius(14)
                    }
                    .disabled(isLoading)
                    .padding(.horizontal, 24)

                    // MARK: Back to Login
                    Button("Back to Login") {
                        dismiss()
                    }
                    .font(.legoBody)
                    .foregroundColor(.legoYellow)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
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
                .foregroundColor(.secondaryText)
                .frame(width: 20)
                .padding(.leading, 14)
            TextField(placeholder, text: text)
                .keyboardType(keyboardType)
                .autocapitalization(keyboardType == .emailAddress ? .none : .words)
                .disableAutocorrection(keyboardType == .emailAddress)
                .padding(.vertical, 16)
                .padding(.trailing, 14)
                .foregroundColor(.lightText)
        }
        .background(Color.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondaryText.opacity(0.3), lineWidth: 1)
        )
    }

    private func secureFieldView(placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.fill")
                .foregroundColor(.secondaryText)
                .frame(width: 20)
                .padding(.leading, 14)
            SecureField(placeholder, text: text)
                .padding(.vertical, 16)
                .padding(.trailing, 14)
                .foregroundColor(.lightText)
        }
        .background(Color.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondaryText.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Sign Up Action

    private func performSignUp() {
        // Validate fields
        guard !displayName.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter your display name."
            return
        }
        let trimmedUsername = username.trimmingCharacters(in: .whitespaces)
        guard !trimmedUsername.isEmpty else {
            errorMessage = "Please enter a username."
            return
        }
        guard !trimmedUsername.contains(" ") else {
            errorMessage = "Username cannot contain spaces."
            return
        }
        guard !email.isEmpty else {
            errorMessage = "Please enter your email."
            return
        }
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            return
        }
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }

        isLoading    = true
        errorMessage = nil

        Task {
            do {
                try await AuthService.shared.signUp(
                    email: email,
                    password: password,
                    username: trimmedUsername,
                    displayName: displayName.trimmingCharacters(in: .whitespaces)
                )
                // ContentView's auth state listener handles navigation automatically
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

import SwiftUI

/// The password reset screen.
/// Sends a Firebase Auth password reset email and shows success or error feedback.
struct ForgotPasswordView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var email        = ""
    @State private var isLoading    = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    var body: some View {
        ZStack {
            Color.darkBackground.ignoresSafeArea()

            VStack(spacing: 32) {

                // MARK: Logo
                BrickFeedLogo()
                    .scaleEffect(1.2)
                    .padding(.top, 60)

                // MARK: Heading
                VStack(spacing: 8) {
                    Image(systemName: "lock.rotation")
                        .font(.system(size: 48))
                        .foregroundColor(.legoYellow)

                    Text("Reset Password")
                        .font(.legoScreenTitle)
                        .foregroundColor(.lightText)

                    Text("Enter your email and we'll send you a reset link.")
                        .font(.legoBody)
                        .foregroundColor(.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // MARK: Email Field
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
                    .padding(.horizontal, 24)

                // MARK: Success / Error messages
                Group {
                    if let success = successMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.successGreen)
                            Text(success)
                                .font(.legoBody)
                                .foregroundColor(.successGreen)
                        }
                        .padding(.horizontal, 24)
                    } else if let error = errorMessage {
                        Text(error)
                            .font(.legoCaption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                }

                // MARK: Send Reset Email Button
                Button(action: performPasswordReset) {
                    Group {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Send Reset Email")
                                .font(.legoCardTitle)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.legoRed)
                    .cornerRadius(14)
                }
                .disabled(isLoading || email.isEmpty)
                .padding(.horizontal, 24)

                // MARK: Back to Login
                Button("Back to Login") {
                    dismiss()
                }
                .font(.legoBody)
                .foregroundColor(.legoYellow)

                Spacer()
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
    }

    // MARK: - Password Reset Action

    private func performPasswordReset() {
        guard !email.isEmpty else { return }
        isLoading      = true
        errorMessage   = nil
        successMessage = nil

        Task {
            do {
                try await AuthService.shared.sendPasswordReset(to: email)
                successMessage = "Check your email for a password reset link."
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

#Preview {
    ForgotPasswordView()
}

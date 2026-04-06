import SwiftUI

/// Shown when a kid (under 13) account tries to turn OFF Kid Safe Mode.
/// Requires parent/guardian email approval before the mode is disabled.
struct ParentalApprovalView: View {

    @Binding var kidSafeMode: Bool
    @Environment(\.dismiss) private var dismiss

    @State private var parentEmail = ""
    @State private var isSending = false
    @State private var emailSent = false
    @State private var errorMessage: String?
    @FocusState private var emailFocused: Bool

    private var storedParentEmail: String {
        UserSession.shared.currentUser?.parentEmail ?? ""
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        // Icon
                        Image(systemName: "shield.fill")
                            .font(.system(size: 72))
                            .foregroundColor(.legoYellow)
                            .padding(.top, 32)

                        // Title
                        VStack(spacing: 8) {
                            Text("Parent Approval Required")
                                .font(.legoScreenTitle)
                                .foregroundColor(.lightText)
                                .multilineTextAlignment(.center)

                            Text("To turn off Kid Safe Mode, a parent or guardian must approve this change.")
                                .font(.legoBody)
                                .foregroundColor(.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        if emailSent {
                            // Success state
                            VStack(spacing: 16) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 56))
                                    .foregroundColor(.successGreen)

                                Text("Email Sent!")
                                    .font(.legoCardTitle).foregroundColor(.lightText)

                                Text("An approval request has been sent to your parent or guardian at \(parentEmail.isEmpty ? storedParentEmail : parentEmail).\n\nKid Safe Mode will remain ON until they approve.")
                                    .font(.legoBody)
                                    .foregroundColor(.secondaryText)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)

                                Button { dismiss() } label: {
                                    Text("Got It")
                                        .font(.legoCardTitle)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(Color.legoYellow)
                                        .foregroundColor(.darkBackground)
                                        .cornerRadius(14)
                                }
                                .padding(.horizontal)
                            }
                        } else {
                            // Input state
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Parent or Guardian Email")
                                    .font(.legoCardTitle).foregroundColor(.lightText)
                                    .padding(.horizontal)

                                if !storedParentEmail.isEmpty {
                                    HStack(spacing: 10) {
                                        Image(systemName: "envelope.fill")
                                            .foregroundColor(.legoYellow)
                                        Text(storedParentEmail)
                                            .font(.legoBody).foregroundColor(.lightText)
                                    }
                                    .padding(14)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.cardBackground)
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                                } else {
                                    HStack(spacing: 10) {
                                        Image(systemName: "envelope.fill")
                                            .foregroundColor(.secondaryText)
                                        TextField("parent@example.com", text: $parentEmail)
                                            .foregroundColor(.lightText)
                                            .font(.legoBody)
                                            .keyboardType(.emailAddress)
                                            .autocapitalization(.none)
                                            .autocorrectionDisabled()
                                            .focused($emailFocused)
                                    }
                                    .padding(14)
                                    .background(Color.cardBackground)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(emailFocused ? Color.legoYellow.opacity(0.6) : Color.clear, lineWidth: 1.5)
                                    )
                                    .padding(.horizontal)
                                }

                                if let error = errorMessage {
                                    Text(error)
                                        .font(.legoCaption).foregroundColor(.legoRed)
                                        .padding(.horizontal)
                                }

                                // Explanation
                                HStack(spacing: 8) {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(.legoYellow)
                                    Text("Your parent will receive an email with instructions to approve this change. Kid Safe Mode stays ON until they do.")
                                        .font(.legoCaption).foregroundColor(.secondaryText)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(12)
                                .background(Color.cardBackground)
                                .cornerRadius(12)
                                .padding(.horizontal)

                                // Send button
                                Button {
                                    sendApprovalRequest()
                                } label: {
                                    HStack(spacing: 10) {
                                        if isSending {
                                            ProgressView().tint(.darkBackground)
                                        } else {
                                            Image(systemName: "paperplane.fill")
                                        }
                                        Text(isSending ? "Sending…" : "Send Approval Request")
                                    }
                                    .font(.legoCardTitle)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(canSend ? Color.legoYellow : Color.legoYellow.opacity(0.4))
                                    .foregroundColor(.darkBackground)
                                    .cornerRadius(14)
                                }
                                .disabled(!canSend || isSending)
                                .padding(.horizontal)
                            }
                        }

                        Color.clear.frame(height: 40)
                    }
                }
            }
            .navigationTitle("Kid Safe Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.cardBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.legoYellow)
                    }
                }
            }
        }
    }

    private var canSend: Bool {
        let email = parentEmail.isEmpty ? storedParentEmail : parentEmail
        return email.contains("@") && email.contains(".")
    }

    private func sendApprovalRequest() {
        let email = parentEmail.isEmpty ? storedParentEmail : parentEmail
        guard email.contains("@") else {
            errorMessage = "Please enter a valid email address."
            return
        }
        isSending = true
        errorMessage = nil

        // Save parent email to Firestore if newly provided
        if parentEmail.isEmpty == false, var user = UserSession.shared.currentUser {
            user.parentEmail = parentEmail
            Task { try? await FirebaseService.shared.saveUser(user) }
        }

        // Simulate sending the approval email
        // In production this would call a Cloud Function or email service
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await MainActor.run {
                isSending = false
                emailSent = true
                // Keep kid safe mode ON — parent hasn't approved yet
                kidSafeMode = true
            }
        }
    }
}

#Preview {
    ParentalApprovalView(kidSafeMode: .constant(true))
}

import SwiftUI
import PhotosUI

/// Age verification screen for Direct Messages.
/// Sprint 5 — Feature 11.
/// This is a placeholder UI — real ID verification would require a backend service.
struct AgeVerificationView: View {

    @AppStorage("dm_ageVerified") private var ageVerified = false
    @Environment(\.dismiss) private var dismiss

    @State private var selectedItem: PhotosPickerItem?
    @State private var uploadedIDImage: UIImage?
    @State private var isSubmitting = false
    @State private var showingConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {

                        // Header icon
                        ZStack {
                            Circle()
                                .fill(Color.legoYellow.opacity(0.15))
                                .frame(width: 100, height: 100)
                            Image(systemName: "person.text.rectangle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.legoYellow)
                        }
                        .padding(.top, 16)

                        // Title
                        VStack(spacing: 8) {
                            Text("Verify Your Age")
                                .font(.legoScreenTitle)
                                .foregroundColor(.lightText)
                            Text("To use Direct Messages, we need to confirm you're old enough. Please upload a photo of a valid ID.")
                                .font(.legoBody)
                                .foregroundColor(.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal)

                        // Accepted ID types
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Accepted ID types:")
                                .font(.legoCardTitle)
                                .foregroundColor(.legoYellow)

                            idTypeRow(icon: "doc.text.fill", text: "Government-issued ID card")
                            idTypeRow(icon: "airplane.circle.fill", text: "Passport")
                            idTypeRow(icon: "graduationcap.fill", text: "School / Student ID")
                            idTypeRow(icon: "car.fill", text: "Driver's License")
                        }
                        .padding()
                        .background(Color.cardBackground)
                        .cornerRadius(16)
                        .padding(.horizontal)

                        // Upload button / preview
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            if let img = uploadedIDImage {
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 180)
                                        .cornerRadius(14)
                                        .clipped()

                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(.successGreen)
                                        .padding(8)
                                }
                            } else {
                                VStack(spacing: 12) {
                                    Image(systemName: "arrow.up.doc.fill")
                                        .font(.system(size: 36))
                                        .foregroundColor(.legoYellow)
                                    Text("Upload ID Photo")
                                        .font(.legoCardTitle)
                                        .foregroundColor(.legoYellow)
                                    Text("Tap to choose from your library")
                                        .font(.legoCaption)
                                        .foregroundColor(.secondaryText)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 140)
                                .background(Color.cardBackground)
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.legoYellow.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [8]))
                                )
                            }
                        }
                        .padding(.horizontal)
                        .onChange(of: selectedItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let img = UIImage(data: data) {
                                    uploadedIDImage = img
                                }
                            }
                        }

                        // Review note
                        HStack(spacing: 10) {
                            Image(systemName: "clock.badge.checkmark.fill")
                                .foregroundColor(.legoYellow)
                                .font(.system(size: 20))
                            Text("Age verification is reviewed by our safety team within 24 hours.")
                                .font(.legoBody)
                                .foregroundColor(.secondaryText)
                        }
                        .padding()
                        .background(Color.cardBackground)
                        .cornerRadius(12)
                        .padding(.horizontal)

                        // Submit / Pending button
                        if ageVerified {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.successGreen)
                                Text("Verified — Messaging Enabled!")
                                    .font(.legoCardTitle)
                                    .foregroundColor(.successGreen)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.successGreen.opacity(0.15))
                            .cornerRadius(14)
                            .padding(.horizontal)
                        } else {
                            Button { submitVerification() } label: {
                                HStack(spacing: 8) {
                                    if isSubmitting {
                                        ProgressView().tint(.white)
                                        Text("Submitting...").font(.legoCardTitle).foregroundColor(.white)
                                    } else if uploadedIDImage != nil {
                                        Image(systemName: "paperplane.fill")
                                        Text("Submit for Review").font(.legoCardTitle)
                                    } else {
                                        Image(systemName: "clock.fill")
                                        Text("Verification Pending").font(.legoCardTitle)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(uploadedIDImage != nil ? Color.legoYellow : Color.secondaryText.opacity(0.3))
                                .foregroundColor(uploadedIDImage != nil ? .darkBackground : .secondaryText)
                                .cornerRadius(14)
                            }
                            .disabled(uploadedIDImage == nil || isSubmitting)
                            .padding(.horizontal)
                        }

                        // Privacy note
                        Text("Your ID is used only to verify your age and is not stored permanently. See our Privacy Policy for details.")
                            .font(.legoCaption)
                            .foregroundColor(.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Color.clear.frame(height: 20)
                    }
                }
            }
            .navigationTitle("Age Verification")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.cardBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.legoYellow)
                }
            }
        }
        .alert("Submitted!", isPresented: $showingConfirmation) {
            Button("Start Messaging") {
                ageVerified = true
                dismiss()
            }
        } message: {
            Text("Thanks for submitting your ID! For this demo, your account is now verified and you can use Direct Messages.")
        }
    }

    // MARK: - ID Type Row

    private func idTypeRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.legoYellow)
                .font(.system(size: 16))
                .frame(width: 24)
            Text(text)
                .font(.legoBody)
                .foregroundColor(.lightText)
        }
    }

    // MARK: - Submit

    private func submitVerification() {
        guard uploadedIDImage != nil else { return }
        isSubmitting = true

        // Simulate review delay — in production this sends to a backend
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isSubmitting = false
            showingConfirmation = true
        }
    }
}

#Preview {
    AgeVerificationView()
}

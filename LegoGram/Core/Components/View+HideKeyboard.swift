import SwiftUI

// MARK: - Keyboard Dismissal Helpers (Sprint 5)

extension View {
    /// Sends resignFirstResponder to dismiss the keyboard.
    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }

    /// Adds a background tap gesture that dismisses the keyboard when the user
    /// taps anywhere outside a text field on the current screen.
    func dismissKeyboardOnTap() -> some View {
        self.background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { hideKeyboard() }
        )
    }
}

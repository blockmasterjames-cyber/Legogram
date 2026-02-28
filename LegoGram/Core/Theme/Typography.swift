import SwiftUI

/// LegoGram's text size and weight rules.
/// Using these keeps every screen's text looking the same.
extension Font {

    /// Big bold title shown at the top of the app — 32pt bold.
    static let legoAppTitle: Font = .system(size: 32, weight: .bold, design: .rounded)

    /// Bold heading at the top of each screen — 24pt bold.
    static let legoScreenTitle: Font = .system(size: 24, weight: .bold, design: .rounded)

    /// Semi-bold title on a post card or list row — 18pt semibold.
    static let legoCardTitle: Font = .system(size: 18, weight: .semibold, design: .rounded)

    /// Regular readable text for descriptions and body content — 16pt.
    static let legoBody: Font = .system(size: 16, weight: .regular, design: .rounded)

    /// Small text used under photos or for extra details — 12pt.
    static let legoCaption: Font = .system(size: 12, weight: .regular, design: .rounded)
}

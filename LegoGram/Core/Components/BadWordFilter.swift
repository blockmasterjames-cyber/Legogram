import Foundation

/// A kid-safe bad word filter for BrickFeed.
/// Replaces inappropriate words with stars so the app stays fun and safe for everyone.
/// Applied to all comments, bios, and post descriptions before they are stored or displayed.
struct BadWordFilter {

    // MARK: - Word List
    // Focused on words kids might actually encounter — keeps the list appropriate for a children's app.
    private static let bannedWords: Set<String> = [
        "damn", "damnit", "crap", "crappy", "hell", "heck",
        "ass", "asses", "butt", "butts",
        "stupid", "idiot", "idiots", "moron", "morons",
        "dumb", "dummy", "dummies", "loser", "losers",
        "shut up", "shutup",
        "hate", "hater", "haters",
        "kill", "killed", "killer",
        "die", "died",
        "ugly", "fugly",
        "fat", "fatso",
        "nerd", "nerds",
        "freak", "freaks",
        "jerk", "jerks",
        "suck", "sucks", "sucked",
        "cuss", "curse",
        "poop", "pee",
        "gross", "nasty",
    ]

    // MARK: - Filter

    /// Returns the text with any banned words replaced by asterisks of the same length.
    /// For example: "that's stupid" → "that's ******"
    static func filter(_ text: String) -> String {
        var result = text
        for word in bannedWords {
            // Case-insensitive whole-word search
            let pattern = "(?i)\\b\(NSRegularExpression.escapedPattern(for: word))\\b"
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(result.startIndex..., in: result)
                result = regex.stringByReplacingMatches(
                    in: result,
                    range: range,
                    withTemplate: String(repeating: "*", count: word.count)
                )
            }
        }
        return result
    }

    /// Returns true if the text contains any banned words.
    static func containsBadWords(_ text: String) -> Bool {
        let lower = text.lowercased()
        return bannedWords.contains { lower.contains($0) }
    }
}

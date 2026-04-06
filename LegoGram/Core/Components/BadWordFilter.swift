import Foundation

/// A kid-safe bad word filter for BrickFeed.
/// Replaces inappropriate words with stars so the app stays fun and safe for everyone.
/// Applied to all comments, bios, post descriptions, display names, and DM messages.
/// Filtered content is logged to Firestore moderation_logs for review.
struct BadWordFilter {

    // MARK: - Word List (50+ words)
    private static let bannedWords: Set<String> = [
        // Profanity
        "damn", "damnit", "dammit", "crap", "crappy",
        "hell", "heck",
        "ass", "asses", "asshole",
        "bastard", "bastards",
        "bitch", "bitches",
        "cuss", "curse",
        "frick", "fricking",

        // Body / toilet humor (kid-relevant)
        "butt", "butts",
        "poop", "pee", "pee-pee", "poopy",
        "fart", "farted",

        // Insults
        "stupid", "idiot", "idiots", "moron", "morons",
        "dumb", "dummy", "dummies",
        "loser", "losers",
        "nerd", "nerds",
        "freak", "freaks",
        "jerk", "jerks",
        "dork", "dorks",
        "geek",
        "wimp", "wimps",
        "crybaby",
        "coward",

        // Bullying phrases
        "shut up", "shutup",
        "go away",
        "nobody likes you",
        "you suck",

        // Hate / aggression
        "hate", "hater", "haters",
        "kill", "killed", "killer",
        "die", "died",
        "gross", "nasty",

        // Appearance
        "ugly", "fugly",
        "fat", "fatso", "fatty",
        "skinny",

        // Misc inappropriate
        "suck", "sucks", "sucked",
        "crap",
        "pervert",
        "creep", "creepy",
        "weirdo", "weirdos",
        "psycho",
    ]

    // MARK: - Leet Speak Normalization
    // Converts common substitutions to normal letters before checking
    private static let leetMap: [Character: Character] = [
        "0": "o",
        "1": "i",
        "3": "e",
        "4": "a",
        "5": "s",
        "7": "t",
        "@": "a",
        "$": "s",
        "!": "i",
        "+": "t",
    ]

    private static func normalizeLeet(_ text: String) -> String {
        String(text.map { leetMap[$0] ?? $0 })
    }

    // MARK: - Filter

    /// Returns the text with any banned words replaced by asterisks of the same length.
    /// Also checks leet speak variations.
    /// Example: "that's stup1d" → "that's ******"
    static func filter(_ text: String) -> String {
        var result = text

        for word in bannedWords {
            // Direct replacement (case-insensitive, whole-word)
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

        // Second pass: check normalized leet speak version
        let normalized = normalizeLeet(result.lowercased())
        if normalized != result.lowercased() {
            for word in bannedWords {
                let pattern = "(?i)\\b\(NSRegularExpression.escapedPattern(for: word))\\b"
                if let regex = try? NSRegularExpression(pattern: pattern) {
                    // Find matches in normalized version and replace at same positions in result
                    let nsNorm = normalized as NSString
                    let range = NSRange(location: 0, length: nsNorm.length)
                    let matches = regex.matches(in: normalized, range: range)
                    // Process in reverse so offsets stay valid
                    for match in matches.reversed() {
                        if let swiftRange = Range(match.range, in: result) {
                            result.replaceSubrange(swiftRange,
                                with: String(repeating: "*", count: match.range.length))
                        }
                    }
                }
            }
        }

        return result
    }

    /// Returns true if the text contains any banned words (including leet speak).
    static func containsBadWords(_ text: String) -> Bool {
        let lower = text.lowercased()
        let normalized = normalizeLeet(lower)
        return bannedWords.contains { word in
            lower.range(of: "\\b\(NSRegularExpression.escapedPattern(for: word))\\b",
                        options: [.regularExpression, .caseInsensitive]) != nil ||
            normalized.range(of: "\\b\(NSRegularExpression.escapedPattern(for: word))\\b",
                             options: [.regularExpression, .caseInsensitive]) != nil
        }
    }

    /// Validates a username/display name. Returns an error string if invalid, nil if OK.
    static func validateUsername(_ text: String) -> String? {
        if containsBadWords(text) {
            return "Username contains inappropriate content. Please choose a different name."
        }
        return nil
    }
}

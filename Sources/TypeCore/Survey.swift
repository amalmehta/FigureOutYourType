import Foundation

/// A short, optional survey about the user. Answers go to Claude alongside the photos.
/// Keep in sync with SURVEY in web/app.js.
public struct Survey: Equatable, Sendable {
    public static let noticeFirstOptions = ["Smile and eyes", "Build", "Style", "Energy and vibe", "Something else"]
    public static let qualityOptions = ["Warmth", "Humor", "Ambition", "Calm", "Adventurousness",
                                        "Intelligence", "Emotional openness", "Loyalty"]
    public static let maxQualities = 3
    public static let valuesOptions = ["Very important to share", "Nice to have", "Doesn't matter to me"]

    public var noticeFirst: String?
    public var qualities: [String]
    public var values: String?
    public var dealBreakers: String
    public var anythingElse: String

    public init(noticeFirst: String? = nil, qualities: [String] = [], values: String? = nil,
                dealBreakers: String = "", anythingElse: String = "") {
        self.noticeFirst = noticeFirst
        self.qualities = qualities
        self.values = values
        self.dealBreakers = dealBreakers
        self.anythingElse = anythingElse
    }

    public mutating func toggleQuality(_ quality: String) {
        if let index = qualities.firstIndex(of: quality) {
            qualities.remove(at: index)
        } else if qualities.count < Self.maxQualities {
            qualities.append(quality)
        }
    }

    public var isEmpty: Bool { promptText == nil }

    /// The answers as text for Claude, or nil when nothing was answered.
    public var promptText: String? {
        var lines: [String] = []
        if let noticeFirst { lines.append("- What I notice first: \(noticeFirst)") }
        if !qualities.isEmpty { lines.append("- Qualities that draw me in most: \(qualities.joined(separator: ", "))") }
        if let values { lines.append("- Shared spiritual beliefs or values: \(values)") }
        let dealBreakers = dealBreakers.trimmingCharacters(in: .whitespacesAndNewlines)
        if !dealBreakers.isEmpty { lines.append("- Deal-breakers: \(dealBreakers)") }
        let anythingElse = anythingElse.trimmingCharacters(in: .whitespacesAndNewlines)
        if !anythingElse.isEmpty { lines.append("- Anything else: \(anythingElse)") }
        guard !lines.isEmpty else { return nil }
        return "About me, from a short survey:\n" + lines.joined(separator: "\n")
    }
}

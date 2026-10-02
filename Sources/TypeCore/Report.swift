import Foundation

/// The finished read on someone's type, as returned by Claude.
public struct TypeReport: Codable, Equatable, Sendable {
    public var headline: String
    public var summary: String
    public var physical: TypeSection
    public var emotional: TypeSection
    public var spiritual: TypeSection
    public var lifestyle: TypeSection
    public var commonThreads: [String]
    public var outliers: [String]
    public var caveats: String

    public init(headline: String, summary: String, physical: TypeSection, emotional: TypeSection,
                spiritual: TypeSection, lifestyle: TypeSection, commonThreads: [String],
                outliers: [String], caveats: String) {
        self.headline = headline
        self.summary = summary
        self.physical = physical
        self.emotional = emotional
        self.spiritual = spiritual
        self.lifestyle = lifestyle
        self.commonThreads = commonThreads
        self.outliers = outliers
        self.caveats = caveats
    }

    /// The four dimensions in display order, with their headings.
    public var sections: [(title: String, section: TypeSection)] {
        [("Physical", physical), ("Emotional", emotional), ("Spiritual", spiritual), ("Style & Lifestyle", lifestyle)]
    }
}

public struct TypeSection: Codable, Equatable, Sendable {
    public var summary: String
    public var traits: [Trait]

    public init(summary: String, traits: [Trait]) {
        self.summary = summary
        self.traits = traits
    }
}

public struct Trait: Codable, Equatable, Sendable, Identifiable {
    public var name: String
    public var detail: String
    public var confidence: Confidence
    public var id: String { name }

    public init(name: String, detail: String, confidence: Confidence) {
        self.name = name
        self.detail = detail
        self.confidence = confidence
    }
}

public enum Confidence: String, Codable, Sendable, CaseIterable {
    case low, medium, high
}

/// The JSON schema sent as `output_config.format`, mirroring `TypeReport`.
enum ReportSchema {
    static let section: [String: Any] = [
        "type": "object",
        "properties": [
            "summary": ["type": "string"],
            "traits": [
                "type": "array",
                "items": [
                    "type": "object",
                    "properties": [
                        "name": ["type": "string"],
                        "detail": ["type": "string"],
                        "confidence": ["type": "string", "enum": Confidence.allCases.map(\.rawValue)],
                    ],
                    "required": ["name", "detail", "confidence"],
                    "additionalProperties": false,
                ],
            ],
        ],
        "required": ["summary", "traits"],
        "additionalProperties": false,
    ]

    static let report: [String: Any] = [
        "type": "object",
        "properties": [
            "headline": ["type": "string"],
            "summary": ["type": "string"],
            "physical": section,
            "emotional": section,
            "spiritual": section,
            "lifestyle": section,
            "commonThreads": ["type": "array", "items": ["type": "string"]],
            "outliers": ["type": "array", "items": ["type": "string"]],
            "caveats": ["type": "string"],
        ],
        "required": ["headline", "summary", "physical", "emotional", "spiritual", "lifestyle",
                     "commonThreads", "outliers", "caveats"],
        "additionalProperties": false,
    ]
}

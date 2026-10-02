import Foundation

public enum AnalyzerError: LocalizedError, Equatable {
    case noAPIKey
    case noPhotos
    case api(status: Int, message: String)
    case declined(String)
    case cutOff
    case unreadableResponse

    public var errorDescription: String? {
        switch self {
        case .noAPIKey: "Add your Anthropic API key in Settings (⌘,) first."
        case .noPhotos: "Add at least one photo first."
        case let .api(status, message): "Claude returned an error (\(status)): \(message)"
        case let .declined(why): "Claude declined to analyze these photos. \(why)"
        case .cutOff: "The answer was cut off before it finished. Try again with fewer photos."
        case .unreadableResponse: "Claude's answer couldn't be read. Try again."
        }
    }
}

/// Sends the people to Claude and turns the answer into a `TypeReport`.
public struct TypeAnalyzer: Sendable {
    public static let model = "claude-opus-5-5"
    static let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    static let systemPrompt = """
    You help someone understand their dating "type". They will show you photos of people they're \
    attracted to, sometimes with a short note about each person. Find the patterns across all of them \
    and describe the type along four dimensions: physical, emotional, spiritual, and style & lifestyle.

    Guidelines:
    - Look for what the people have in common. A trait only counts as part of the type if it shows up \
    across several people; say how many when it helps. Name anyone who breaks the pattern in "outliers".
    - Physical: describe only what is visible — hair, build, height cues, facial hair, grooming, \
    expression, apparent age range, how they carry themselves. Never name or guess race, ethnicity, \
    religion, sexual orientation, health or disability.
    - Emotional and spiritual: base these mainly on the user's notes. Without notes you can only read \
    surface cues (expression, setting, activity, the energy a photo gives off) — say so and mark those \
    traits low confidence.
    - Style & lifestyle: clothing, aesthetic, settings, hobbies or activities visible in the photos or notes.
    - Refer to people as "Person 1", "Person 2", etc. Don't try to identify anyone.
    - Write warmly and directly to the user ("you're drawn to…"). Keep each detail to one or two sentences.
    - "headline" is a short, vivid phrase that sums up the type. "caveats" says plainly what photos \
    can't tell you and how much to trust this read.
    """

    let apiKey: String
    let session: URLSession

    public init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    public func analyze(_ people: [Person]) async throws -> TypeReport {
        var request = URLRequest(url: Self.endpoint, timeoutInterval: 600)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        // Lets the API re-run a declined request on Anthropic's recommended fallback model.
        request.setValue("server-side-fallback-2026-07-01", forHTTPHeaderField: "anthropic-beta")
        request.httpBody = try Self.requestBody(for: people)

        let (data, response) = try await session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else {
            throw AnalyzerError.api(status: status, message: Self.errorMessage(from: data))
        }
        return try Self.parseReport(from: data)
    }

    // MARK: - Request

    static func requestBody(for people: [Person]) throws -> Data {
        let withPhotos = people.filter { !$0.photos.isEmpty }
        guard !withPhotos.isEmpty else { throw AnalyzerError.noPhotos }

        var content: [[String: Any]] = []
        for (index, person) in withPhotos.enumerated() {
            let note = person.note.trimmingCharacters(in: .whitespacesAndNewlines)
            let photoWord = person.photos.count == 1 ? "photo" : "photos"
            var label = "Person \(index + 1) (\(person.photos.count) \(photoWord))"
            label += note.isEmpty ? " — no note." : " — the user's note: \(note)"
            content.append(["type": "text", "text": label])
            for photo in person.photos {
                content.append([
                    "type": "image",
                    "source": ["type": "base64", "media_type": "image/jpeg", "data": photo.jpeg.base64EncodedString()],
                ])
            }
        }
        content.append(["type": "text", "text": "What's my type?"])

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 16000,
            "system": systemPrompt,
            "fallbacks": "default",
            "output_config": [
                "effort": "high",
                "format": ["type": "json_schema", "schema": ReportSchema.report],
            ],
            "messages": [["role": "user", "content": content]],
        ]
        return try JSONSerialization.data(withJSONObject: body)
    }

    // MARK: - Response

    static func parseReport(from data: Data) throws -> TypeReport {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AnalyzerError.unreadableResponse
        }
        switch json["stop_reason"] as? String {
        case "refusal":
            let details = json["stop_details"] as? [String: Any]
            throw AnalyzerError.declined(details?["explanation"] as? String ?? "")
        case "max_tokens":
            throw AnalyzerError.cutOff
        default:
            break
        }
        let blocks = json["content"] as? [[String: Any]] ?? []
        guard let text = blocks.last(where: { $0["type"] as? String == "text" })?["text"] as? String,
              let report = try? JSONDecoder().decode(TypeReport.self, from: Data(text.utf8)) else {
            throw AnalyzerError.unreadableResponse
        }
        return report
    }

    static func errorMessage(from data: Data) -> String {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let error = json["error"] as? [String: Any], let message = error["message"] as? String {
            return message
        }
        return String(data: data, encoding: .utf8)?.prefix(300).description ?? "Unknown error"
    }
}

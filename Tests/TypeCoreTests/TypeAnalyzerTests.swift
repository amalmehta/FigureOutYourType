import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import XCTest
@testable import TypeCore

final class TypeAnalyzerTests: XCTestCase {
    private func samplePNG(width: Int, height: Int) -> Data {
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                                space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.setFillColor(red: 0.9, green: 0.3, blue: 0.5, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(destination, context.makeImage()!, nil)
        CGImageDestinationFinalize(destination)
        return data as Data
    }

    func testImagePrepDownscalesToJPEG() throws {
        let jpeg = try XCTUnwrap(ImagePrep.jpeg(from: samplePNG(width: 3000, height: 2000)))
        let source = try XCTUnwrap(CGImageSourceCreateWithData(jpeg as CFData, nil))
        XCTAssertEqual(CGImageSourceGetType(source) as String?, UTType.jpeg.identifier)
        let props = try XCTUnwrap(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
        XCTAssertEqual(props[kCGImagePropertyPixelWidth] as? Int, ImagePrep.maxPixelSize)
    }

    func testImagePrepRejectsNonImages() {
        XCTAssertNil(ImagePrep.jpeg(from: Data("not an image".utf8)))
    }

    func testRequestBodyLabelsPeopleAndIncludesImages() throws {
        let photo = Photo(jpeg: Data([0xFF, 0xD8, 0xFF]))
        let people = [Person(photos: [photo, photo], note: "kind, outdoorsy"), Person(photos: [photo])]
        let body = try JSONSerialization.jsonObject(with: TypeAnalyzer.requestBody(for: people)) as! [String: Any]

        XCTAssertEqual(body["model"] as? String, "claude-opus-5-5")
        XCTAssertEqual(body["fallbacks"] as? String, "default")
        XCTAssertNil(body["thinking"])
        let config = body["output_config"] as! [String: Any]
        XCTAssertEqual((config["format"] as! [String: Any])["type"] as? String, "json_schema")

        let content = ((body["messages"] as! [[String: Any]])[0]["content"]) as! [[String: Any]]
        XCTAssertEqual(content.filter { $0["type"] as? String == "image" }.count, 3)
        let texts = content.compactMap { $0["text"] as? String }
        XCTAssertEqual(texts[0], "Person 1 (2 photos) — the user's note: kind, outdoorsy")
        XCTAssertEqual(texts[1], "Person 2 (1 photo) — no note.")
        let source = content[1]["source"] as! [String: Any]
        XCTAssertEqual(source["media_type"] as? String, "image/jpeg")
        XCTAssertEqual(source["data"] as? String, Data([0xFF, 0xD8, 0xFF]).base64EncodedString())
    }

    func testRequestBodyNeedsPhotos() {
        XCTAssertThrowsError(try TypeAnalyzer.requestBody(for: [])) {
            XCTAssertEqual($0 as? AnalyzerError, .noPhotos)
        }
    }

    func testSchemaRequiresEveryReportField() {
        let required = Set(ReportSchema.report["required"] as! [String])
        let properties = Set((ReportSchema.report["properties"] as! [String: Any]).keys)
        XCTAssertEqual(required, properties)
    }

    private let sampleReport = TypeReport(
        headline: "Sunlit, creative and quietly confident",
        summary: "You go for warm people with an artsy streak.",
        physical: TypeSection(summary: "Tall and lean.", traits: [Trait(name: "Curly hair", detail: "4 of 5 people.", confidence: .high)]),
        emotional: TypeSection(summary: "Warm.", traits: []),
        spiritual: TypeSection(summary: "Grounded.", traits: [Trait(name: "Nature", detail: "Outdoor settings.", confidence: .low)]),
        lifestyle: TypeSection(summary: "Vintage style.", traits: []),
        commonThreads: ["Easy smiles"], outliers: ["Person 3 is more polished"], caveats: "Photos only go so far."
    )

    private func response(text: String, stopReason: String = "end_turn") -> Data {
        let json: [String: Any] = [
            "content": [["type": "thinking", "thinking": ""], ["type": "text", "text": text]],
            "stop_reason": stopReason,
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    func testParsesReport() throws {
        let text = String(data: try JSONEncoder().encode(sampleReport), encoding: .utf8)!
        XCTAssertEqual(try TypeAnalyzer.parseReport(from: response(text: text)), sampleReport)
    }

    func testRefusalAndCutOff() {
        let refusal = try! JSONSerialization.data(withJSONObject: [
            "content": [], "stop_reason": "refusal", "stop_details": ["explanation": "Policy."],
        ])
        XCTAssertThrowsError(try TypeAnalyzer.parseReport(from: refusal)) {
            XCTAssertEqual($0 as? AnalyzerError, .declined("Policy."))
        }
        XCTAssertThrowsError(try TypeAnalyzer.parseReport(from: response(text: "{", stopReason: "max_tokens"))) {
            XCTAssertEqual($0 as? AnalyzerError, .cutOff)
        }
        XCTAssertThrowsError(try TypeAnalyzer.parseReport(from: response(text: "not json"))) {
            XCTAssertEqual($0 as? AnalyzerError, .unreadableResponse)
        }
    }

    func testErrorMessage() {
        let data = Data(#"{"type":"error","error":{"type":"authentication_error","message":"invalid x-api-key"}}"#.utf8)
        XCTAssertEqual(TypeAnalyzer.errorMessage(from: data), "invalid x-api-key")
    }
}

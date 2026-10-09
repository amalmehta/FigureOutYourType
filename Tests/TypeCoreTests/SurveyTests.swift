import XCTest
@testable import TypeCore

final class SurveyTests: XCTestCase {
    func testEmptySurveyAddsNothing() throws {
        XCTAssertNil(Survey().promptText)
        XCTAssertNil(Survey(dealBreakers: "   ").promptText)
        let body = try JSONSerialization.jsonObject(
            with: TypeAnalyzer.requestBody(for: [Person(photos: [Photo(jpeg: Data([1]))])])) as! [String: Any]
        let content = (body["messages"] as! [[String: Any]])[0]["content"] as! [[String: Any]]
        XCTAssertTrue((content[0]["text"] as! String).hasPrefix("Person 1"))
    }

    func testQualitiesCapAtThreeAndToggle() {
        var survey = Survey()
        for quality in Survey.qualityOptions { survey.toggleQuality(quality) }
        XCTAssertEqual(survey.qualities, Array(Survey.qualityOptions.prefix(3)))
        survey.toggleQuality("Warmth")
        XCTAssertEqual(survey.qualities, ["Humor", "Ambition"])
    }

    func testAnswersComeFirstInRequest() throws {
        let survey = Survey(noticeFirst: "Style", qualities: ["Humor", "Calm"], values: "Nice to have",
                            dealBreakers: " smoking ", anythingElse: "")
        XCTAssertEqual(survey.promptText, """
        About me, from a short survey:
        - What I notice first: Style
        - Qualities that draw me in most: Humor, Calm
        - Shared spiritual beliefs or values: Nice to have
        - Deal-breakers: smoking
        """)
        let body = try JSONSerialization.jsonObject(
            with: TypeAnalyzer.requestBody(for: [Person(photos: [Photo(jpeg: Data([1]))])], survey: survey)) as! [String: Any]
        let content = (body["messages"] as! [[String: Any]])[0]["content"] as! [[String: Any]]
        XCTAssertEqual(content[0]["text"] as? String, survey.promptText)
        XCTAssertTrue((content[1]["text"] as! String).hasPrefix("Person 1"))
    }
}

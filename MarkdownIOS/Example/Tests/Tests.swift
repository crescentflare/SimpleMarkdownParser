import UIKit
import XCTest
@testable import SimpleMarkdownParser

// Test class
class Tests: XCTestCase {
    
    // --
    // MARK: Test cases
    // --

    // Test case with given text and expected markdown tags
    func testFindTagsNewLines() {
        let markdownTextLines = [
            "",
            "",
            "Text",
            "",
            "",
            "",
            "Another",
            ""
        ]
        let expectedTags = [
            WrappedMarkdownTag(type: .Normal, flags: MarkdownTag.FLAG_NONE, text: "Text"),
            WrappedMarkdownTag(type: .Paragraph, weight: 1, flags: MarkdownTag.FLAG_NONE, text: ""),
            WrappedMarkdownTag(type: .Normal, flags: MarkdownTag.FLAG_NONE, text: "Another")
        ]
        assertTags(markdownTextLines, expectedTags: expectedTags)
    }

    
    // --
    // MARK: Helpers
    // --
    
    func assertTags(markdownTextLines: [String], expectedTags: [WrappedMarkdownTag], file: String = #file, line: UInt = #line) {
        let parser = SimpleMarkdownParserSwift()
        let markdownText = markdownTextLines.joinWithSeparator("\n")
        let foundTags = parser.findTags(markdownText)
        for i in 0..<min(foundTags.count, expectedTags.count) {
            let wrappedTag = WrappedMarkdownTag(markdownText: markdownText, tag: foundTags[i])
            if expectedTags[i] != wrappedTag {
                recordFailureWithDescription("Tags not equal, expected: \(expectedTags[i]), but having: \(wrappedTag)", inFile: file, atLine: line, expected: true)
            }
        }
        if expectedTags.count != foundTags.count {
            recordFailureWithDescription("Missing or too many tags, expected: \(expectedTags.count), but having: \(foundTags.count)", inFile: file, atLine: line, expected: true)
        }
        XCTAssertEqual(expectedTags.count, foundTags.count)
    }

}

// Helper class to simply compare tags
class WrappedMarkdownTag: NSObject {
    
    private var type: MarkdownTagType
    private var flags: Int
    private var weight: Int
    private var text: String
    private var extra: String
    
    override var description : String {
        return "{ type: \(type), flags: \(flags), weight: \(weight), text: \(text), extra: \(extra)"
    }
    
    convenience init(type: MarkdownTagType, flags: Int, text: String) {
        self.init(type: type, weight: 0, flags: flags, text: text, extra: "")
    }

    convenience init(type: MarkdownTagType, flags: Int, text: String, extra: String) {
        self.init(type: type, weight: 0, flags: flags, text: text, extra: extra)
    }

    convenience init(type: MarkdownTagType, weight: Int, flags: Int, text: String) {
        self.init(type: type, weight: weight, flags: flags, text: text, extra: "")
    }

    init(type: MarkdownTagType, weight: Int, flags: Int, text: String, extra: String) {
        self.type = type
        self.weight = weight
        self.flags = flags
        self.text = text
        self.extra = extra
    }
    
    convenience init(markdownText: String, tag: MarkdownTag) {
        self.init(
            type: tag.type,
            weight: tag.weight,
            flags: tag.flags,
            text: SimpleMarkdownParserSwift().extractText(markdownText, tag: tag),
            extra: SimpleMarkdownParserSwift().extractExtra(markdownText, tag: tag)
        )
    }
    
    override func isEqual(object: AnyObject?) -> Bool {
        guard let other = object as? WrappedMarkdownTag else { return false }
        return self.type == other.type && self.flags == other.flags && self.weight == other.weight && self.text == other.text && self.extra == other.extra
    }

}

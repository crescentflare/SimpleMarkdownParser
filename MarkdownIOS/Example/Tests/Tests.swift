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

    func testFindTagsHeaders() {
        //Test case with given text and expected markdown tags
        let markdownTextLines = [
            "Some text",
            "",
            "#First header",
            "Additional text",
            "And more",
            "",
            "  ##   Last header",
            "",
            "Final text"
        ]
        let expectedTags = [
            WrappedMarkdownTag(type: .Normal, flags: MarkdownTag.FLAG_NONE, text: "Some text"),
            WrappedMarkdownTag(type: .Paragraph, weight: 2, flags: MarkdownTag.FLAG_NONE, text: ""),
            WrappedMarkdownTag(type: .Header, weight: 1, flags: MarkdownTag.FLAG_NONE, text: "First header"),
            WrappedMarkdownTag(type: .Paragraph, weight: 1, flags: MarkdownTag.FLAG_NONE, text: ""),
            WrappedMarkdownTag(type: .Normal, flags: MarkdownTag.FLAG_NONE, text: "Additional text"),
            WrappedMarkdownTag(type: .Normal, flags: MarkdownTag.FLAG_NONE, text: "And more"),
            WrappedMarkdownTag(type: .Paragraph, weight: 2, flags: MarkdownTag.FLAG_NONE, text: ""),
            WrappedMarkdownTag(type: .Header, weight: 2, flags: MarkdownTag.FLAG_NONE, text: "Last header"),
            WrappedMarkdownTag(type: .Paragraph, weight: 1, flags: MarkdownTag.FLAG_NONE, text: ""),
            WrappedMarkdownTag(type: .Normal, flags: MarkdownTag.FLAG_NONE, text: "Final text")
        ]
        assertTags(markdownTextLines, expectedTags: expectedTags)
    }

    func testFindTagsSections() {
        //Test case with given text and expected markdown tags
        let markdownTextLines = [
            "",
            "",
            "  #A strange indented header",
            "Another piece of text",
            "  ",
            "Text with a space separator to prevent paragraph",
            "",
            "New paragraph",
            "  # Sudden header",
            "Text",
            "",
            "* Bullet item",
            "* Second item",
            "  With some text",
            "",
            "New paragraph"
        ]
        let expectedTags = [
            WrappedMarkdownTag(type: .Header, weight: 1, flags: MarkdownTag.FLAG_NONE, text: "A strange indented header"),
            WrappedMarkdownTag(type: .Paragraph, weight: 1, flags: MarkdownTag.FLAG_NONE, text: ""),
            WrappedMarkdownTag(type: .Normal, flags: MarkdownTag.FLAG_NONE, text: "Another piece of text"),
            WrappedMarkdownTag(type: .Normal, flags: MarkdownTag.FLAG_NONE, text: ""),
            WrappedMarkdownTag(type: .Normal, flags: MarkdownTag.FLAG_NONE, text: "Text with a space separator to prevent paragraph"),
            WrappedMarkdownTag(type: .Paragraph, weight: 1, flags: MarkdownTag.FLAG_NONE, text: ""),
            WrappedMarkdownTag(type: .Normal, flags: MarkdownTag.FLAG_NONE, text: "New paragraph"),
            WrappedMarkdownTag(type: .Paragraph, weight: 2, flags: MarkdownTag.FLAG_NONE, text: ""),
            WrappedMarkdownTag(type: .Header, weight: 1, flags: MarkdownTag.FLAG_NONE, text: "Sudden header"),
            WrappedMarkdownTag(type: .Paragraph, weight: 1, flags: MarkdownTag.FLAG_NONE, text: ""),
            WrappedMarkdownTag(type: .Normal, flags: MarkdownTag.FLAG_NONE, text: "Text"),
            WrappedMarkdownTag(type: .Paragraph, weight: 1, flags: MarkdownTag.FLAG_NONE, text: ""),
            WrappedMarkdownTag(type: .UnorderedList, weight: 1, flags: MarkdownTag.FLAG_NONE, text: "Bullet item"),
            WrappedMarkdownTag(type: .UnorderedList, weight: 1, flags: MarkdownTag.FLAG_NONE, text: "Second item"),
            WrappedMarkdownTag(type: .Normal, flags: MarkdownTag.FLAG_NONE, text: "With some text"),
            WrappedMarkdownTag(type: .Paragraph, weight: 1, flags: MarkdownTag.FLAG_NONE, text: ""),
            WrappedMarkdownTag(type: .Normal, flags: MarkdownTag.FLAG_NONE, text: "New paragraph")
        ]
        assertTags(markdownTextLines, expectedTags: expectedTags)
    }

    func testFindTagsStyling() {
        //Test case with given text and expected markdown tags
        let markdownTextLines = [
            "Some text **before** the captions",
            "# Caption 1",
            "Some lines of _styled and **double styled** text_ which should be formatted correctly.",
            "Also new lines should work properly.",
            "### Caption 3",
            "The caption above is a bit smaller. Below add more lines to start a new \\*paragraph\\*.",
            "",
            "New paragraph here with ~~strike through text in **bold**~~.",
            "",
            "+ A bullet list",
            "- Second bullet item",
            "  * A nested item",
            "* Third bullet item",
            "  1. Nested first item",
            "  2. Nested second item",
            "",
            "And some text afterwards with a [link](https://www.github.com)."
        ]
        let expectedTags = [
            WrappedMarkdownTag(type: .Normal, flags: MarkdownTag.FLAG_NONE, text: "Some text **before** the captions"),
            WrappedMarkdownTag(type: .TextStyle, weight: 2, flags: MarkdownTag.FLAG_NONE, text: "before"),
            WrappedMarkdownTag(type: .Paragraph, weight: 2, flags: MarkdownTag.FLAG_NONE, text: ""),
            WrappedMarkdownTag(type: .Header, weight: 1, flags: MarkdownTag.FLAG_NONE, text: "Caption 1"),
            WrappedMarkdownTag(type: .Paragraph, weight: 1, flags: MarkdownTag.FLAG_NONE, text: ""),
            WrappedMarkdownTag(type: .Normal, flags: MarkdownTag.FLAG_NONE, text: "Some lines of _styled and **double styled** text_ which should be formatted correctly."),
            WrappedMarkdownTag(type: .TextStyle, weight: 1, flags: MarkdownTag.FLAG_NONE, text: "styled and **double styled** text"),
            WrappedMarkdownTag(type: .TextStyle, weight: 2, flags: MarkdownTag.FLAG_NONE, text: "double styled"),
            WrappedMarkdownTag(type: .Normal, flags: MarkdownTag.FLAG_NONE, text: "Also new lines should work properly."),
            WrappedMarkdownTag(type: .Paragraph, weight: 2, flags: MarkdownTag.FLAG_NONE, text: ""),
            WrappedMarkdownTag(type: .Header, weight: 3, flags: MarkdownTag.FLAG_NONE, text: "Caption 3"),
            WrappedMarkdownTag(type: .Paragraph, weight: 1, flags: MarkdownTag.FLAG_NONE, text: ""),
            WrappedMarkdownTag(type: .Normal, flags: MarkdownTag.FLAG_ESCAPED, text: "The caption above is a bit smaller. Below add more lines to start a new *paragraph*."),
            WrappedMarkdownTag(type: .Paragraph, weight: 1, flags: MarkdownTag.FLAG_NONE, text: ""),
            WrappedMarkdownTag(type: .Normal, flags: MarkdownTag.FLAG_NONE, text: "New paragraph here with ~~strike through text in **bold**~~."),
            WrappedMarkdownTag(type: .AlternativeTextStyle, weight: 2, flags: MarkdownTag.FLAG_NONE, text: "strike through text in **bold**"),
            WrappedMarkdownTag(type: .TextStyle, weight: 2, flags: MarkdownTag.FLAG_NONE, text: "bold"),
            WrappedMarkdownTag(type: .Paragraph, weight: 1, flags: MarkdownTag.FLAG_NONE, text: ""),
            WrappedMarkdownTag(type: .UnorderedList, weight: 1, flags: MarkdownTag.FLAG_NONE, text: "A bullet list"),
            WrappedMarkdownTag(type: .UnorderedList, weight: 1, flags: MarkdownTag.FLAG_NONE, text: "Second bullet item"),
            WrappedMarkdownTag(type: .UnorderedList, weight: 2, flags: MarkdownTag.FLAG_NONE, text: "A nested item"),
            WrappedMarkdownTag(type: .UnorderedList, weight: 1, flags: MarkdownTag.FLAG_NONE, text: "Third bullet item"),
            WrappedMarkdownTag(type: .OrderedList, weight: 2, flags: MarkdownTag.FLAG_NONE, text: "Nested first item"),
            WrappedMarkdownTag(type: .OrderedList, weight: 2, flags: MarkdownTag.FLAG_NONE, text: "Nested second item"),
            WrappedMarkdownTag(type: .Paragraph, weight: 1, flags: MarkdownTag.FLAG_NONE, text: ""),
            WrappedMarkdownTag(type: .Normal, flags: MarkdownTag.FLAG_NONE, text: "And some text afterwards with a [link](https://www.github.com)."),
            WrappedMarkdownTag(type: .Link, flags: MarkdownTag.FLAG_NONE, text: "link", extra: "https://www.github.com")
        ]
        assertTags(markdownTextLines, expectedTags: expectedTags)
    }

    func testFindTagsEdgeCases() {
        //Test case with given text and expected markdown tags
        let markdownTextLines = [
            "A strange ***combination** tag*."
        ]
        let expectedTags = [
            WrappedMarkdownTag(type: .Normal, flags: MarkdownTag.FLAG_NONE, text: "A strange ***combination** tag*."),
            WrappedMarkdownTag(type: .TextStyle, weight: 2, flags: MarkdownTag.FLAG_NONE, text: "*combination")
        ]
        assertTags(markdownTextLines, expectedTags: expectedTags)
    }
    
    func testEmptyString() {
        assertTags([], expectedTags: []);
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

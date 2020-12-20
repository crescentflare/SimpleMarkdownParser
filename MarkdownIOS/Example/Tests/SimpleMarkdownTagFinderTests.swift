import UIKit
import XCTest
@testable import SimpleMarkdownParser

// Tests finding markdown tags in markdown text
class SimpleMarkdownTagFinderTests: XCTestCase {
    
    // --
    // MARK: Test cases
    // --

    func testFindParagraphTags() {
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
            WrappedMarkdownTag(type: .line),
            WrappedMarkdownTag(type: .line),
            WrappedMarkdownTag(type: .paragraph, text: "Text"),
            WrappedMarkdownTag(type: .line, text: "Text"),
            WrappedMarkdownTag(type: .line),
            WrappedMarkdownTag(type: .line),
            WrappedMarkdownTag(type: .line),
            WrappedMarkdownTag(type: .paragraph, text: "Another"),
            WrappedMarkdownTag(type: .line, text: "Another")
        ]
        assertTags(markdownTextLines: markdownTextLines, expectedTags: expectedTags)
    }
    
    func testFindHeaderTags() {
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
            WrappedMarkdownTag(type: .paragraph, text: "Some text"),
            WrappedMarkdownTag(type: .line, text: "Some text"),
            WrappedMarkdownTag(type: .line),
            WrappedMarkdownTag(type: .header, weight: 1, text: "First header"),
            WrappedMarkdownTag(type: .line, text: "#First header"),
            WrappedMarkdownTag(type: .paragraph, text: "Additional text\nAnd more"),
            WrappedMarkdownTag(type: .line, text: "Additional text"),
            WrappedMarkdownTag(type: .line, text: "And more"),
            WrappedMarkdownTag(type: .line),
            WrappedMarkdownTag(type: .header, weight: 2, text: "Last header"),
            WrappedMarkdownTag(type: .line, text: "##   Last header"),
            WrappedMarkdownTag(type: .line),
            WrappedMarkdownTag(type: .paragraph, text: "Final text"),
            WrappedMarkdownTag(type: .line, text: "Final text")
        ]
        assertTags(markdownTextLines: markdownTextLines, expectedTags: expectedTags)
    }

    func testFindSectionTags() {
        let markdownTextLines = [
            "",
            "",
            "  #A strange indented header",
            "Another piece of text",
            "  ",
            "Text with a space separator to separate paragraph",
            "",
            "Another paragraph",
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
            WrappedMarkdownTag(type: .line),
            WrappedMarkdownTag(type: .line),
            WrappedMarkdownTag(type: .header, weight: 1, text: "A strange indented header"),
            WrappedMarkdownTag(type: .line, text: "#A strange indented header"),
            WrappedMarkdownTag(type: .paragraph, text: "Another piece of text"),
            WrappedMarkdownTag(type: .line, text: "Another piece of text"),
            WrappedMarkdownTag(type: .line),
            WrappedMarkdownTag(type: .paragraph, text: "Text with a space separator to separate paragraph"),
            WrappedMarkdownTag(type: .line, text: "Text with a space separator to separate paragraph"),
            WrappedMarkdownTag(type: .line),
            WrappedMarkdownTag(type: .paragraph, text: "Another paragraph"),
            WrappedMarkdownTag(type: .line, text: "Another paragraph"),
            WrappedMarkdownTag(type: .header, weight: 1, text: "Sudden header"),
            WrappedMarkdownTag(type: .line, text: "# Sudden header"),
            WrappedMarkdownTag(type: .paragraph, text: "Text"),
            WrappedMarkdownTag(type: .line, text: "Text"),
            WrappedMarkdownTag(type: .line),
            WrappedMarkdownTag(type: .list, text: "* Bullet item\n* Second item\n  With some text"),
            WrappedMarkdownTag(type: .line, text: "* Bullet item"),
            WrappedMarkdownTag(type: .unorderedList, weight: 1, text: "Bullet item"),
            WrappedMarkdownTag(type: .line, text: "* Second item"),
            WrappedMarkdownTag(type: .unorderedList, weight: 1, text: "Second item\n  With some text"),
            WrappedMarkdownTag(type: .line, text: "With some text"),
            WrappedMarkdownTag(type: .line),
            WrappedMarkdownTag(type: .paragraph, text: "New paragraph"),
            WrappedMarkdownTag(type: .line, text: "New paragraph")
        ]
        assertTags(markdownTextLines: markdownTextLines, expectedTags: expectedTags)
    }

    func testFindStylingTags() {
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
            "And some text afterwards with a [link](https://www.github.com)."
        ]
        let expectedTags = [
            WrappedMarkdownTag(type: .paragraph, text: "Some text **before** the captions"),
            WrappedMarkdownTag(type: .line, text: "Some text **before** the captions"),
            WrappedMarkdownTag(type: .textStyle, weight: 2, text: "before"),
            WrappedMarkdownTag(type: .header, weight: 1, text: "Caption 1"),
            WrappedMarkdownTag(type: .line, text: "# Caption 1"),
            WrappedMarkdownTag(type: .paragraph, text: "Some lines of _styled and **double styled** text_ which should be formatted correctly.\nAlso new lines should work properly."),
            WrappedMarkdownTag(type: .line, text: "Some lines of _styled and **double styled** text_ which should be formatted correctly."),
            WrappedMarkdownTag(type: .textStyle, weight: 1, text: "styled and **double styled** text"),
            WrappedMarkdownTag(type: .textStyle, weight: 2, text: "double styled"),
            WrappedMarkdownTag(type: .line, text: "Also new lines should work properly."),
            WrappedMarkdownTag(type: .header, weight: 3, text: "Caption 3"),
            WrappedMarkdownTag(type: .line, text: "### Caption 3"),
            WrappedMarkdownTag(type: .paragraph, text: "The caption above is a bit smaller. Below add more lines to start a new *paragraph*.", escapedCharacters: ["*", "*"]),
            WrappedMarkdownTag(type: .line, text: "The caption above is a bit smaller. Below add more lines to start a new *paragraph*.", escapedCharacters: ["*", "*"]),
            WrappedMarkdownTag(type: .line),
            WrappedMarkdownTag(type: .paragraph, text: "New paragraph here with ~~strike through text in **bold**~~."),
            WrappedMarkdownTag(type: .line, text: "New paragraph here with ~~strike through text in **bold**~~."),
            WrappedMarkdownTag(type: .alternativeTextStyle, weight: 2, text: "strike through text in **bold**"),
            WrappedMarkdownTag(type: .textStyle, weight: 2, text: "bold"),
            WrappedMarkdownTag(type: .line),
            WrappedMarkdownTag(type: .list, text: "+ A bullet list\n- Second bullet item\n  * A nested item\n* Third bullet item\n  1. Nested first item\n  2. Nested second item"),
            WrappedMarkdownTag(type: .line, text: "+ A bullet list"),
            WrappedMarkdownTag(type: .unorderedList, weight: 1, text: "A bullet list"),
            WrappedMarkdownTag(type: .line, text: "- Second bullet item"),
            WrappedMarkdownTag(type: .unorderedList, weight: 1, text: "Second bullet item"),
            WrappedMarkdownTag(type: .line, text: "* A nested item"),
            WrappedMarkdownTag(type: .unorderedList, weight: 2, text: "A nested item"),
            WrappedMarkdownTag(type: .line, text: "* Third bullet item"),
            WrappedMarkdownTag(type: .unorderedList, weight: 1, text: "Third bullet item"),
            WrappedMarkdownTag(type: .line, text: "1. Nested first item"),
            WrappedMarkdownTag(type: .orderedList, weight: 2, text: "Nested first item"),
            WrappedMarkdownTag(type: .line, text: "2. Nested second item"),
            WrappedMarkdownTag(type: .orderedList, weight: 2, text: "Nested second item"),
            WrappedMarkdownTag(type: .paragraph, text: "And some text afterwards with a [link](https://www.github.com)."),
            WrappedMarkdownTag(type: .line, text: "And some text afterwards with a [link](https://www.github.com)."),
            WrappedMarkdownTag(type: .link, text: "link", extra: "https://www.github.com")
        ]
        assertTags(markdownTextLines: markdownTextLines, expectedTags: expectedTags)
    }

    func testFindEdgeCasesTags() {
        let markdownTextLines = [
            "A strange ***combination** tag*."
        ]
        let expectedTags = [
            WrappedMarkdownTag(type: .paragraph, text: "A strange ***combination** tag*."),
            WrappedMarkdownTag(type: .line, text: "A strange ***combination** tag*."),
            WrappedMarkdownTag(type: .textStyle, weight: 2, text: "*combination")
        ]
        assertTags(markdownTextLines: markdownTextLines, expectedTags: expectedTags)
    }
    
    func testEmptyString() {
        assertTags(markdownTextLines: [], expectedTags: []);
    }

    
    // --
    // MARK: Helpers
    // --
    
    func assertTags(markdownTextLines: [String], expectedTags: [WrappedMarkdownTag], file: String = #file, line: UInt = #line) {
        // Find symbols
        let symbolFinder = SimpleMarkdownSymbolFinderSwift()
        let markdownText = markdownTextLines.joined(separator: "\n")
        symbolFinder.scanText(markdownText)
        
        // Find tags and compare
        let foundTags = SimpleMarkdownTagFinder().findTags(text: markdownText, symbols: symbolFinder.symbolStorage.symbols)
        for i in 0..<min(foundTags.count, expectedTags.count) {
            let wrappedTag = WrappedMarkdownTag(markdownText: markdownText, tag: foundTags[i])
            if expectedTags[i] != wrappedTag {
                recordFailure(withDescription: "Tags not equal, expected: \(expectedTags[i]), but having: \(wrappedTag)", inFile: file, atLine: Int(line), expected: true)
            }
        }
        if expectedTags.count != foundTags.count {
            recordFailure(withDescription: "Missing or too many tags, expected: \(expectedTags.count), but having: \(foundTags.count)", inFile: file, atLine: Int(line), expected: true)
        }
        XCTAssertEqual(expectedTags.count, foundTags.count)
    }

}

// Helper class to simply compare tags
class WrappedMarkdownTag: NSObject {
    
    fileprivate var type: MarkdownTagType
    fileprivate var weight: Int
    fileprivate var text: String
    fileprivate var extra: String
    fileprivate var escapedCharacters: [Character]

    override var description : String {
        return "{ type: \(type), weight: \(weight), text: \(text), extra: \(extra), escapedCharacters: \(escapedCharacters) }"
    }
    
    convenience init(type: MarkdownTagType, text: String = "", extra: String = "", escapedCharacters: [Character] = []) {
        self.init(type: type, weight: 0, text: text, extra: extra, escapedCharacters: escapedCharacters)
    }

    init(type: MarkdownTagType, weight: Int, text: String = "", extra: String = "", escapedCharacters: [Character] = []) {
        self.type = type
        self.weight = weight
        self.text = text
        self.extra = extra
        self.escapedCharacters = escapedCharacters
    }
    
    convenience init(markdownText: String, tag: MarkdownTag) {
        var escapedCharacters = [Character]()
        var text = ""
        var extra = ""
        var textOffset = 0
        if let startTextIndex = tag.startTextIndex, let endTextIndex = tag.endTextIndex {
            textOffset = tag.startTextPosition ?? 0
            text = String(markdownText[startTextIndex..<endTextIndex])
        }
        if let startExtraIndex = tag.startExtraIndex, let endExtraIndex = tag.endExtraIndex {
            extra = String(markdownText[startExtraIndex..<endExtraIndex])
        }
        for escapeSymbol in tag.escapeSymbols {
            escapedCharacters.append(markdownText[escapeSymbol.endIndex])
        }
        for escapeSymbol in tag.escapeSymbols.reversed() {
            if escapeSymbol.startPosition - textOffset < text.count {
                text.remove(at: text.index(text.startIndex, offsetBy: escapeSymbol.startPosition - textOffset))
            }
        }
        self.init(
            type: tag.type,
            weight: tag.weight,
            text: text,
            extra: extra,
            escapedCharacters: escapedCharacters
        )
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? WrappedMarkdownTag else { return false }
        return self.type == other.type && self.weight == other.weight && self.text == other.text && self.extra == other.extra && self.escapedCharacters == other.escapedCharacters
    }

}

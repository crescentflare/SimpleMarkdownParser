import UIKit
import XCTest
@testable import SimpleMarkdownParser

// Tests finding markdown symbols in markdown text
class SimpleMarkdownSymbolFinderTests: XCTestCase {
    
    // --
    // MARK: Test cases
    // --

    func testFindTextBlockSymbols() {
        let markdownTextLines = [
            "",
            "",
            "Line",
            "",
            "",
            "",
            "  Another line ",
            ""
        ]
        let expectedSymbols = [
            WrappedMarkdownSymbol(type: .newline, text: "\n", line: 0, linePosition: 0),
            WrappedMarkdownSymbol(type: .newline, text: "\n", line: 1, linePosition: 0),
            WrappedMarkdownSymbol(type: .textBlock, text: "Line", line: 2, linePosition: 0),
            WrappedMarkdownSymbol(type: .newline, text: "\n", line: 2, linePosition: 4),
            WrappedMarkdownSymbol(type: .newline, text: "\n", line: 3, linePosition: 0),
            WrappedMarkdownSymbol(type: .newline, text: "\n", line: 4, linePosition: 0),
            WrappedMarkdownSymbol(type: .newline, text: "\n", line: 5, linePosition: 0),
            WrappedMarkdownSymbol(type: .textBlock, text: "Another line", line: 6, linePosition: 2),
            WrappedMarkdownSymbol(type: .newline, text: "\n", line: 6, linePosition: 15)
        ]
        assertSymbols(markdownTextLines: markdownTextLines, expectedSymbols: expectedSymbols)
    }

    func testFindHeaderSymbols() {
        let markdownTextLines = [
            "#Nospacedheader",
            "## Corrected header",
            "### Wrapped header  ###",
            "Some header # token in between",
            "  ##   Extra spacey header "
        ]
        let expectedSymbols = [
            WrappedMarkdownSymbol(type: .header, text: "#", line: 0, linePosition: 0),
            WrappedMarkdownSymbol(type: .textBlock, text: "#Nospacedheader", line: 0, linePosition: 0),
            WrappedMarkdownSymbol(type: .newline, text: "\n", line: 0, linePosition: 15),
            WrappedMarkdownSymbol(type: .header, text: "##", line: 1, linePosition: 0),
            WrappedMarkdownSymbol(type: .textBlock, text: "## Corrected header", line: 1, linePosition: 0),
            WrappedMarkdownSymbol(type: .newline, text: "\n", line: 1, linePosition: 19),
            WrappedMarkdownSymbol(type: .header, text: "###", line: 2, linePosition: 0),
            WrappedMarkdownSymbol(type: .textBlock, text: "### Wrapped header  ###", line: 2, linePosition: 0),
            WrappedMarkdownSymbol(type: .header, text: "###", line: 2, linePosition: 20),
            WrappedMarkdownSymbol(type: .newline, text: "\n", line: 2, linePosition: 23),
            WrappedMarkdownSymbol(type: .textBlock, text: "Some header # token in between", line: 3, linePosition: 0),
            WrappedMarkdownSymbol(type: .header, text: "#", line: 3, linePosition: 12),
            WrappedMarkdownSymbol(type: .newline, text: "\n", line: 3, linePosition: 30),
            WrappedMarkdownSymbol(type: .header, text: "##", line: 4, linePosition: 2),
            WrappedMarkdownSymbol(type: .textBlock, text: "##   Extra spacey header", line: 4, linePosition: 2)
        ]
        assertSymbols(markdownTextLines: markdownTextLines, expectedSymbols: expectedSymbols)
    }
    
    func testFindTextStyleSymbols() {
        let markdownTextLines = [
            "Simple text with _italics_",
            "  **bold** and _italics_ ",
            "*nested __text style__*",
            "Mixed ~~strike **and~~ bold**",
            "Some _ incomplete *** text style ~~~ markers"
        ]
        let expectedSymbols = [
            WrappedMarkdownSymbol(type: .textBlock, text: "Simple text with _italics_", line: 0, linePosition: 0),
            WrappedMarkdownSymbol(type: .secondTextStyle, text: "_", line: 0, linePosition: 17),
            WrappedMarkdownSymbol(type: .secondTextStyle, text: "_", line: 0, linePosition: 25),
            WrappedMarkdownSymbol(type: .newline, text: "\n", line: 0, linePosition: 26),
            WrappedMarkdownSymbol(type: .firstTextStyle, text: "**", line: 1, linePosition: 2),
            WrappedMarkdownSymbol(type: .textBlock, text: "**bold** and _italics_", line: 1, linePosition: 2),
            WrappedMarkdownSymbol(type: .firstTextStyle, text: "**", line: 1, linePosition: 8),
            WrappedMarkdownSymbol(type: .secondTextStyle, text: "_", line: 1, linePosition: 15),
            WrappedMarkdownSymbol(type: .secondTextStyle, text: "_", line: 1, linePosition: 23),
            WrappedMarkdownSymbol(type: .newline, text: "\n", line: 1, linePosition: 25),
            WrappedMarkdownSymbol(type: .firstTextStyle, text: "*", line: 2, linePosition: 0),
            WrappedMarkdownSymbol(type: .textBlock, text: "*nested __text style__*", line: 2, linePosition: 0),
            WrappedMarkdownSymbol(type: .secondTextStyle, text: "__", line: 2, linePosition: 8),
            WrappedMarkdownSymbol(type: .secondTextStyle, text: "__", line: 2, linePosition: 20),
            WrappedMarkdownSymbol(type: .firstTextStyle, text: "*", line: 2, linePosition: 22),
            WrappedMarkdownSymbol(type: .newline, text: "\n", line: 2, linePosition: 23),
            WrappedMarkdownSymbol(type: .textBlock, text: "Mixed ~~strike **and~~ bold**", line: 3, linePosition: 0),
            WrappedMarkdownSymbol(type: .thirdTextStyle, text: "~~", line: 3, linePosition: 6),
            WrappedMarkdownSymbol(type: .firstTextStyle, text: "**", line: 3, linePosition: 15),
            WrappedMarkdownSymbol(type: .thirdTextStyle, text: "~~", line: 3, linePosition: 20),
            WrappedMarkdownSymbol(type: .firstTextStyle, text: "**", line: 3, linePosition: 27),
            WrappedMarkdownSymbol(type: .newline, text: "\n", line: 3, linePosition: 29),
            WrappedMarkdownSymbol(type: .textBlock, text: "Some _ incomplete *** text style ~~~ markers", line: 4, linePosition: 0),
            WrappedMarkdownSymbol(type: .secondTextStyle, text: "_", line: 4, linePosition: 5),
            WrappedMarkdownSymbol(type: .firstTextStyle, text: "***", line: 4, linePosition: 18),
            WrappedMarkdownSymbol(type: .thirdTextStyle, text: "~~~", line: 4, linePosition: 33)
        ]
        assertSymbols(markdownTextLines: markdownTextLines, expectedSymbols: expectedSymbols)
    }
    
    func testFindListSymbols() {
        let markdownTextLines = [
            "* First bullet point",
            "- Second bullet point",
            "  + Indented item",
            "1. Ordered item",
            "  1. Nested numbered item",
            "  2. Second one",
            "",
            "1 No list symbol"
        ]
        let expectedSymbols = [
            WrappedMarkdownSymbol(type: .unorderedListItem, text: "*", line: 0, linePosition: 0),
            WrappedMarkdownSymbol(type: .textBlock, text: "* First bullet point", line: 0, linePosition: 0),
            WrappedMarkdownSymbol(type: .newline, text: "\n", line: 0, linePosition: 20),
            WrappedMarkdownSymbol(type: .unorderedListItem, text: "-", line: 1, linePosition: 0),
            WrappedMarkdownSymbol(type: .textBlock, text: "- Second bullet point", line: 1, linePosition: 0),
            WrappedMarkdownSymbol(type: .newline, text: "\n", line: 1, linePosition: 21),
            WrappedMarkdownSymbol(type: .unorderedListItem, text: "+", line: 2, linePosition: 2),
            WrappedMarkdownSymbol(type: .textBlock, text: "+ Indented item", line: 2, linePosition: 2),
            WrappedMarkdownSymbol(type: .newline, text: "\n", line: 2, linePosition: 17),
            WrappedMarkdownSymbol(type: .orderedListItem, text: "1.", line: 3, linePosition: 0),
            WrappedMarkdownSymbol(type: .textBlock, text: "1. Ordered item", line: 3, linePosition: 0),
            WrappedMarkdownSymbol(type: .newline, text: "\n", line: 3, linePosition: 15),
            WrappedMarkdownSymbol(type: .orderedListItem, text: "1.", line: 4, linePosition: 2),
            WrappedMarkdownSymbol(type: .textBlock, text: "1. Nested numbered item", line: 4, linePosition: 2),
            WrappedMarkdownSymbol(type: .newline, text: "\n", line: 4, linePosition: 25),
            WrappedMarkdownSymbol(type: .orderedListItem, text: "2.", line: 5, linePosition: 2),
            WrappedMarkdownSymbol(type: .textBlock, text: "2. Second one", line: 5, linePosition: 2),
            WrappedMarkdownSymbol(type: .newline, text: "\n", line: 5, linePosition: 15),
            WrappedMarkdownSymbol(type: .newline, text: "\n", line: 6, linePosition: 0),
            WrappedMarkdownSymbol(type: .textBlock, text: "1 No list symbol", line: 7, linePosition: 0)
        ]
        assertSymbols(markdownTextLines: markdownTextLines, expectedSymbols: expectedSymbols)
    }
    
    func testFindLinkSymbols() {
        let markdownTextLines = [
            "Simple link: [https://www.github.com]",
            "[Named link](https://www.github.com/crescentflare)",
            "Quote link: [open Google](https://www.google.com \"Google's homepage\")",
            "Some [ random ) link tokens (]]"
        ]
        let expectedSymbols = [
            WrappedMarkdownSymbol(type: .textBlock, text: "Simple link: [https://www.github.com]", line: 0, linePosition: 0),
            WrappedMarkdownSymbol(type: .openLink, text: "[", line: 0, linePosition: 13),
            WrappedMarkdownSymbol(type: .closeLink, text: "]", line: 0, linePosition: 36),
            WrappedMarkdownSymbol(type: .newline, text: "\n", line: 0, linePosition: 37),
            WrappedMarkdownSymbol(type: .openLink, text: "[", line: 1, linePosition: 0),
            WrappedMarkdownSymbol(type: .textBlock, text: "[Named link](https://www.github.com/crescentflare)", line: 1, linePosition: 0),
            WrappedMarkdownSymbol(type: .closeLink, text: "]", line: 1, linePosition: 11),
            WrappedMarkdownSymbol(type: .openUrl, text: "(", line: 1, linePosition: 12),
            WrappedMarkdownSymbol(type: .closeUrl, text: ")", line: 1, linePosition: 49),
            WrappedMarkdownSymbol(type: .newline, text: "\n", line: 1, linePosition: 50),
            WrappedMarkdownSymbol(type: .textBlock, text: "Quote link: [open Google](https://www.google.com \"Google's homepage\")", line: 2, linePosition: 0),
            WrappedMarkdownSymbol(type: .openLink, text: "[", line: 2, linePosition: 12),
            WrappedMarkdownSymbol(type: .closeLink, text: "]", line: 2, linePosition: 24),
            WrappedMarkdownSymbol(type: .openUrl, text: "(", line: 2, linePosition: 25),
            WrappedMarkdownSymbol(type: .doubleQuote, text: "\"", line: 2, linePosition: 49),
            WrappedMarkdownSymbol(type: .doubleQuote, text: "\"", line: 2, linePosition: 67),
            WrappedMarkdownSymbol(type: .closeUrl, text: ")", line: 2, linePosition: 68),
            WrappedMarkdownSymbol(type: .newline, text: "\n", line: 2, linePosition: 69),
            WrappedMarkdownSymbol(type: .textBlock, text: "Some [ random ) link tokens (]]", line: 3, linePosition: 0),
            WrappedMarkdownSymbol(type: .openLink, text: "[", line: 3, linePosition: 5),
            WrappedMarkdownSymbol(type: .closeUrl, text: ")", line: 3, linePosition: 14),
            WrappedMarkdownSymbol(type: .openUrl, text: "(", line: 3, linePosition: 28),
            WrappedMarkdownSymbol(type: .closeLink, text: "]", line: 3, linePosition: 29),
            WrappedMarkdownSymbol(type: .closeLink, text: "]", line: 3, linePosition: 30)
        ]
        assertSymbols(markdownTextLines: markdownTextLines, expectedSymbols: expectedSymbols)
    }
    
    func testFindEscapeSymbols() {
        let markdownTextLines = [
            "Escaped \\*text style\\* symbols, using the escape character \\\\",
            "\\# This is no header",
            "##\\#\\# But this actually is a header",
            "A fake \\",
            "\\",
            "Newline"
        ]
        let expectedSymbols = [
            WrappedMarkdownSymbol(type: .textBlock, text: "Escaped \\*text style\\* symbols, using the escape character \\\\", line: 0, linePosition: 0),
            WrappedMarkdownSymbol(type: .escape, text: "\\", line: 0, linePosition: 8),
            WrappedMarkdownSymbol(type: .escape, text: "\\", line: 0, linePosition: 19),
            WrappedMarkdownSymbol(type: .escape, text: "\\", line: 0, linePosition: 57),
            WrappedMarkdownSymbol(type: .newline, text: "\n", line: 0, linePosition: 58),
            WrappedMarkdownSymbol(type: .escape, text: "\\", line: 1, linePosition: 0),
            WrappedMarkdownSymbol(type: .textBlock, text: "\\# This is no header", line: 1, linePosition: 0),
            WrappedMarkdownSymbol(type: .newline, text: "\n", line: 1, linePosition: 19),
            WrappedMarkdownSymbol(type: .header, text: "##", line: 2, linePosition: 0),
            WrappedMarkdownSymbol(type: .textBlock, text: "##\\#\\# But this actually is a header", line: 2, linePosition: 0),
            WrappedMarkdownSymbol(type: .escape, text: "\\", line: 2, linePosition: 2),
            WrappedMarkdownSymbol(type: .escape, text: "\\", line: 2, linePosition: 3),
            WrappedMarkdownSymbol(type: .newline, text: "\n", line: 2, linePosition: 34),
            WrappedMarkdownSymbol(type: .textBlock, text: "A fake \\\n\\\nNewline", line: 3, linePosition: 0),
            WrappedMarkdownSymbol(type: .escape, text: "\\", line: 3, linePosition: 7),
            WrappedMarkdownSymbol(type: .escape, text: "\\", line: 3, linePosition: 8)
        ]
        assertSymbols(markdownTextLines: markdownTextLines, expectedSymbols: expectedSymbols)
    }
    
    func testEmptyString() {
        assertSymbols(markdownTextLines: [], expectedSymbols: [])
    }

    
    // --
    // MARK: Helpers
    // --
    
    func assertSymbols(markdownTextLines: [String], expectedSymbols: [WrappedMarkdownSymbol], file: String = #file, line: UInt = #line) {
        let symbolFinder = SimpleMarkdownSymbolFinderSwift()
        let markdownText = markdownTextLines.joined(separator: "\n")
        symbolFinder.scanText(markdownText)
        let foundSymbols = symbolFinder.symbolStorage.symbols
        for i in 0..<min(expectedSymbols.count, foundSymbols.count) {
            let wrappedSymbol = WrappedMarkdownSymbol(markdownText: markdownText, symbol: foundSymbols[i])
            if expectedSymbols[i] != wrappedSymbol {
                recordFailure(withDescription: "Symbols not equal, expected: \(expectedSymbols[i]), but having: \(wrappedSymbol)", inFile: file, atLine: Int(line), expected: true)
            }
        }
        if expectedSymbols.count != foundSymbols.count {
            recordFailure(withDescription: "Missing or too many symbols, expected: \(expectedSymbols.count), but having: \(foundSymbols.count)", inFile: file, atLine: Int(line), expected: true)
        }
        XCTAssertEqual(expectedSymbols.count, foundSymbols.count)
    }

}

// Helper class to simplify comparing symbols
class WrappedMarkdownSymbol: NSObject {
    
    fileprivate var type: MarkdownSymbolType
    fileprivate var text: String
    fileprivate var line: Int
    fileprivate var linePosition: Int
    
    override var description : String {
        return "{ type: \(type), text: \(text), line: \(line), linePosition: \(linePosition) }"
    }
    
    init(type: MarkdownSymbolType, text: String, line: Int, linePosition: Int) {
        self.type = type
        self.text = text
        self.line = line
        self.linePosition = linePosition
    }
    
    convenience init(markdownText: String, symbol: MarkdownSymbol) {
        self.init(
            type: symbol.type,
            text: String(markdownText[symbol.startIndex..<symbol.endIndex]),
            line: symbol.line,
            linePosition: symbol.linePosition
        )
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? WrappedMarkdownSymbol else { return false }
        return self.type == other.type && self.text == other.text && self.line == other.line && self.linePosition == other.linePosition
    }

}

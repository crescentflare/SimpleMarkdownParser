//
//  MarkdownSymbol.swift
//  SimpleMarkdownParser Pod
//
//  Library symbol parsing: used to define symbols in a markdown document, like header and text style markers
//

// The enum to define the type of supported markdown symbol markers
public enum MarkdownSymbolType {
    
    case escape
    case doubleQuote
    case textBlock
    case newline
    case header
    case firstTextStyle
    case secondTextStyle
    case thirdTextStyle
    case orderedListItem
    case unorderedListItem
    case openLink
    case closeLink
    case openUrl
    case closeUrl
    
    public func isTextStyle() -> Bool {
        return self == .firstTextStyle || self == .secondTextStyle || self == .thirdTextStyle
    }
    
}

// Symbol object
public class MarkdownSymbol {
    
    // --
    // MARK: Members
    // --

    public let type: MarkdownSymbolType
    public let line: Int
    public let linePosition: Int
    public let startPosition: Int
    public let startIndex: String.Index
    public var endPosition: Int
    public var endIndex: String.Index
    

    // --
    // MARK: Initialization
    // --

    public init(type: MarkdownSymbolType, line: Int, startPosition: Int, startIndex: String.Index, endPosition: Int, endIndex: String.Index, linePosition: Int) {
        self.type = type
        self.line = line
        self.startPosition = startPosition
        self.startIndex = startIndex
        self.endPosition = endPosition
        self.endIndex = endIndex
        self.linePosition = linePosition
    }
    

    // --
    // MARK: Update position
    // --

    public func updateEndPosition(_ position: Int, index: String.Index) {
        self.endPosition = position
        self.endIndex = index
    }
    
}

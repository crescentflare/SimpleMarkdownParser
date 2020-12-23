//
//  MarkdownTag.swift
//  SimpleMarkdownParser Pod
//
//  Library tag parsing: a markdown paragraph, heading or styling tag found within the markdown text
//

// The enum to define the type of supported markdown tags
public enum MarkdownTagType: Int {
    
    case paragraph = 0
    case header = 1
    case list = 2
    case line = 3
    case sectionSpacer = 4
    case orderedListItem = 5
    case unorderedListItem = 6
    case link = 7
    case textStyle = 8
    case alternativeTextStyle = 9
    
    public func isSection() -> Bool {
        return self == .paragraph || self == .header || self == .list
    }

}

// Tag object
public class MarkdownTag {

    public let type: MarkdownTagType
    public var startIndex: String.Index
    public var endIndex: String.Index
    public var startTextIndex: String.Index
    public var endTextIndex: String.Index
    public var startExtraIndex: String.Index?
    public var endExtraIndex: String.Index?
    public var startPosition: Int
    public var endPosition: Int
    public var startTextPosition: Int
    public var endTextPosition: Int
    public var startExtraPosition: Int?
    public var endExtraPosition: Int?
    public var weight: Int
    public var escapeSymbols: [MarkdownSymbol]
    
    public convenience init(type: MarkdownTagType, weight: Int, startIndex: String.Index, endIndex: String.Index, startPosition: Int, endPosition: Int, escapeSymbols: [MarkdownSymbol] = []) {
        self.init(type: type, weight: weight, startIndex: startIndex, endIndex: endIndex, startPosition: startPosition, endPosition: endPosition, startTextIndex: startIndex, endTextIndex: endIndex, startTextPosition: startPosition, endTextPosition: endPosition, startExtraIndex: nil, endExtraIndex: nil, startExtraPosition: nil, endExtraPosition: nil, escapeSymbols: escapeSymbols)
    }

    public convenience init(type: MarkdownTagType, weight: Int, startIndex: String.Index, endIndex: String.Index, startPosition: Int, endPosition: Int, startTextIndex: String.Index, endTextIndex: String.Index, startTextPosition: Int, endTextPosition: Int, escapeSymbols: [MarkdownSymbol] = []) {
        self.init(type: type, weight: weight, startIndex: startIndex, endIndex: endIndex, startPosition: startPosition, endPosition: endPosition, startTextIndex: startTextIndex, endTextIndex: endTextIndex, startTextPosition: startTextPosition, endTextPosition: endTextPosition, startExtraIndex: nil, endExtraIndex: nil, startExtraPosition: nil, endExtraPosition: nil, escapeSymbols: escapeSymbols)
    }

    public init(type: MarkdownTagType, weight: Int, startIndex: String.Index, endIndex: String.Index, startPosition: Int, endPosition: Int, startTextIndex: String.Index, endTextIndex: String.Index, startTextPosition: Int, endTextPosition: Int, startExtraIndex: String.Index?, endExtraIndex: String.Index?, startExtraPosition: Int?, endExtraPosition: Int?, escapeSymbols: [MarkdownSymbol] = []) {
        self.type = type
        self.weight = weight
        self.startIndex = startIndex
        self.endIndex = endIndex
        self.startPosition = startPosition
        self.endPosition = endPosition
        self.startTextIndex = startTextIndex
        self.endTextIndex = endTextIndex
        self.startTextPosition = startTextPosition
        self.endTextPosition = endTextPosition
        self.startExtraIndex = startExtraIndex
        self.endExtraIndex = endExtraIndex
        self.startExtraPosition = startExtraPosition
        self.endExtraPosition = endExtraPosition
        self.escapeSymbols = escapeSymbols
    }

}

// Processed tag object (after text processing)
public class ProcessedMarkdownTag {

    public let type: MarkdownTagType
    public let startIndex: String.Index
    public let endIndex: String.Index
    public let startPosition: Int
    public let endPosition: Int
    public let weight: Int
    public var link: String?

    public init(type: MarkdownTagType, weight: Int, startIndex: String.Index, endIndex: String.Index, startPosition: Int, endPosition: Int, startExtraIndex: String.Index? = nil, endExtraIndex: String.Index? = nil, link: String? = nil) {
        self.type = type
        self.weight = weight
        self.startIndex = startIndex
        self.endIndex = endIndex
        self.startPosition = startPosition
        self.endPosition = endPosition
        self.link = link
    }

}

//
//  MarkdownTag.swift
//  SimpleMarkdownParser Pod
//
//  Library tag parsing: a markdown parapgraph, heading or styling tag found within the markdown text
//

// The enum to define the type of supported markdown tags
public enum MarkdownTagType: Int {
    
    case normal = -1 // To be deprecated
    case paragraph = 0
    case header = 1
    case list = 2
    case line = 3
    case sectionSpacer = 4
    case orderedList = 5
    case unorderedList = 6
    case link = 7
    case textStyle = 8
    case alternativeTextStyle = 9
    
    public func isSection() -> Bool {
        return self == .paragraph || self == .header || self == .list
    }

}

// Tag object
public class MarkdownTag {

    // --
    // MARK: Static flags
    // --

    public static var FLAG_NONE = 0x0
    public static var FLAG_ESCAPED = 0x40000000

    
    // --
    // MARK: Fields
    // --
    
    public var type = MarkdownTagType.normal
    public var flags = MarkdownTag.FLAG_NONE
    public var startIndex: String.Index? = nil
    public var endIndex: String.Index? = nil
    public var startTextIndex: String.Index? = nil
    public var endTextIndex: String.Index? = nil
    public var startExtraIndex: String.Index? = nil
    public var endExtraIndex: String.Index? = nil
    public var startPosition: Int? = nil
    public var endPosition: Int? = nil
    public var startTextPosition: Int? = nil
    public var endTextPosition: Int? = nil
    public var startExtraPosition: Int? = nil
    public var endExtraPosition: Int? = nil
    public var weight = 0
    public var escapeSymbols = [MarkdownSymbol]()


    // --
    // MARK: Default initializer
    // --
    
    public init() {
    }

}

// Processed tag object (after text processing)
public class ProcessedMarkdownTag {

    // --
    // MARK: Fields
    // --
    
    public let type: MarkdownTagType
    public let startIndex: String.Index
    public let endIndex: String.Index
    public let startPosition: Int
    public let endPosition: Int
    public var weight = 0
    public var link: String?


    // --
    // MARK: Default initializer
    // --
    
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

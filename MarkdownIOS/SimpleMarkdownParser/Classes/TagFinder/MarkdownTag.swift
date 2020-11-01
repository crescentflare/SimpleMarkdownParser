//
//  MarkdownTag.swift
//  SimpleMarkdownParser Pod
//
//  Core library: a markdown parapgraph, heading or styling tag found within the markdown text
//

// The enum to define the type of supported markdown tags
public enum MarkdownTagType: Int {
    
    case normal = -1 // To be deprecated
    case paragraph = 0
    case header = 1
    case list = 2
    case line = 3
    case orderedList = 4
    case unorderedList = 5
    case link = 6
    case textStyle = 7
    case alternativeTextStyle = 8
    
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

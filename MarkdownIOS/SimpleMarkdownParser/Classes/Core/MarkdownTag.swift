//
//  MarkdownTag.swift
//  SimpleMarkdownParser Pod
//
//  Core library: a markdown parapgraph, heading or styling tag found within the markdown text
//

// The enum to define the type of supported markdown tags
public enum MarkdownTagType {
    
    case normal
    case paragraph
    case textStyle
    case alternativeTextStyle
    case link
    case header
    case orderedList
    case unorderedList
    
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


    // --
    // MARK: Default initializer
    // --
    
    public init() {
    }

}

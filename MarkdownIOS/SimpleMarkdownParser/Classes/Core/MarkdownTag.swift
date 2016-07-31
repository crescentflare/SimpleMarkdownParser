//
//  MarkdownTag.swift
//  SimpleMarkdownParser Pod
//
//  Core library: a markdown parapgraph, heading or styling tag found within the markdown text
//

// The enum to define the type of supported markdown tags
public enum MarkdownTagType {
    
    case Normal
    case Paragraph
    case TextStyle
    case AlternativeTextStyle
    case Link
    case Header
    case OrderedList
    case UnorderedList
    
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
    
    public var type = MarkdownTagType.Normal
    public var flags = MarkdownTag.FLAG_NONE
    public var startPosition: String.Index? = nil
    public var endPosition: String.Index? = nil
    public var startText: String.Index? = nil
    public var endText: String.Index? = nil
    public var startExtra: String.Index? = nil
    public var endExtra: String.Index? = nil
    public var weight = 0


    // --
    // MARK: Default initializer
    // --
    
    public init() {
    }

}

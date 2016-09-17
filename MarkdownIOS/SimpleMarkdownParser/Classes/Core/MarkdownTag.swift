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
open class MarkdownTag {

    // --
    // MARK: Static flags
    // --

    open static var FLAG_NONE = 0x0
    open static var FLAG_ESCAPED = 0x40000000

    
    // --
    // MARK: Fields
    // --
    
    open var type = MarkdownTagType.normal
    open var flags = MarkdownTag.FLAG_NONE
    open var startPosition: String.Index? = nil
    open var endPosition: String.Index? = nil
    open var startText: String.Index? = nil
    open var endText: String.Index? = nil
    open var startExtra: String.Index? = nil
    open var endExtra: String.Index? = nil
    open var weight = 0


    // --
    // MARK: Default initializer
    // --
    
    public init() {
    }

}

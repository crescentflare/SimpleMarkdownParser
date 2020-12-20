//
//  MarkdownAttributedStringGenerator.swift
//  SimpleMarkdownParser Pod
//
//  Conversion library: defines the protocol for generating the attributed string
//

public protocol MarkdownAttributedStringGenerator: class {
    
    func applyAttribute(defaultFont: UIFont, attributedString: NSMutableAttributedString, type: MarkdownTagType, weight: Int, start: Int, length: Int, extra: String)
    func applySectionSpacerAttribute(defaultFont: UIFont, attributedString: NSMutableAttributedString, previousSectionType: MarkdownTagType, previousSectionWeight: Int, nextSectionType: MarkdownTagType, nextSectionWeight: Int, start: Int, length: Int)
    func getListToken(fromType: MarkdownTagType, weight: Int, index: Int) -> String
    
}

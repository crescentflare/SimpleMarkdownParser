//
//  MarkdownAttributedStringGenerator.swift
//  SimpleMarkdownParser Pod
//
//  Conversion library: defines the protocol for generating the attributed string
//

public protocol MarkdownAttributedStringGenerator: class {
    
    func applyAttribute(defaultFont: UIFont, attributedString: NSMutableAttributedString, type: MarkdownTagType, weight: Int, start: Int, length: Int, extra: String)
    func getListToken(fromType: MarkdownTagType, weight: Int, index: Int) -> String
    
}

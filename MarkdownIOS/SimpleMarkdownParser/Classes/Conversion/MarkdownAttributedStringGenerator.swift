//
//  MarkdownAttributedStringGenerator.swift
//  SimpleMarkdownParser Pod
//
//  Conversion library: defines the protocol for generating the attributed string
//

public protocol MarkdownAttributedStringGenerator: class {
    
    func applyAttribute(_ defaultFont: UIFont, attributedString: NSMutableAttributedString, type: MarkdownTagType, weight: Int, start: Int, length: Int, extra: String)
    func getListToken(_ type: MarkdownTagType, weight: Int, index: Int) -> String
    
}

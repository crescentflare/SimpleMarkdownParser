//
//  SimpleMarkdownParser.swift
//  SimpleMarkdownParser Pod
//
//  Core library: defines the protocol of the parser
//

// The enum to define the way to extract the text between 2 tags
public enum ExtractBetweenMode {
    
    case startToNext
    case intermediateToNext
    case intermediateToEnd
    
}

// Parser protocol
public protocol SimpleMarkdownParser: class {
    
    func findTags(_ markdownText: String) -> [MarkdownTag]
    func extractText(_ markdownText: String, tag: MarkdownTag) -> String
    func extractTextBetween(_ markdownText: String, startTag: MarkdownTag, endTag: MarkdownTag, mode: ExtractBetweenMode) -> String
    func extractFull(_ markdownText: String, tag: MarkdownTag) -> String
    func extractFullBetween(_ markdownText: String, startTag: MarkdownTag, endTag: MarkdownTag, mode: ExtractBetweenMode) -> String
    func extractExtra(_ markdownText: String, tag: MarkdownTag) -> String
    
}

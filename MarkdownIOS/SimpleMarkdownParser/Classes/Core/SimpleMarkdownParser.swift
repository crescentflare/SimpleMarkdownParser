//
//  SimpleMarkdownParser.swift
//  SimpleMarkdownParser Pod
//
//  Core library: defines the protocol of the parser
//

// The enum to define the way to extract the text between 2 tags
public enum ExtractBetweenMode {
    
    case StartToNext
    case IntermediateToNext
    case IntermediateToEnd
    
}

// Parser protocol
public protocol SimpleMarkdownParser: class {
    
    func findTags(markdownText: String) -> [MarkdownTag]
    func extractText(markdownText: String, tag: MarkdownTag) -> String
    func extractTextBetween(markdownText: String, startTag: MarkdownTag, endTag: MarkdownTag, mode: ExtractBetweenMode) -> String
    func extractFull(markdownText: String, tag: MarkdownTag) -> String
    func extractFullBetween(markdownText: String, startTag: MarkdownTag, endTag: MarkdownTag, mode: ExtractBetweenMode) -> String
    func extractExtra(markdownText: String, tag: MarkdownTag) -> String
    
}

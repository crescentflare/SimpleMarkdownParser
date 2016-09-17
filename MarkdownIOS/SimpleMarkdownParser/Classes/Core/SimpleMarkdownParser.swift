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
    
    func findTags(onMarkdownText: String) -> [MarkdownTag]
    func extract(textFromMarkdownText: String, tag: MarkdownTag) -> String
    func extract(textBetweenMarkdownText: String, startTag: MarkdownTag, endTag: MarkdownTag, mode: ExtractBetweenMode) -> String
    func extract(fullFromMarkdownText: String, tag: MarkdownTag) -> String
    func extract(fullBetweenMarkdownText: String, startTag: MarkdownTag, endTag: MarkdownTag, mode: ExtractBetweenMode) -> String
    func extract(extraFromMarkdownText: String, tag: MarkdownTag) -> String
    
}

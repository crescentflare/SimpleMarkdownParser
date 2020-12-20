//
//  SimpleMarkdownConverter.swift
//  SimpleMarkdownParser Pod
//
//  Conversion library: utility class to convert markdown to HTML or attributed string
//

public let NSClickableTextAttributeName = "NSClickableTextAttributeName"
public let NSHighlightColorAttributeName = "NSHighlightColorAttributeName"

// Convert markdown text to an attributed string or HTML
public class SimpleMarkdownConverter {
    
    // --
    // MARK: HTML conversion handling
    // --
    
    public static func toHtmlString(fromMarkdownText: String) -> String {
        // Find symbols
        let symbolFinder = obtainSymbolFinder(forMarkdownText: fromMarkdownText)
        symbolFinder.scanText(fromMarkdownText)
        
        // Find tags from symbols and process text
        let tags = SimpleMarkdownTagFinder().findTags(text: fromMarkdownText, symbols: symbolFinder.symbolStorage.symbols)
        let processor = SimpleMarkdownTextProcessor.process(text: fromMarkdownText, tags: tags)
        
        // Process HTML
        let htmlProcessor = SimpleMarkdownHtmlProcessor.process(text: processor.text, tags: processor.tags)
        return htmlProcessor.text
    }

    
    // --
    // MARK: Attributed string conversion handling
    // --
    
    public static func toAttributedString(defaultFont: UIFont, markdownText: String, attributedStringGenerator: MarkdownAttributedStringGenerator? = nil) -> NSAttributedString {
        // Find symbols
        let symbolFinder = obtainSymbolFinder(forMarkdownText: markdownText)
        symbolFinder.scanText(markdownText)
        
        // Find tags from symbols and process text
        let stringGenerator = attributedStringGenerator ?? DefaultMarkdownAttributedStringGenerator()
        let tags = SimpleMarkdownTagFinder().findTags(text: markdownText, symbols: symbolFinder.symbolStorage.symbols)
        let processor = SimpleMarkdownTextProcessor.process(text: markdownText, tags: tags, attributedStringGenerator: stringGenerator)
        processor.rearrangeNestedTextStyles()
        
        // Set up attributed string
        let attributedString = NSMutableAttributedString(string: processor.text)
        attributedString.addAttribute(NSAttributedString.Key.font, value: defaultFont, range: NSMakeRange(0, attributedString.length))
        for index in processor.tags.indices {
            let tag = processor.tags[index]
            // Handle section spacer
            if tag.type == .sectionSpacer {
                var previousSectionTagType: MarkdownTagType?
                var nextSectionTagType: MarkdownTagType?
                var previousSectionWeight = 0
                var nextSectionWeight = 0
                for checkIndex in processor.tags.indices {
                    let checkTag = processor.tags[checkIndex]
                    if checkTag.type.isSection() {
                        if checkIndex < index {
                            previousSectionTagType = checkTag.type
                            previousSectionWeight = checkTag.weight
                        } else if checkIndex > index {
                            nextSectionTagType = checkTag.type
                            nextSectionWeight = checkTag.weight
                            break
                        }
                    }
                }
                if let previousType = previousSectionTagType, let nextType = nextSectionTagType {
                    stringGenerator.applySectionSpacerAttribute(defaultFont: defaultFont, attributedString: attributedString, previousSectionType: previousType, previousSectionWeight: previousSectionWeight, nextSectionType: nextType, nextSectionWeight: nextSectionWeight, start: tag.startPosition, length: tag.endPosition - tag.startPosition)
                }
            }
            
            // Apply attributes from tag
            stringGenerator.applyAttribute(defaultFont: defaultFont, attributedString: attributedString, type: tag.type, weight: tag.weight, start: tag.startPosition, length: tag.endPosition - tag.startPosition, extra: tag.link ?? "")
        }
        return attributedString
    }

    
    // --
    // MARK: Obtain parser instance
    // --
    
    private static func obtainSymbolFinder(forMarkdownText: String) -> SimpleMarkdownSymbolFinder {
        return SimpleMarkdownSymbolFinderSwift()
    }

}

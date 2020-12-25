//
//  SimpleMarkdownHtmlProcessor.swift
//  SimpleMarkdownParser Pod
//
//  Conversion library: helper class to generate HTML tags which are inserted into the processed markdown text
//

// Process text to insert HTML tags from processed markdown
public class SimpleMarkdownHtmlProcessor {
    
    // --
    // MARK: Members
    // --

    public var text = ""
    private var htmlTags = [MarkdownHtmlTag]()
    private let markdownTags: [ProcessedMarkdownTag]
    

    // --
    // MARK: Initialization
    // --

    private init(text: String, tags: [ProcessedMarkdownTag]) {
        self.text = text
        markdownTags = tags
    }
    

    // --
    // MARK: Processing
    // --
    
    public static func process(text: String, tags: [ProcessedMarkdownTag]) -> SimpleMarkdownHtmlProcessor {
        let instance = SimpleMarkdownHtmlProcessor(text: text, tags: tags)
        instance.processInternal()
        return instance
    }

    private func processInternal() {
        // Process markdown tags
        let sectionTags = markdownTags.filter { $0.type.isSection() }
        for sectionTag in sectionTags {
            // First add section html tags
            if sectionTag.type == .paragraph {
                htmlTags.append(MarkdownHtmlTag(index: sectionTag.startIndex, tag: .openParagraph, counter: htmlTags.count))
                htmlTags.append(MarkdownHtmlTag(index: sectionTag.endIndex, tag: .closeParagraph, counter: htmlTags.count))
            } else if sectionTag.type == .header {
                let clippedWeight = max(1, min(sectionTag.weight, 6))
                htmlTags.append(MarkdownHtmlTag(index: sectionTag.startIndex, tag: MarkdownHtmlTagType.allOpenHeaders[clippedWeight - 1], counter: htmlTags.count))
                htmlTags.append(MarkdownHtmlTag(index: sectionTag.endIndex, tag: MarkdownHtmlTagType.allCloseHeaders[clippedWeight - 1], counter: htmlTags.count))
            }
            
            // Process inner tags
            let innerTags = markdownTags.filter { !$0.type.isSection() && $0.startIndex >= sectionTag.startIndex && $0.endIndex <= sectionTag.endIndex }
            let innerListTags = innerTags.filter { $0.type == .orderedListItem || $0.type == .unorderedListItem }
            if innerListTags.count > 0 {
                addHtmlListTags(innerTags: innerListTags, index: 0, untilIndex: innerListTags.count, weight: 1)
            }
            for tag in innerTags {
                switch tag.type {
                case .textStyle:
                    let clippedWeight = max(1, min(tag.weight, 3))
                    htmlTags.append(MarkdownHtmlTag(index: tag.startIndex, tag: MarkdownHtmlTagType.allOpenTextStyles[clippedWeight - 1], counter: htmlTags.count))
                    htmlTags.append(MarkdownHtmlTag(index: tag.endIndex, tag: MarkdownHtmlTagType.allCloseTextStyles[clippedWeight - 1], counter: htmlTags.count))
                case .alternativeTextStyle:
                    htmlTags.append(MarkdownHtmlTag(index: tag.startIndex, tag: .openAlternativeTextStyle, counter: htmlTags.count))
                    htmlTags.append(MarkdownHtmlTag(index: tag.endIndex, tag: .closeAlternativeTextStyle, counter: htmlTags.count))
                case .link:
                    htmlTags.append(MarkdownHtmlTag(index: tag.startIndex, tag: .openLink, counter: htmlTags.count, value: tag.link))
                    htmlTags.append(MarkdownHtmlTag(index: tag.endIndex, tag: .closeLink, counter: htmlTags.count))
                case .orderedListItem, .unorderedListItem:
                    htmlTags.append(MarkdownHtmlTag(index: tag.startIndex, tag: .openListItem, counter: htmlTags.count))
                    htmlTags.append(MarkdownHtmlTag(index: tag.endIndex, tag: .closeListItem, counter: htmlTags.count))
                case .line:
                    let htmlTag = MarkdownHtmlTag(index: tag.endIndex, tag: .lineBreak, counter: htmlTags.count)
                    htmlTag.preventCancellation = sectionTag.type == .list && tag.endPosition == sectionTag.endPosition
                    htmlTags.append(htmlTag)
                default:
                    break
                }
            }
        }
        
        // Remove line breaks canceled by other html tags
        var removeIndices = [Int]()
        for index in htmlTags.indices {
            if htmlTags[index].tag == .lineBreak && !htmlTags[index].preventCancellation {
                for checkIndex in htmlTags.indices {
                    if checkIndex != index && htmlTags[index].index == htmlTags[checkIndex].index && htmlTags[checkIndex].tag.cancelsLineBreak() {
                        removeIndices.append(index)
                        break
                    }
                }
            }
        }
        for removeIndex in removeIndices.reversed() {
            htmlTags.remove(at: removeIndex)
        }
        
        // Sort and insert in text (start at the end, to easily insert without taking string position changes into account)
        htmlTags.sort {
            if $0.index > $1.index {
                return true
            } else if $0.index == $1.index {
                if $0.tag.priority() > $1.tag.priority() {
                    return true
                } else if $0.tag.priority() == $1.tag.priority() {
                    return $0.tag.isClosingTag() ? $0.counter < $1.counter : $0.counter > $1.counter
                }
            }
            return false
        }
        for htmlTag in htmlTags {
            text.insert(contentsOf: Array(htmlTag.insertToken()), at: htmlTag.index)
        }
    }
    

    // --
    // MARK: Helper
    // --

    private func addHtmlListTags(innerTags: [ProcessedMarkdownTag], index: Int, untilIndex: Int, weight: Int) {
        // Find start index for tag matching weight, return early if none are found
        var startIndex = -1
        for i in index..<untilIndex {
            let tagWeight = max(1, innerTags[i].weight)
            if tagWeight >= weight {
                startIndex = i
                break
            }
        }
        if startIndex < index {
            return
        }
        
        // Find end index
        var checkType: MarkdownTagType = innerTags[startIndex].weight == weight ? innerTags[startIndex].type : .list
        var endIndex = startIndex + 1
        for i in (startIndex + 1)..<untilIndex {
            let tagWeight = max(1, innerTags[i].weight)
            if checkType == .list && tagWeight == weight {
                checkType = innerTags[i].type
            }
            if tagWeight < weight || (tagWeight == weight && innerTags[i].type != checkType) {
                break
            }
            endIndex += 1
        }
        
        // Insert list section tags
        htmlTags.append(MarkdownHtmlTag(index: innerTags[startIndex].startIndex, tag: checkType == .orderedListItem ? .openOrderedList : .openUnorderedList, counter: htmlTags.count))
        htmlTags.append(MarkdownHtmlTag(index: innerTags[endIndex - 1].endIndex, tag: checkType == .orderedListItem ? .closeOrderedList : .closeUnorderedList, counter: htmlTags.count))
        
        // Call recursively for a higher weight, or continuation into a different list type
        addHtmlListTags(innerTags: innerTags, index: startIndex, untilIndex: endIndex, weight: weight + 1)
        if endIndex < untilIndex {
            addHtmlListTags(innerTags: innerTags, index: endIndex, untilIndex: untilIndex, weight: weight)
        }
    }

}

// A helper enum to list all supported HTML tags and their properties
private enum MarkdownHtmlTagType: String {
    
    case lineBreak = "<br/>"
    case openHeader1 = "<h1>"
    case closeHeader1 = "</h1>"
    case openHeader2 = "<h2>"
    case closeHeader2 = "</h2>"
    case openHeader3 = "<h3>"
    case closeHeader3 = "</h3>"
    case openHeader4 = "<h4>"
    case closeHeader4 = "</h4>"
    case openHeader5 = "<h5>"
    case closeHeader5 = "</h5>"
    case openHeader6 = "<h6>"
    case closeHeader6 = "</h6>"
    case openParagraph = "<p>"
    case closeParagraph = "</p>"
    case openUnorderedList = "<ul>"
    case closeUnorderedList = "</ul>"
    case openOrderedList = "<ol>"
    case closeOrderedList = "</ol>"
    case openListItem = "<li>"
    case closeListItem = "</li>"
    case openTextStyle1 = "<i>"
    case closeTextStyle1 = "</i>"
    case openTextStyle2 = "<b>"
    case closeTextStyle2 = "</b>"
    case openTextStyle3 = "<b><i>"
    case closeTextStyle3 = "</i></b>"
    case openAlternativeTextStyle = "<del>"
    case closeAlternativeTextStyle = "</del>"
    case openLink = "<a href=\"#\">"
    case closeLink = "</a>"

    static var allOpenHeaders: [MarkdownHtmlTagType] = [ .openHeader1, .openHeader2, .openHeader3, .openHeader4, .openHeader5, .openHeader6 ]
    static var allCloseHeaders: [MarkdownHtmlTagType] = [ .closeHeader1, .closeHeader2, .closeHeader3, .closeHeader4, .closeHeader5, .closeHeader6 ]
    static var allOpenTextStyles: [MarkdownHtmlTagType] = [ .openTextStyle1, .openTextStyle2, .openTextStyle3 ]
    static var allCloseTextStyles: [MarkdownHtmlTagType] = [ .closeTextStyle1, .closeTextStyle2, .closeTextStyle3 ]

    func cancelsLineBreak() -> Bool {
        return MarkdownHtmlTagType.allCloseHeaders.contains(self) || self == .closeParagraph || self == .closeUnorderedList || self == .closeOrderedList || self == .closeListItem
    }
    
    func isClosingTag() -> Bool {
        return MarkdownHtmlTagType.allCloseHeaders.contains(self) || MarkdownHtmlTagType.allCloseTextStyles.contains(self) || self == .closeParagraph || self == .closeUnorderedList || self == .closeOrderedList || self == .closeListItem || self == .closeAlternativeTextStyle || self == .closeLink
    }
    
    func priority() -> Int {
        if self == .lineBreak {
            return 2
        }
        if isClosingTag() {
            return 1
        }
        return 0
    }

}

// A helper class to store an HTML tag to insert, together with some extra data to maintain the correct ordering
private class MarkdownHtmlTag {
    
    let index: String.Index
    let tag: MarkdownHtmlTagType
    let counter: Int
    let value: String?
    var preventCancellation = false
    
    init(index: String.Index, tag: MarkdownHtmlTagType, counter: Int, value: String? = nil) {
        self.index = index
        self.tag = tag
        self.counter = counter
        self.value = value
    }
    
    func insertToken() -> String {
        if let value = value {
            return tag.rawValue.replacingOccurrences(of: "#", with: value)
        }
        return tag.rawValue
    }

}

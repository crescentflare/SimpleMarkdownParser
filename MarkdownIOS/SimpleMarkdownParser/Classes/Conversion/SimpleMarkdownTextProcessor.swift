//
//  SimpleMarkdownTextProcessor.swift
//  SimpleMarkdownParser Pod
//
//  Conversion library: helper class to filter out markdown symbols and return processed tags
//

// Process text to filter out markdown symbols and store its processed text and tags
public class SimpleMarkdownTextProcessor {
    
    // --
    // MARK: Members
    // --

    public var text = ""
    public var tags = [ProcessedMarkdownTag]()
    private let originalTags: [MarkdownTag]
    private let originalText: String
    private let attributedStringGenerator: MarkdownAttributedStringGenerator?
    

    // --
    // MARK: Initialization
    // --

    private init(text: String, tags: [MarkdownTag], attributedStringGenerator: MarkdownAttributedStringGenerator? = nil) {
        originalText = text
        self.originalTags = tags
        self.attributedStringGenerator = attributedStringGenerator
    }
    

    // --
    // MARK: Processing
    // --
    
    public static func process(text: String, tags: [MarkdownTag], attributedStringGenerator: MarkdownAttributedStringGenerator? = nil) -> SimpleMarkdownTextProcessor {
        let instance = SimpleMarkdownTextProcessor(text: text, tags: tags, attributedStringGenerator: attributedStringGenerator)
        instance.processInternal()
        return instance
    }
    
    public func rearrangeNestedTextStyles() {
        let originalTags = tags
        var scanPosition = 0
        var alternativeScanPosition = 0
        tags = []
        for index in originalTags.indices {
            let checkTag = originalTags[index]
            if checkTag.type == .textStyle || checkTag.type == .alternativeTextStyle {
                if (checkTag.type == .textStyle && checkTag.startPosition >= scanPosition) || (checkTag.type == .alternativeTextStyle && checkTag.startPosition >= alternativeScanPosition) {
                    let nestedTags = getRearrangedTextStyleTags(checkTags: originalTags, index: index)
                    tags.append(contentsOf: nestedTags)
                    if let lastNestedTag = nestedTags.last {
                        if checkTag.type == .textStyle {
                            scanPosition = lastNestedTag.endPosition
                        } else {
                            alternativeScanPosition = lastNestedTag.endPosition
                        }
                    }
                }
            } else {
                tags.append(checkTag)
            }
        }
        tags.sort { $0.startPosition < $1.startPosition || ($0.type.rawValue < $1.type.rawValue && $0.startPosition <= $1.startPosition) }
    }
    
    private func processInternal() {
        let sectionTags = originalTags.filter { $0.type.isSection() }
        for sectionIndex in sectionTags.indices {
            // Determine tags and copy ranges for this section
            let sectionTag = sectionTags[sectionIndex]
            let innerTags = originalTags.filter { !$0.type.isSection() && $0.startPosition >= sectionTag.startPosition && $0.endPosition <= sectionTag.endPosition }
            let copyRanges = getCopyRanges(sectionTag: sectionTag, innerTags: innerTags)
                
            // Add to text
            let startTextIndex = text.endIndex
            let startTextPosition = text.count
            for range in copyRanges {
                if range.type == .copy {
                    text += originalText[originalText.index(originalText.startIndex, offsetBy: range.startPosition)..<originalText.index(originalText.startIndex, offsetBy: range.endPosition)]
                } else if let insertText = range.insertText {
                    text += insertText
                }
            }

            // Add processed block tag
            let processedSectionTag = ProcessedMarkdownTag(type: sectionTag.type, weight: sectionTag.weight, startIndex: startTextIndex, endIndex: text.endIndex, startPosition: startTextPosition, endPosition: text.count)
            tags.append(processedSectionTag)
            
            // Add processed inner tags
            let deleteRanges = getDeleteRanges(sectionTag: sectionTag, copyRanges: copyRanges)
            let blockPositionAdjustment = sectionTag.startPosition - startTextPosition
            for innerTag in innerTags {
                // Calculate position offset adjustments
                var startOffset = -blockPositionAdjustment
                var endOffset = -blockPositionAdjustment
                for range in deleteRanges {
                    if range.type == .delete && range.startPosition < innerTag.endTextPosition {
                        let rangeLength = range.endPosition - range.startPosition
                        let tagLength = innerTag.endTextPosition - innerTag.startTextPosition
                        let startAdjustment = max(0, min(rangeLength, innerTag.startTextPosition - range.startPosition))
                        startOffset -= startAdjustment
                        endOffset -= startAdjustment + min(tagLength, min(rangeLength, max(0, min(innerTag.endTextPosition - range.startPosition, range.endPosition - innerTag.startTextPosition))))
                    } else if (range.type == .insert || range.type == .insertListToken) && range.startPosition < innerTag.endTextPosition {
                        let length = range.insertText?.count ?? 0
                        let includeInTag = range.type == .insertListToken && (innerTag.type == .orderedListItem || innerTag.type == .unorderedListItem || innerTag.type == .line) && range.startPosition == innerTag.startTextPosition
                        if range.endPosition <= innerTag.startTextPosition && !includeInTag {
                            startOffset += length
                        }
                        endOffset += length
                    }
                }
                
                // Add processed tag
                let startPosition = innerTag.startTextPosition + startOffset
                let endPosition = innerTag.endTextPosition + endOffset
                let processedTag = ProcessedMarkdownTag(type: innerTag.type, weight: innerTag.weight, startIndex: text.index(startTextIndex, offsetBy: startPosition - processedSectionTag.startPosition), endIndex: text.index(startTextIndex, offsetBy: endPosition - processedSectionTag.startPosition), startPosition: startPosition, endPosition: endPosition)
                if innerTag.type == .link {
                    if let startExtraIndex = innerTag.startExtraIndex, let endExtraIndex = innerTag.endExtraIndex {
                        processedTag.link = String(originalText[startExtraIndex..<endExtraIndex])
                    } else {
                        processedTag.link = String(originalText[innerTag.startTextIndex..<innerTag.endTextIndex])
                    }
                }
                tags.append(processedTag)
            }

            // Add section spacer and newlines between sections
            if sectionIndex + 1 < sectionTags.count {
                if attributedStringGenerator != nil {
                    text += "\n\n"
                    tags.append(ProcessedMarkdownTag(type: .sectionSpacer, weight: 0, startIndex: text.index(before: text.endIndex), endIndex: text.endIndex, startPosition: text.count - 1, endPosition: text.count))
                } else {
                    text += "\n"
                }
            }
        }
    }
    
    private func getRearrangedTextStyleTags(checkTags: [ProcessedMarkdownTag], index: Int, addWeight: Int = 0) -> [ProcessedMarkdownTag] {
        // Scan nested tags
        let textStyleTag = checkTags[index]
        var result = [ProcessedMarkdownTag]()
        var scanPosition = textStyleTag.startPosition
        for i in (index + 1)..<checkTags.count {
            // Break when reaching the end of the current text style tag
            let checkTag = checkTags[i]
            if checkTag.startPosition >= textStyleTag.endPosition {
                break
            }
            
            // Check nested text style tag
            if checkTag.startPosition >= scanPosition && checkTag.type == textStyleTag.type {
                let nestedTags = getRearrangedTextStyleTags(checkTags: checkTags, index: i, addWeight: textStyleTag.weight + addWeight)
                result.append(ProcessedMarkdownTag(type: textStyleTag.type, weight: textStyleTag.weight + addWeight, startIndex: text.index(textStyleTag.startIndex, offsetBy: scanPosition - textStyleTag.startPosition), endIndex: checkTag.startIndex, startPosition: scanPosition, endPosition: checkTag.startPosition))
                result.append(contentsOf: nestedTags)
                if let lastNestedTag = nestedTags.last {
                    scanPosition = lastNestedTag.endPosition
                }
            }
        }
        
        // Finish current tag and return result
        if scanPosition < textStyleTag.endPosition {
            result.append(ProcessedMarkdownTag(type: textStyleTag.type, weight: textStyleTag.weight + addWeight, startIndex: text.index(textStyleTag.startIndex, offsetBy: scanPosition - textStyleTag.startPosition), endIndex: textStyleTag.endIndex, startPosition: scanPosition, endPosition: textStyleTag.endPosition))
        }
        return result
    }


    // --
    // MARK: Helper
    // --

    private func getCopyRanges(sectionTag: MarkdownTag, innerTags: [MarkdownTag]) -> [SimpleMarkdownProcessRange] {
        // Mark possible escape characters from the entire block for removal
        let sectionRange = SimpleMarkdownProcessRange(startPosition: sectionTag.startTextPosition, endPosition: sectionTag.endTextPosition, type: .copy)
        var modifyRanges = [sectionRange]
        for escapeSymbol in sectionTag.escapeSymbols {
            for modifyRange in modifyRanges {
                if let addRange = modifyRange.markRemoval(removeStartPosition: escapeSymbol.startPosition, removeEndPosition: escapeSymbol.endPosition) {
                    modifyRanges.append(addRange)
                    break
                }
            }
        }
        
        // Process inner tags
        var listWeightCounter = [Int]()
        for innerTag in innerTags {
            // Mark leading text for removal
            if innerTag.startTextPosition > innerTag.startPosition {
                for modifyRange in modifyRanges {
                    if let addRange = modifyRange.markRemoval(removeStartPosition: innerTag.startPosition, removeEndPosition: innerTag.startTextPosition) {
                        modifyRanges.append(addRange)
                        break
                    }
                }
            }
            
            // Mark trailing text for removal
            if innerTag.endTextPosition < innerTag.endPosition {
                for modifyRange in modifyRanges {
                    if let addRange = modifyRange.markRemoval(removeStartPosition: innerTag.endTextPosition, removeEndPosition: innerTag.endPosition) {
                        modifyRanges.append(addRange)
                        break
                    }
                }
            }
            
            // Insert text for newlines and lists
            if innerTag.type == .line {
                if sectionTag.type == .list {
                    var foundListTag = false
                    for checkTag in innerTags {
                        if (checkTag.type == .orderedListItem || checkTag.type == .unorderedListItem) && checkTag.startPosition == innerTag.startTextPosition {
                            foundListTag = true
                            break
                        }
                    }
                    if !foundListTag, let attributedStringGenerator = attributedStringGenerator {
                        modifyRanges.append(SimpleMarkdownProcessRange(startPosition: innerTag.startTextPosition, endPosition: innerTag.startTextPosition, type: .insertListToken, insertText: attributedStringGenerator.getListToken(fromType: .line, weight: 0, index: 0)))
                    }
                }
                if innerTag.endPosition < sectionTag.endPosition {
                    modifyRanges.append(SimpleMarkdownProcessRange(startPosition: innerTag.endTextPosition, endPosition: innerTag.endTextPosition, type: .insert, insertText: "\n"))
                }
            } else if innerTag.type == .orderedListItem || innerTag.type == .unorderedListItem, let attributedStringGenerator = attributedStringGenerator {
                let weightIndex = max(0, innerTag.weight - 1)
                if weightIndex >= listWeightCounter.count {
                    for _ in listWeightCounter.count...weightIndex {
                        listWeightCounter.append(0)
                    }
                } else if weightIndex + 1 < listWeightCounter.count {
                    listWeightCounter = listWeightCounter.dropLast(listWeightCounter.count - weightIndex - 1)
                } else if (listWeightCounter[weightIndex] > 0) != (innerTag.type == .orderedListItem) {
                    listWeightCounter[weightIndex] = 0
                }
                modifyRanges.append(SimpleMarkdownProcessRange(startPosition: innerTag.startTextPosition, endPosition: innerTag.startTextPosition, type: .insertListToken, insertText: attributedStringGenerator.getListToken(fromType: innerTag.type, weight: innerTag.weight, index: abs(listWeightCounter[weightIndex]) + 1)))
                listWeightCounter[weightIndex] += innerTag.type == .orderedListItem ? 1 : -1
            }
        }
        return modifyRanges.sorted { $0.startPosition < $1.startPosition || ($0.startPosition == $1.startPosition && $0.type.isInsert() && !$1.type.isInsert()) }
    }
    
    private func getDeleteRanges(sectionTag: MarkdownTag, copyRanges: [SimpleMarkdownProcessRange]) -> [SimpleMarkdownProcessRange] {
        // Add delete range between each copy range
        var result = [SimpleMarkdownProcessRange]()
        var previousRange = SimpleMarkdownProcessRange(startPosition: sectionTag.startPosition, endPosition: sectionTag.startPosition, type: .copy)
        for range in copyRanges {
            if range.type == .copy {
                if range.startPosition > previousRange.endPosition {
                    result.append(SimpleMarkdownProcessRange(startPosition: previousRange.endPosition, endPosition: range.startPosition, type: .delete))
                }
                previousRange = range
            } else {
                result.append(range)
            }
        }
            
        // Check if there is something left to delete at the end
        if previousRange.endPosition < sectionTag.endPosition {
            result.append(SimpleMarkdownProcessRange(startPosition: previousRange.endPosition, endPosition: sectionTag.endPosition, type: .delete))
        }
        
        // Return result
        return result
    }
    
}

// A helper enum to mark text ranges to copy, delete or to manually insert text
private enum SimpleMarkdownProcessRangeType {
    
    case copy
    case delete
    case insert
    case insertListToken
    
    func isInsert() -> Bool {
        return self == .insert || self == .insertListToken
    }
    
}

// A helper class to store a text range to copy, delete or to manually insert text
private class SimpleMarkdownProcessRange {
    
    var startPosition: Int
    var endPosition: Int
    let type: SimpleMarkdownProcessRangeType
    let insertText: String?
    
    init(startPosition: Int, endPosition: Int, type: SimpleMarkdownProcessRangeType, insertText: String? = nil) {
        self.startPosition = startPosition
        self.endPosition = endPosition
        self.type = type
        self.insertText = insertText
    }
    
    func markRemoval(removeStartPosition: Int, removeEndPosition: Int) -> SimpleMarkdownProcessRange? {
        if type == .copy && isValid() {
            if removeStartPosition > startPosition && removeEndPosition < endPosition {
                let split = SimpleMarkdownProcessRange(startPosition: removeEndPosition, endPosition: endPosition, type: .copy)
                endPosition = removeStartPosition
                return split
            } else if removeStartPosition <= startPosition && removeEndPosition > startPosition {
                startPosition = removeEndPosition
                endPosition = max(startPosition, endPosition)
            } else if removeStartPosition < endPosition && removeEndPosition >= endPosition {
                endPosition = removeStartPosition
                startPosition = min(startPosition, endPosition)
            }
        }
        return nil
    }
    
    func isValid() -> Bool {
        return startPosition < endPosition
    }
    
}

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

    private func processInternal() {
        let sectionTags = originalTags.filter { $0.type.isSection() }
        for sectionIndex in sectionTags.indices {
            // Determine tags and copy ranges for this section
            let sectionTag = sectionTags[sectionIndex]
            let innerTags = originalTags.filter { !$0.type.isSection() && $0.startPosition ?? 0 >= sectionTag.startPosition ?? 0 && $0.endPosition ?? 0 <= sectionTag.endPosition ?? 0 }
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
            let blockPositionAdjustment = (sectionTag.startPosition ?? 0) - startTextPosition
            for innerTag in innerTags {
                // Calculate position offset adjustments
                var startOffset = -blockPositionAdjustment
                var endOffset = -blockPositionAdjustment
                for range in deleteRanges {
                    if range.type == .delete && range.startPosition < innerTag.endTextPosition ?? 0 {
                        let rangeLength = range.endPosition - range.startPosition
                        let tagLength = (innerTag.endTextPosition ?? 0) - (innerTag.startTextPosition ?? 0)
                        let startAdjustment = max(0, min(rangeLength, (innerTag.startTextPosition ?? 0) - range.startPosition))
                        startOffset -= startAdjustment
                        endOffset -= startAdjustment + min(tagLength, min(rangeLength, max(0, min((innerTag.endTextPosition ?? 0) - range.startPosition, range.endPosition - (innerTag.startTextPosition ?? 0)))))
                    } else if (range.type == .insert || range.type == .insertListToken) && range.startPosition < innerTag.endTextPosition ?? 0 {
                        let length = range.insertText?.count ?? 0
                        let includeInTag = range.type == .insertListToken && (innerTag.type == .orderedList || innerTag.type == .unorderedList || innerTag.type == .line) && range.startPosition == innerTag.startTextPosition ?? 0
                        if range.endPosition <= innerTag.startTextPosition ?? 0 && !includeInTag {
                            startOffset += length
                        }
                        endOffset += length
                    }
                }
                
                // Add processed tag
                let startPosition = (innerTag.startTextPosition ?? 0) + startOffset
                let endPosition = (innerTag.endTextPosition ?? 0) + endOffset
                let processedTag = ProcessedMarkdownTag(type: innerTag.type, weight: innerTag.weight, startIndex: text.index(startTextIndex, offsetBy: startPosition - processedSectionTag.startPosition), endIndex: text.index(startTextIndex, offsetBy: endPosition - processedSectionTag.startPosition), startPosition: startPosition, endPosition: endPosition)
                if innerTag.type == .link {
                    if let startExtraIndex = innerTag.startExtraIndex, let endExtraIndex = innerTag.endExtraIndex {
                        processedTag.link = String(originalText[startExtraIndex..<endExtraIndex])
                    } else if let startTextIndex = innerTag.startTextIndex, let endTextIndex = innerTag.endTextIndex {
                        processedTag.link = String(originalText[startTextIndex..<endTextIndex])
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
    

    // --
    // MARK: Processing
    // --

    private func getCopyRanges(sectionTag: MarkdownTag, innerTags: [MarkdownTag]) -> [SimpleMarkdownProcessRange] {
        if let sectionRange = SimpleMarkdownProcessRange(startPosition: sectionTag.startTextPosition, endPosition: sectionTag.endTextPosition, type: .copy) {
            // Mark possible escape characters from the entire block for removal
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
                if innerTag.startTextPosition ?? 0 > innerTag.startPosition ?? 0 {
                    for modifyRange in modifyRanges {
                        if let addRange = modifyRange.markRemoval(removeStartPosition: innerTag.startPosition, removeEndPosition: innerTag.startTextPosition) {
                            modifyRanges.append(addRange)
                            break
                        }
                    }
                }
                
                // Mark trailing text for removal
                if innerTag.endTextPosition ?? 0 < innerTag.endPosition ?? 0 {
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
                            if (checkTag.type == .orderedList || checkTag.type == .unorderedList) && checkTag.startPosition ?? 0 == innerTag.startTextPosition ?? 0 {
                                foundListTag = true
                                break
                            }
                        }
                        if !foundListTag, let attributedStringGenerator = attributedStringGenerator, let listExtraLineRange = SimpleMarkdownProcessRange(startPosition: innerTag.startTextPosition, endPosition: innerTag.startTextPosition, type: .insertListToken, insertText: attributedStringGenerator.getListToken(fromType: .line, weight: 0, index: 0)) {
                            modifyRanges.append(listExtraLineRange)
                        }
                    }
                    if innerTag.endPosition ?? 0 < sectionTag.endPosition ?? 0, let newlineRange = SimpleMarkdownProcessRange(startPosition: innerTag.endTextPosition, endPosition: innerTag.endTextPosition, type: .insert, insertText: "\n") {
                        modifyRanges.append(newlineRange)
                    }
                } else if innerTag.type == .orderedList || innerTag.type == .unorderedList, let attributedStringGenerator = attributedStringGenerator {
                    let weightIndex = max(0, innerTag.weight - 1)
                    if weightIndex >= listWeightCounter.count {
                        for _ in listWeightCounter.count...weightIndex {
                            listWeightCounter.append(0)
                        }
                    } else if weightIndex + 1 < listWeightCounter.count {
                        listWeightCounter = listWeightCounter.dropLast(listWeightCounter.count - weightIndex - 1)
                    } else if (listWeightCounter[weightIndex] > 0) != (innerTag.type == .orderedList) {
                        listWeightCounter[weightIndex] = 0
                    }
                    if let listPointRange = SimpleMarkdownProcessRange(startPosition: innerTag.startTextPosition, endPosition: innerTag.startTextPosition, type: .insertListToken, insertText: attributedStringGenerator.getListToken(fromType: innerTag.type, weight: innerTag.weight, index: abs(listWeightCounter[weightIndex]) + 1)) {
                        modifyRanges.append(listPointRange)
                    }
                    listWeightCounter[weightIndex] += innerTag.type == .orderedList ? 1 : -1
                }
            }
            return modifyRanges.sorted { $0.startPosition < $1.startPosition || ($0.startPosition == $1.startPosition && $0.type.isInsert() && !$1.type.isInsert() ) }
        }
        return []
    }
    
    private func getDeleteRanges(sectionTag: MarkdownTag, copyRanges: [SimpleMarkdownProcessRange]) -> [SimpleMarkdownProcessRange] {
        var result = [SimpleMarkdownProcessRange]()
        if var previousRange = SimpleMarkdownProcessRange(startPosition: sectionTag.startPosition, endPosition: sectionTag.startPosition, type: .copy) {
            // Add delete range between each copy range
            for range in copyRanges {
                if range.type == .copy {
                    if range.startPosition > previousRange.endPosition {
                        if let deleteRange = SimpleMarkdownProcessRange(startPosition: previousRange.endPosition, endPosition: range.startPosition, type: .delete) {
                            result.append(deleteRange)
                        }
                    }
                    previousRange = range
                } else {
                    result.append(range)
                }
            }
            
            // Check if there is something left to delete at the end
            if previousRange.endPosition < sectionTag.endPosition ?? 0 {
                if let deleteRange = SimpleMarkdownProcessRange(startPosition: previousRange.endPosition, endPosition: sectionTag.endPosition, type: .delete) {
                    result.append(deleteRange)
                }
            }
        }
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
    
    init?(startPosition: Int?, endPosition: Int?, type: SimpleMarkdownProcessRangeType, insertText: String? = nil) {
        if let startPosition = startPosition, let endPosition = endPosition {
            self.startPosition = startPosition
            self.endPosition = endPosition
            self.type = type
            self.insertText = insertText
        } else {
            return nil
        }
    }
    
    func markRemoval(removeStartPosition: Int?, removeEndPosition: Int?) -> SimpleMarkdownProcessRange? {
        if let removeStartPosition = removeStartPosition, let removeEndPosition = removeEndPosition, type == .copy, isValid() {
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

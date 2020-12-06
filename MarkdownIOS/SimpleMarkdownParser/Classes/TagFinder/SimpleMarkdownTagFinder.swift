//
//  SimpleMarkdownTagFinder.swift
//  SimpleMarkdownParser Pod
//
//  Library tag parsing: combine markdown symbols into tags
//

// Finds markdown tags in text based on markdown symbols
public class SimpleMarkdownTagFinder {
    
    // --
    // MARK: Default initializer
    // --

    public init() {
    }


    // --
    // MARK: High level parsing
    // --

    public func findTags(text: String, symbols: [MarkdownSymbol]) -> [MarkdownTag] {
        // Find first paragraph tag
        var result = [MarkdownTag]()
        var paragraphIndex = findNextParagraphBlockIndex(symbols: symbols)
        var startSymbolIndex = 0
        for index in 0..<symbols.count {
            if symbols[index].startPosition >= symbols[paragraphIndex].startPosition {
                startSymbolIndex = index
                break
            }
        }
        
        // Add lines that could come before it
        if startSymbolIndex > 0 {
            let scanSymbols = symbols[0..<startSymbolIndex]
            let dummyParagraphTag = MarkdownTag()
            dummyParagraphTag.type = .paragraph
            dummyParagraphTag.startPosition = symbols[0].startPosition
            dummyParagraphTag.endPosition = symbols[startSymbolIndex].startPosition - symbols[startSymbolIndex].linePosition
            dummyParagraphTag.startIndex = symbols[0].startIndex
            dummyParagraphTag.endIndex = text.index(symbols[startSymbolIndex].startIndex, offsetBy: -symbols[startSymbolIndex].linePosition)
            result.append(contentsOf: findLineTags(text: text, symbols: scanSymbols, forParagraph: dummyParagraphTag))
        }
        
        // Start finding inner tags
        while paragraphIndex >= 0 {
            // Set up paragraph tag
            let nextParagraphIndex = findNextParagraphBlockIndex(symbols: symbols, afterParagraphIndex: paragraphIndex)
            let paragraphTag = makeParagraphTag(text: text, symbols: symbols, fromIndex: paragraphIndex, toIndex: nextParagraphIndex)
            result.append(paragraphTag)
            
            // Determine symbols found within the paragraph tag
            var endSymbolIndex = startSymbolIndex
            for index in startSymbolIndex..<symbols.count {
                if symbols[index].startPosition >= paragraphTag.startPosition ?? 0 && symbols[index].endPosition <= paragraphTag.endPosition ?? 0 {
                    endSymbolIndex = index + 1
                }
            }
            
            // Find line tags and shorten the paragraph if empty lines are at the end
            let scanSymbols = symbols[startSymbolIndex..<endSymbolIndex]
            let lineTags = findLineTags(text: text, symbols: scanSymbols, forParagraph: paragraphTag)
            result.append(contentsOf: lineTags)
            for index in lineTags.indices {
                if lineTags[index].startTextPosition ?? 0 >= lineTags[index].endTextPosition ?? 0 {
                    if index > 0 {
                        paragraphTag.endPosition = lineTags[index - 1].endPosition
                        paragraphTag.endIndex = lineTags[index - 1].endIndex
                    }
                    break
                }
            }

            // Add other tags within the paragraph
            result.append(contentsOf: findTextStyleTags(text: text, symbols: scanSymbols, forParagraph: paragraphTag))
            result.append(contentsOf: findLinkTags(text: text, symbols: scanSymbols, forParagraph: paragraphTag))
            result.append(contentsOf: findListTags(text: text, symbols: scanSymbols, forParagraph: paragraphTag))
            
            // Prepare for the next iteration
            startSymbolIndex = endSymbolIndex
            paragraphIndex = nextParagraphIndex
        }
        
        // Add escape symbols to tags
        let escapeSymbols = symbols.filter { $0.type == .escape }
        for tag in result {
            tag.escapeSymbols = escapeSymbols.filter { $0.startPosition >= tag.startPosition ?? 0 && $0.startPosition < tag.endPosition ?? 0 }
        }
        
        // Sort and return result
        result.sort { ($0.startPosition ?? 0) < ($1.startPosition ?? 0) || ($0.type.rawValue < $1.type.rawValue && ($0.startPosition ?? 0) <= ($1.startPosition ?? 0)) }
        return result
    }
    
    
    // --
    // MARK: Check paragraphs
    // --
    
    private func makeParagraphTag(text: String, symbols: [MarkdownSymbol], fromIndex: Int, toIndex: Int = -1, firstItem: Bool = false) -> MarkdownTag {
        // Set up tag with type
        let tag = MarkdownTag()
        tag.type = getParagraphType(symbols: symbols, nearSymbol: symbols[fromIndex])
        
        // Set position range
        tag.startPosition = firstItem ? 0 : symbols[fromIndex].startPosition - symbols[fromIndex].linePosition
        tag.endPosition = toIndex >= 0 ? symbols[toIndex].startPosition - symbols[toIndex].linePosition : text.count
        tag.startTextPosition = symbols[fromIndex].startPosition
        if toIndex > fromIndex || toIndex < 0 {
            let endIndex = toIndex < 0 ? symbols.count : toIndex
            for index in fromIndex..<endIndex {
                if symbols[index].type == .textBlock {
                    tag.endTextPosition = symbols[index].endPosition
                }
            }
        } else {
            tag.endTextPosition = symbols[fromIndex].endPosition
        }
        
        // Set index range
        tag.startIndex = firstItem ? text.startIndex : text.index(symbols[fromIndex].startIndex, offsetBy: -symbols[fromIndex].linePosition)
        tag.endIndex = toIndex >= 0 ? text.index(symbols[toIndex].startIndex, offsetBy: -symbols[toIndex].linePosition) : text.endIndex
        tag.startTextIndex = symbols[fromIndex].startIndex
        if toIndex > fromIndex || toIndex < 0 {
            let endIndex = toIndex < 0 ? symbols.count : toIndex
            for index in fromIndex..<endIndex {
                if symbols[index].type == .textBlock {
                    tag.endTextIndex = symbols[index].endIndex
                }
            }
        } else {
            tag.endTextIndex = symbols[fromIndex].endIndex
        }

        // For headers, exclude header characters from text and determine weight, then trim for good measure
        if tag.type == .header {
            var firstHeader = true
            for symbol in symbols {
                if symbol.startPosition >= tag.startPosition ?? 0 {
                    if symbol.endPosition <= tag.endPosition ?? 0 {
                        if symbol.type == .header {
                            if firstHeader {
                                tag.startTextPosition = symbol.endPosition
                                tag.startTextIndex = symbol.endIndex
                                tag.weight = symbol.endPosition - symbol.startPosition
                                firstHeader = false
                            } else {
                                tag.endTextPosition = symbol.startPosition
                                tag.endTextIndex = symbol.startIndex
                                break
                            }
                        }
                    } else {
                        break
                    }
                }
            }
            trimTagSpaces(text: text, tag: tag)
        }
        
        // Return result
        return tag
    }
    
    private func findNextParagraphBlockIndex(symbols: [MarkdownSymbol], afterParagraphIndex: Int = -1) -> Int {
        let afterParagraphType = afterParagraphIndex >= 0 ? getParagraphType(symbols: symbols, nearSymbol: symbols[afterParagraphIndex]) : .paragraph
        var consecutiveNewlines = 0
        for index in (afterParagraphIndex + 1)..<symbols.count {
            if symbols[index].type == .newline {
                consecutiveNewlines += 1
            } else if symbols[index].type == .textBlock {
                let paragraphType = getParagraphType(symbols: symbols, nearSymbol: symbols[index])
                let canAbortEarly = paragraphType == .header || afterParagraphType == .header || (afterParagraphType != .list && paragraphType != afterParagraphType)
                if consecutiveNewlines > 1 || afterParagraphIndex < 0 || (consecutiveNewlines > 0 && canAbortEarly) {
                    return index
                } else {
                    consecutiveNewlines = 0
                }
            }
        }
        return -1
    }
    
    private func getParagraphType(symbols: [MarkdownSymbol], nearSymbol: MarkdownSymbol) -> MarkdownTagType {
        let checkLine = nearSymbol.line
        let checkLinePosition = nearSymbol.linePosition
        for symbol in symbols {
            if symbol.line == checkLine && symbol.linePosition == checkLinePosition {
                switch symbol.type {
                case .header:
                    return .header
                case .orderedListItem, .unorderedListItem:
                    return .list
                default: break
                }
            } else if symbol.line > checkLine {
                break
            }
        }
        return .paragraph
    }
    
    
    // --
    // MARK: Check lines
    // --

    private func findLineTags(text: String, symbols: ArraySlice<MarkdownSymbol>, forParagraph: MarkdownTag) -> [MarkdownTag] {
        // Split paragraph in lines
        var result = [MarkdownTag]()
        if let startPosition = forParagraph.startPosition, let endPosition = forParagraph.endPosition, let startIndex = forParagraph.startIndex, let endIndex = forParagraph.endIndex {
            // Search for newline symbols
            let paragraphSymbol = MarkdownSymbol(type: .textBlock, line: 0, startPosition: startPosition, startIndex: startIndex, endPosition: endPosition, endIndex: endIndex, linePosition: 0)
            var startSymbol = paragraphSymbol
            for symbol in symbols {
                if symbol.type == .newline {
                    result.append(makeLineTag(text: text, startSymbol: startSymbol, endSymbol: symbol))
                    startSymbol = symbol
                }
            }
            
            // Handle remains
            if startSymbol.endPosition < paragraphSymbol.endPosition || startSymbol === paragraphSymbol {
                result.append(makeLineTag(text: text, startSymbol: startSymbol, endSymbol: paragraphSymbol))
            }
        }
        
        // Return result
        return result
    }
    
    private func makeLineTag(text: String, startSymbol: MarkdownSymbol, endSymbol: MarkdownSymbol) -> MarkdownTag {
        let tag = MarkdownTag()
        tag.type = .line
        tag.weight = 0
        tag.startPosition = startSymbol.type == .newline ? startSymbol.endPosition : startSymbol.startPosition
        tag.endPosition = endSymbol.endPosition
        tag.startIndex = startSymbol.type == .newline ? startSymbol.endIndex : startSymbol.startIndex
        tag.endIndex = endSymbol.endIndex
        tag.startTextPosition = startSymbol.type == .newline ? startSymbol.endPosition : startSymbol.startPosition
        tag.endTextPosition = endSymbol.type == .newline ? endSymbol.startPosition : endSymbol.endPosition
        tag.startTextIndex = startSymbol.type == .newline ? startSymbol.endIndex : startSymbol.startIndex
        tag.endTextIndex = endSymbol.type == .newline ? endSymbol.startIndex : endSymbol.endIndex
        trimTagSpaces(text: text, tag: tag)
        return tag
    }

    
    // --
    // MARK: Check text styles
    // --

    private func findTextStyleTags(text: String, symbols: ArraySlice<MarkdownSymbol>, forParagraph: MarkdownTag) -> [MarkdownTag] {
        // Find matching text style symbols in two batches (the second one is used to catch edge cases)
        var result = [MarkdownTag]()
        var checkSymbols = symbols.filter { $0.type.isTextStyle() }
        var phase = 0
        while phase < 2 && checkSymbols.count > 1 {
            for index in 0..<checkSymbols.count - 1 {
                if phase == 0 && checkSymbols[index + 1].type == checkSymbols[index].type {
                    result.append(makeTextStyleTag(text: text, startSymbol: checkSymbols[index], endSymbol: checkSymbols[index + 1]))
                    checkSymbols.remove(at: index + 1)
                    checkSymbols.remove(at: index)
                    break
                } else if phase == 1, let nextIndex = checkSymbols.indices.first(where: { $0 > index && checkSymbols[$0].type == checkSymbols[index].type } ) {
                    result.append(makeTextStyleTag(text: text, startSymbol: checkSymbols[index], endSymbol: checkSymbols[nextIndex]))
                    for removeIndex in (index...nextIndex).reversed() {
                        checkSymbols.remove(at: removeIndex)
                    }
                    break
                } else if index == checkSymbols.count - 2 {
                    phase += 1
                    break
                }
            }
        }
        
        // Return result
        return result
    }
    
    private func makeTextStyleTag(text: String, startSymbol: MarkdownSymbol, endSymbol: MarkdownSymbol) -> MarkdownTag {
        let tag = MarkdownTag()
        tag.type = startSymbol.type == .thirdTextStyle ? .alternativeTextStyle : .textStyle
        tag.weight = min(startSymbol.endPosition - startSymbol.startPosition, endSymbol.endPosition - endSymbol.startPosition)
        tag.startPosition = startSymbol.startPosition
        tag.endPosition = endSymbol.endPosition
        tag.startIndex = startSymbol.startIndex
        tag.endIndex = endSymbol.endIndex
        tag.startTextPosition = startSymbol.startPosition + tag.weight
        tag.endTextPosition = endSymbol.endPosition - tag.weight
        tag.startTextIndex = text.index(startSymbol.startIndex, offsetBy: tag.weight)
        tag.endTextIndex = text.index(endSymbol.endIndex, offsetBy: -tag.weight)
        return tag
    }
    
    
    // --
    // MARK: Check links
    // --

    private func findLinkTags(text: String, symbols: ArraySlice<MarkdownSymbol>, forParagraph: MarkdownTag) -> [MarkdownTag] {
        // Find enclosing link symbols and compose tags (with optional URL override)
        var result = [MarkdownTag]()
        var inLinkSymbol: MarkdownSymbol?
        for symbol in symbols {
            if symbol.type == .newline {
                inLinkSymbol = nil
            } else if symbol.type == .openLink && inLinkSymbol == nil {
                inLinkSymbol = symbol
            } else if let startLinkSymbol = inLinkSymbol, symbol.type == .closeLink {
                result.append(makeLinkTag(text: text, startSymbol: startLinkSymbol, endSymbol: symbol, symbols: symbols))
                inLinkSymbol = nil
            }
        }
        
        // Return result
        return result
    }

    private func makeLinkTag(text: String, startSymbol: MarkdownSymbol, endSymbol: MarkdownSymbol, symbols: ArraySlice<MarkdownSymbol>) -> MarkdownTag {
        // Set up basic tag
        let tag = MarkdownTag()
        tag.type = .link
        tag.weight = 0
        tag.startPosition = startSymbol.startPosition
        tag.endPosition = endSymbol.endPosition
        tag.startIndex = startSymbol.startIndex
        tag.endIndex = endSymbol.endIndex
        tag.startTextPosition = startSymbol.startPosition + 1
        tag.endTextPosition = endSymbol.endPosition - 1
        tag.startTextIndex = text.index(after: startSymbol.startIndex)
        tag.endTextIndex = text.index(before: endSymbol.endIndex)

        // Add extra information if found
        var inUrlSymbol: MarkdownSymbol?
        var foundDoubleQuotes = 0
        var cutOffExtraPosition: Int?
        var cutOffExtraIndex: String.Index?
        for symbol in symbols {
            if symbol.startPosition == endSymbol.endPosition && symbol.type == .openUrl {
                inUrlSymbol = symbol
            } else if symbol.startPosition > endSymbol.endPosition && (inUrlSymbol == nil || symbol.type == .newline) {
                break
            } else if inUrlSymbol != nil && symbol.type == .doubleQuote {
                if foundDoubleQuotes == 0 {
                    cutOffExtraPosition = symbol.startPosition
                    cutOffExtraIndex = symbol.startIndex
                }
                foundDoubleQuotes += 1
            } else if let startUrlSymbol = inUrlSymbol, symbol.type == .closeUrl {
                tag.startExtraPosition = startUrlSymbol.endPosition
                tag.endExtraPosition = foundDoubleQuotes > 1 ? cutOffExtraPosition : symbol.startPosition
                tag.startExtraIndex = startUrlSymbol.endIndex
                tag.endExtraIndex = foundDoubleQuotes > 1 ? cutOffExtraIndex : symbol.startIndex
                tag.endPosition = symbol.endPosition
                tag.endIndex = symbol.endIndex
                trimExtraSpaces(text: text, tag: tag)
                break
            }
        }
        
        // Return result
        return tag
    }

    
    // --
    // MARK: Check lists
    // --

    private func findListTags(text: String, symbols: ArraySlice<MarkdownSymbol>, forParagraph: MarkdownTag) -> [MarkdownTag] {
        // Find ordered and unordered list items and compose tags
        var result = [MarkdownTag]()
        var inListSymbol: MarkdownSymbol?
        for symbol in symbols {
            if symbol.type == .orderedListItem || symbol.type == .unorderedListItem {
                if let checkListSymbol = inListSymbol {
                    result.append(makeListItemTag(text: text, startSymbol: checkListSymbol, endPosition: symbol.startPosition, endIndex: symbol.startIndex))
                }
                inListSymbol = symbol
            }
        }
        
        // Add last list item (if needed) and return result
        if let checkListSymbol = inListSymbol, let endPosition = forParagraph.endPosition, let endIndex = forParagraph.endIndex {
            result.append(makeListItemTag(text: text, startSymbol: checkListSymbol, endPosition: endPosition, endIndex: endIndex))
        }
        return result
    }

    private func makeListItemTag(text: String, startSymbol: MarkdownSymbol, endPosition: Int, endIndex: String.Index) -> MarkdownTag {
        let tag = MarkdownTag()
        tag.type = startSymbol.type == .orderedListItem ? .orderedList : .unorderedList
        tag.weight = 1 + startSymbol.linePosition / 2
        tag.startPosition = startSymbol.startPosition
        tag.endPosition = endPosition
        tag.startIndex = startSymbol.startIndex
        tag.endIndex = endIndex
        tag.startTextPosition = startSymbol.endPosition
        tag.endTextPosition = endPosition
        tag.startTextIndex = startSymbol.endIndex
        tag.endTextIndex = endIndex
        trimTagSpaces(text: text, tag: tag)
        return tag
    }

    
    // --
    // MARK: Helpers
    // --
    
    private func trimTagSpaces(text: String, tag: MarkdownTag) {
        // Update start
        if var startTextIndex = tag.startTextIndex, var startTextPosition = tag.startTextPosition {
            while startTextPosition < tag.endTextPosition ?? 0 && text[startTextIndex].isWhitespace {
                startTextIndex = text.index(after: startTextIndex)
                startTextPosition += 1
            }
            tag.startTextPosition = startTextPosition
            tag.startTextIndex = startTextIndex
        }
        
        // Update end
        if var endTextIndex = tag.endTextIndex, var endTextPosition = tag.endTextPosition {
            while endTextPosition > tag.startTextPosition ?? 0 {
                let checkIndex = text.index(before: endTextIndex)
                if !text[checkIndex].isWhitespace {
                    break
                }
                endTextIndex = checkIndex
                endTextPosition -= 1
            }
            tag.endTextPosition = endTextPosition
            tag.endTextIndex = endTextIndex
        }
    }

    private func trimExtraSpaces(text: String, tag: MarkdownTag) {
        if var endExtraIndex = tag.endExtraIndex, var endExtraPosition = tag.endExtraPosition {
            while endExtraPosition > tag.startExtraPosition ?? 0 {
                let checkIndex = text.index(before: endExtraIndex)
                if !text[checkIndex].isWhitespace {
                    break
                }
                endExtraIndex = checkIndex
                endExtraPosition -= 1
            }
            tag.endExtraPosition = endExtraPosition
            tag.endExtraIndex = endExtraIndex
        }
    }

}

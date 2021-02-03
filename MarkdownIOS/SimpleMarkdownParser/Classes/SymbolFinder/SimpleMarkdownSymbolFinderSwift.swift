//
//  SimpleMarkdownSymbolFinderSwift.swift
//  SimpleMarkdownParser Pod
//
//  Library symbol parsing: implements the symbol finder in swift
//

// Symbol finder implementation in swift
public class SimpleMarkdownSymbolFinderSwift: SimpleMarkdownSymbolFinder {
    
    // --
    // MARK: Members
    // --
    
    public let symbolStorage = SimpleMarkdownSymbolStorage()
    private var currentLine = 0
    private var linePosition = 0
    private var lastEscapePosition = -100
    private var currentTextBlockSymbol: MarkdownSymbol?
    private var currentHeaderSymbol: MarkdownSymbol?
    private var currentTextStyleSymbol: MarkdownSymbol?
    private var currentListItemSymbol: MarkdownSymbol?
    private var needListDotSeparator = false
    

    // --
    // MARK: Default initializer
    // --

    public init() {
    }


    // --
    // MARK: Scanning text
    // --

    public func scanText(_ text: String) {
        // Prepare
        var index = text.startIndex
        symbolStorage.clearSymbols()
        
        // Scan text
        for i in 0..<text.count {
            let nextIndex = text.index(after: index)
            addCharacter(position: i, index: index, nextIndex: nextIndex, character: text[index])
            index = nextIndex
        }
        
        // Finalize
        finalize()
    }
    

    // --
    // MARK: Internal symbol finder
    // --

    private func addCharacter(position: Int, index: String.Index, nextIndex: String.Index, character: Character) {
        // Handle character escaping
        var escaped = false
        if character == "\\" {
            if lastEscapePosition != position - 1 {
                lastEscapePosition = position
                symbolStorage.addSymbol(MarkdownSymbol(type: .escape, line: currentLine, startPosition: position, startIndex: index, endPosition: position + 1, endIndex: nextIndex, linePosition: linePosition))
            }
            escaped = true
        } else {
            escaped = lastEscapePosition == position - 1
        }
        
        // Check for double quotes
        if !escaped && character == "\"" {
            symbolStorage.addSymbol(MarkdownSymbol(type: .doubleQuote, line: currentLine, startPosition: position, startIndex: index, endPosition: position + 1, endIndex: nextIndex, linePosition: linePosition))
        }
        
        // Check for text blocks
        let isTextCharacter = !character.isWhitespace || escaped
        if let textBlockSymbol = currentTextBlockSymbol {
            if isTextCharacter {
                textBlockSymbol.updateEndPosition(position + 1, index: nextIndex)
            }
        } else if isTextCharacter {
            currentTextBlockSymbol = MarkdownSymbol(type: .textBlock, line: currentLine, startPosition: position, startIndex: index, endPosition: position + 1, endIndex: nextIndex, linePosition: linePosition)
        }
        
        // Check for newlines
        if character.isNewline && !escaped {
            if let textBlockSymbol = currentTextBlockSymbol {
                symbolStorage.addSymbol(textBlockSymbol)
                currentTextBlockSymbol = nil
            }
            symbolStorage.addSymbol(MarkdownSymbol(type: .newline, line: currentLine, startPosition: position, startIndex: index, endPosition: position + 1, endIndex: nextIndex, linePosition: linePosition))
        }
        
        // Check for headers
        let isHeaderCharacter = character == "#" && !escaped
        if let headerSymbol = currentHeaderSymbol {
            if isHeaderCharacter {
                headerSymbol.updateEndPosition(position + 1, index: nextIndex)
            } else {
                symbolStorage.addSymbol(headerSymbol)
                currentHeaderSymbol = nil
            }
        } else if isHeaderCharacter {
            currentHeaderSymbol = MarkdownSymbol(type: .header, line: currentLine, startPosition: position, startIndex: index, endPosition: position + 1, endIndex: nextIndex, linePosition: linePosition)
        }
        
        // Check for text styles
        var textStyleType = MarkdownSymbolType.escape
        if !escaped {
            if character == "*" {
                textStyleType = .firstTextStyle
            } else if character == "_" {
                textStyleType = .secondTextStyle
            } else if character == "~" {
                textStyleType = .thirdTextStyle
            }
        }
        if let textStyleSymbol = currentTextStyleSymbol {
            if textStyleSymbol.type == textStyleType {
                textStyleSymbol.updateEndPosition(position + 1, index: nextIndex)
            } else {
                symbolStorage.addSymbol(textStyleSymbol)
                currentTextStyleSymbol = nil
                if textStyleType != .escape {
                    currentTextStyleSymbol = MarkdownSymbol(type: textStyleType, line: currentLine, startPosition: position, startIndex: index, endPosition: position + 1, endIndex: nextIndex, linePosition: linePosition)
                }
            }
        } else if textStyleType != .escape {
            currentTextStyleSymbol = MarkdownSymbol(type: textStyleType, line: currentLine, startPosition: position, startIndex: index, endPosition: position + 1, endIndex: nextIndex, linePosition: linePosition)
        }
        
        // Check for lists
        if !escaped {
            if let listItemSymbol = currentListItemSymbol {
                if listItemSymbol.type == .unorderedListItem && character == " " {
                    symbolStorage.addSymbol(listItemSymbol)
                    currentListItemSymbol = nil
                } else if listItemSymbol.type == .orderedListItem {
                    if needListDotSeparator && (character.isNumber || character == ".") {
                        listItemSymbol.updateEndPosition(position + 1, index: nextIndex)
                        if character == "." {
                            needListDotSeparator = false
                        }
                    } else if !needListDotSeparator && character == " " {
                        symbolStorage.addSymbol(listItemSymbol)
                        currentListItemSymbol = nil
                    } else {
                        currentListItemSymbol = nil
                    }
                } else {
                    currentListItemSymbol = nil
                }
            } else if let textBlockSymbol = currentTextBlockSymbol, textBlockSymbol.startPosition == position {
                let isBulletCharacter = character == "*" || character == "+" || character == "-"
                if isBulletCharacter || character.isNumber {
                    currentListItemSymbol = MarkdownSymbol(type: isBulletCharacter ? .unorderedListItem : .orderedListItem, line: currentLine, startPosition: position, startIndex: index, endPosition: position + 1, endIndex: nextIndex, linePosition: linePosition)
                    needListDotSeparator = !isBulletCharacter
                }
            }
        } else {
            currentListItemSymbol = nil
        }
        
        // Check for links
        if !escaped {
            let linkSymbolType: MarkdownSymbolType
            if character == "[" {
                linkSymbolType = .openLink
            } else if character == "]" {
                linkSymbolType = .closeLink
            } else if character == "(" {
                linkSymbolType = .openUrl
            } else if character == ")" {
                linkSymbolType = .closeUrl
            } else {
                linkSymbolType = .escape
            }
            if linkSymbolType != .escape {
                symbolStorage.addSymbol(MarkdownSymbol(type: linkSymbolType, line: currentLine, startPosition: position, startIndex: index, endPosition: position + 1, endIndex: nextIndex, linePosition: linePosition))
            }
        }
        
        // Update line position
        if !escaped && character.isNewline {
            linePosition = 0
            currentLine += 1
        } else if lastEscapePosition != position {
            linePosition += 1
        }
    }
    
    private func finalize() {
        // Finish symbol finders in progress
        if let textBlockSymbol = currentTextBlockSymbol {
            symbolStorage.addSymbol(textBlockSymbol)
        }
        if let headerSymbol = currentHeaderSymbol {
            symbolStorage.addSymbol(headerSymbol)
        }
        if let textStyleSymbol = currentTextStyleSymbol {
            symbolStorage.addSymbol(textStyleSymbol)
        }
        
        // Sort found symbols and remove duplicates
        symbolStorage.sort()
        symbolStorage.cleanOverlaps()
    }

}

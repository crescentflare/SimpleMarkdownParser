//
//  SimpleMarkdownSymbolStorage.swift
//  SimpleMarkdownParser Pod
//
//  Library symbol parsing: stores markdown symbols being found during text scanning
//

// Stores found markdown symbol markers
public class SimpleMarkdownSymbolStorage {
    
    // --
    // MARK: Members
    // --

    public var symbols = [MarkdownSymbol]()
    

    // --
    // MARK: Storage
    // --

    public func addSymbol(_ symbol: MarkdownSymbol) {
        symbols.append(symbol)
    }
    
    public func clearSymbols() {
        symbols = [MarkdownSymbol]()
    }
    
    public func sort() {
        symbols.sort { $0.startPosition < $1.startPosition }
    }
    

    // --
    // MARK: Cleaning
    // --

    public func cleanOverlaps() {
        // Collect indices to remove
        var removeIndices = [Int]()
        
        // Unordered list items override text style
        for index in symbols.indices {
            if symbols[index].type == .firstTextStyle && symbols[index].endPosition - symbols[index].startPosition == 1 {
                var startIndex = index + 1
                for checkIndex in (0..<index).reversed() {
                    if symbols[checkIndex].startPosition == symbols[index].startPosition {
                        startIndex = checkIndex
                    } else {
                        break
                    }
                }
                for checkIndex in startIndex..<symbols.count {
                    if checkIndex != index {
                        if symbols[checkIndex].startPosition == symbols[index].startPosition {
                            if symbols[checkIndex].type == .unorderedListItem {
                                removeIndices.append(index)
                                break
                            }
                        } else {
                            break
                        }
                    }
                }
            }
        }
        
        // Remove items with indices
        for index in removeIndices.reversed() {
            symbols.remove(at: index)
        }
    }
    
}

//
//  SimpleMarkdownParserSwift.swift
//  SimpleMarkdownParser Pod
//
//  Core library: basic Swift implementation of the markdown core parser
//

// Helper object for markdown tag markers
private class MarkdownMarker {
    let chr: Character
    var weight: Int
    let position: String.Index
    
    fileprivate init(chr: Character, weight: Int, position: String.Index) {
        self.chr = chr
        self.weight = weight
        self.position = position
    }
}

// Parser class
open class SimpleMarkdownParserSwift : SimpleMarkdownParser {
    
    // --
    // MARK: Default initializer
    // --

    public init() {
    }

    
    // --
    // MARK: Finding tags
    // --
    
    open func findTags(_ markdownText: String) -> [MarkdownTag] {
        var foundTags: [MarkdownTag] = []
        let maxLength = markdownText.endIndex
        var paragraphStartPos: String.Index? = nil
        var curLine: MarkdownTag? = scanLine(markdownText, position: markdownText.startIndex, maxLength: maxLength, sectionType: .paragraph)
        while curLine != nil {
            // Fetch next line ahead
            let hasNextLine = curLine!.endPosition! < maxLength
            let isEmptyLine = markdownText.index(curLine!.startPosition!, offsetBy: 1) == curLine!.endPosition
            var curType = curLine!.type
            if isEmptyLine {
                curType = .paragraph
            }
            let nextLine: MarkdownTag? = hasNextLine ? scanLine(markdownText, position: curLine!.endPosition!, maxLength: maxLength, sectionType: curType) : nil
            
            // Insert section tag
            if curLine!.startText != nil {
                addStyleTags(&foundTags, markdownText: markdownText, sectionTag: &curLine!)
            } else if !isEmptyLine {
                let spacedLineTag = MarkdownTag()
                spacedLineTag.type = curLine!.type
                spacedLineTag.startPosition = curLine!.startPosition
                spacedLineTag.endPosition = curLine!.endPosition
                spacedLineTag.startText = curLine!.startPosition
                spacedLineTag.endText = curLine!.startPosition
                spacedLineTag.weight = curLine!.weight
                spacedLineTag.flags = curLine!.flags
                foundTags.append(spacedLineTag)
            }
            
            // Insert paragraphs when needed
            if nextLine != nil {
                let startNewParagraph = curLine!.type == .header || nextLine!.type == .header || markdownText.index(nextLine!.startPosition!, offsetBy: 1) == nextLine!.endPosition
                let stopParagraph = markdownText.index(nextLine!.startPosition!, offsetBy: 1) != nextLine!.endPosition
                if startNewParagraph && foundTags.count > 0 && paragraphStartPos == nil {
                    paragraphStartPos = curLine!.endPosition
                }
                if stopParagraph && paragraphStartPos != nil {
                    let paragraphTag = MarkdownTag()
                    paragraphTag.type = .paragraph
                    paragraphTag.startPosition = paragraphStartPos
                    paragraphTag.endPosition = nextLine!.startPosition
                    paragraphTag.startText = paragraphStartPos
                    paragraphTag.endText = paragraphStartPos
                    paragraphTag.weight = nextLine!.type == .header ? 2 : 1
                    foundTags.append(paragraphTag)
                    paragraphStartPos = nil
                }
            }
            
            //Set pointer to next line and continue
            curLine = nextLine
        }
        return foundTags
    }
    
    
    // --
    // MARK: Extracting text
    // --
    
    open func extractText(_ markdownText: String, tag: MarkdownTag) -> String {
        if (tag.flags & MarkdownTag.FLAG_ESCAPED) > 0 {
            return escapedSubstring(markdownText, startPosition: tag.startText!, endPosition: tag.endText!)
        }
        return markdownText.substring(with: tag.startText!..<tag.endText!)
    }
    
    open func extractTextBetween(_ markdownText: String, startTag: MarkdownTag, endTag: MarkdownTag, mode: ExtractBetweenMode) -> String {
        var startPos = markdownText.startIndex
        var endPos = markdownText.startIndex
        switch mode {
        case .startToNext:
            startPos = startTag.startText!
            endPos = endTag.startPosition!
            break
        case .intermediateToNext:
            startPos = startTag.endPosition!
            endPos = endTag.startPosition!
            break
        case .intermediateToEnd:
            startPos = startTag.endPosition!
            endPos = endTag.endText!
            break
        }
        if startPos >= endPos {
            return ""
        }
        if (startTag.flags & MarkdownTag.FLAG_ESCAPED) > 0 {
            return escapedSubstring(markdownText, startPosition: startPos, endPosition: endPos)
        }
        return markdownText.substring(with: startPos..<endPos)
    }
    
    open func extractFull(_ markdownText: String, tag: MarkdownTag) -> String {
        if (tag.flags & MarkdownTag.FLAG_ESCAPED) > 0 {
            return escapedSubstring(markdownText, startPosition: tag.startPosition!, endPosition: tag.endPosition!)
        }
        return markdownText.substring(with: tag.startPosition!..<tag.endPosition!)
    }
    
    open func extractFullBetween(_ markdownText: String, startTag: MarkdownTag, endTag: MarkdownTag, mode: ExtractBetweenMode) -> String {
        var startPos = markdownText.startIndex
        var endPos = markdownText.startIndex
        switch mode {
        case .startToNext:
            startPos = startTag.startPosition!
            endPos = endTag.startPosition!
            break
        case .intermediateToNext:
            startPos = startTag.endPosition!
            endPos = endTag.startPosition!
            break
        case .intermediateToEnd:
            startPos = startTag.endPosition!
            endPos = endTag.endPosition!
            break
        }
        if startPos >= endPos {
            return ""
        }
        if (startTag.flags & MarkdownTag.FLAG_ESCAPED) > 0 {
            return escapedSubstring(markdownText, startPosition: startPos, endPosition: endPos)
        }
        return markdownText.substring(with: startPos..<endPos)
    }
    
    open func extractExtra(_ markdownText: String, tag: MarkdownTag) -> String {
        if tag.startExtra == nil || tag.endExtra == nil || tag.endExtra! <= tag.startExtra! {
            return ""
        }
        if (tag.flags & MarkdownTag.FLAG_ESCAPED) > 0 {
            return escapedSubstring(markdownText, startPosition: tag.startExtra!, endPosition: tag.endExtra!)
        }
        return markdownText.substring(with: tag.startExtra!..<tag.endExtra!)
    }
    
    fileprivate func escapedSubstring(_ text: String, startPosition: String.Index, endPosition: String.Index) -> String {
        var filteredText = ""
        for i in text.characters.indices[startPosition..<endPosition] {
            let chr = text.characters[i]
            if chr == "\\" && text.characters[text.index(i, offsetBy: 1)] != "\n" {
                continue
            }
            filteredText.append(chr)
        }
        return filteredText
    }
    

    // --
    // MARK: Markdown line scanning
    // --
    
    fileprivate func scanLine(_ markdownText: String, position: String.Index, maxLength: String.Index, sectionType: MarkdownTagType) -> MarkdownTag? {
        if position >= maxLength {
            return nil
        }
        let styledTag = MarkdownTag()
        let normalTag = MarkdownTag()
        var skipChars = 0
        var chr: Character = "\0", nextChr = markdownText.characters[position], secondNextChr: Character = "\0"
        var styleTagDefined = false, escaped = false
        var headerTokenSequence = false
        if markdownText.distance(from: position, to: maxLength) > 1 {
            secondNextChr = markdownText.characters[markdownText.index(position, offsetBy: 1)]
        }
        normalTag.startPosition = position
        styledTag.startPosition = position
        for i in markdownText.characters.indices[position..<maxLength] {
            chr = nextChr
            nextChr = secondNextChr
            if markdownText.distance(from: i, to: maxLength) > 2 {
                secondNextChr = markdownText.characters[markdownText.index(i, offsetBy: 2)]
            }
            if skipChars > 0 {
                skipChars -= 1
                continue
            }
            if !escaped && chr == "\\" {
                normalTag.flags = normalTag.flags | MarkdownTag.FLAG_ESCAPED
                styledTag.flags = styledTag.flags | MarkdownTag.FLAG_ESCAPED
                escaped = true
                continue
            }
            if escaped {
                if chr != "\n" {
                    if normalTag.startText == nil {
                        normalTag.startText = i
                    }
                    if styledTag.startText == nil {
                        styledTag.startText = i
                    }
                }
                normalTag.endText = markdownText.index(i, offsetBy: 1)
                styledTag.endText = markdownText.index(i, offsetBy: 1)
            } else {
                if chr == "\n" {
                    normalTag.endPosition = markdownText.index(i, offsetBy: 1)
                    styledTag.endPosition = markdownText.index(i, offsetBy: 1)
                    break
                }
                if chr != " " {
                    if normalTag.startText == nil {
                        normalTag.startText = i
                    }
                    normalTag.endText = markdownText.index(i, offsetBy: 1)
                }
                if !styleTagDefined {
                    let allowNewParagraph = sectionType == .paragraph || sectionType == .header
                    let continueBulletList = sectionType == .unorderedList || sectionType == .orderedList
                    if chr == "#" {
                        styledTag.type = .header
                        styledTag.weight = 1
                        styleTagDefined = true
                        headerTokenSequence = true
                    } else if (allowNewParagraph || continueBulletList) && (chr == "*" || chr == "-" || chr == "+") && nextChr == " " && markdownText.distance(from: position, to: i) % 2 == 0 {
                        styledTag.type = .unorderedList
                        styledTag.weight = 1 + markdownText.distance(from: position, to: i) / 2
                        styleTagDefined = true
                        skipChars = 1
                    } else if (allowNewParagraph || continueBulletList) && chr >= "0" && chr <= "9" && nextChr == "." && secondNextChr == " " && markdownText.distance(from: position, to: i) % 2 == 0 {
                        styledTag.type = .orderedList
                        styledTag.weight = 1 + markdownText.distance(from: position, to: i) / 2
                        styleTagDefined = true
                        skipChars = 2
                    } else if chr != " " {
                        styledTag.type = .normal
                        styleTagDefined = true
                    }
                } else if styledTag.type != .normal {
                    if styledTag.type == .header {
                        if chr == "#" && headerTokenSequence {
                            styledTag.weight += 1
                        } else {
                            headerTokenSequence = false
                        }
                        if chr != "#" && chr != " " && styledTag.startText == nil {
                            styledTag.startText = i
                            styledTag.endText = markdownText.index(i, offsetBy: 1)
                        } else if (chr != "#" || (nextChr != "#" && nextChr != "\n" && nextChr != " " && nextChr != "\0")) && chr != " " && styledTag.startText != nil {
                            styledTag.endText = markdownText.index(i, offsetBy: 1)
                        }
                    } else {
                        if chr != " " {
                            if styledTag.startText == nil {
                                styledTag.startText = i
                            }
                            styledTag.endText = markdownText.index(i, offsetBy: 1)
                        }
                    }
                }
            }
            escaped = false
        }
        if styleTagDefined && styledTag.type != .normal && styledTag.startText != nil && styledTag.endText! > styledTag.startText! {
            if styledTag.endPosition == nil {
                styledTag.endPosition = maxLength
            }
            return styledTag
        }
        if normalTag.endPosition == nil {
            normalTag.endPosition = maxLength
        }
        normalTag.type = .normal
        return normalTag
    }


    // --
    // MARK: Markdown style tag scanning
    // --

    fileprivate func addStyleTags(_ foundTags: inout [MarkdownTag], markdownText: String, sectionTag: inout MarkdownTag) {
        // First add the main section tag
        let mainTag = MarkdownTag()
        mainTag.type = sectionTag.type
        mainTag.startPosition = sectionTag.startPosition
        mainTag.endPosition = sectionTag.endPosition
        mainTag.startText = sectionTag.startText
        mainTag.endText = sectionTag.endText
        mainTag.weight = sectionTag.weight
        mainTag.flags = sectionTag.flags
        foundTags.append(mainTag)
        
        //Traverse string and find tag markers
        var tagMarkers: [MarkdownMarker] = []
        var addTags: [MarkdownTag] = []
        let maxLength = sectionTag.endText!
        var curMarkerWeight = 0
        var curMarkerChar: Character = "\0"
        var skipCharacters = 0
        for i in markdownText.characters.indices[sectionTag.startText!..<maxLength] {
            if skipCharacters > 0 {
                skipCharacters -= 1
                continue
            }
            let chr = markdownText.characters[i]
            if curMarkerChar != "\0" {
                if chr == curMarkerChar {
                    curMarkerWeight += 1
                } else {
                    tagMarkers.append(MarkdownMarker(chr: curMarkerChar, weight: curMarkerWeight, position: markdownText.index(i, offsetBy: -curMarkerWeight)))
                    curMarkerChar = "\0"
                }
            }
            if curMarkerChar == "\0" {
                if chr == "*" || chr == "_" || chr == "~" {
                    curMarkerChar = chr
                    curMarkerWeight = 1
                } else if chr == "[" || chr == "]" || chr == "(" || chr == ")" {
                    tagMarkers.append(MarkdownMarker(chr: chr, weight: 1, position: i))
                }
            }
            if chr == "\\" {
                skipCharacters += 1
            }
        }
        if curMarkerChar != "\0" {
            tagMarkers.append(MarkdownMarker(chr: curMarkerChar, weight: curMarkerWeight, position: markdownText.index(maxLength, offsetBy: -curMarkerWeight)))
        }
        
        //Sort tags to add and finally add them
        processMarkers(markdownText: markdownText, addTags: &addTags, markers: &tagMarkers, start: 0, end: tagMarkers.count, addFlags: sectionTag.flags)
        addTags.sort(by: { (lhs, rhs) -> Bool in
            let diff = lhs.startPosition! < rhs.startPosition! ? markdownText.distance(from: lhs.startPosition!, to: rhs.startPosition!) : -markdownText.distance(from: rhs.startPosition!, to: lhs.startPosition!)
            return diff > 0
        })
        foundTags.append(contentsOf: addTags)
    }
    

    // --
    // MARK: Markdown marker conversion (resursive)
    // --
    
    fileprivate func processMarkers(markdownText: String, addTags: inout [MarkdownTag], markers: inout [MarkdownMarker], start: Int, end: Int, addFlags: Int) {
        var adjustedStart = start
        var processing = true
        while processing && adjustedStart < end {
            let marker = markers[adjustedStart]
            processing = false
            if marker.chr == "[" || marker.chr == "]" || marker.chr == "(" || marker.chr == ")" {
                if marker.chr == "[" {
                    var linkTag: MarkdownTag? = nil
                    var extraMarker: MarkdownMarker? = nil
                    for i in adjustedStart + 1..<end {
                        let checkMarker = markers[i]
                        if (checkMarker.chr == "]" && linkTag == nil) || (checkMarker.chr == ")" && linkTag != nil) {
                            if linkTag == nil {
                                linkTag = MarkdownTag()
                                linkTag!.type = .link
                                linkTag!.startPosition = marker.position
                                linkTag!.endPosition = markdownText.index(checkMarker.position, offsetBy: checkMarker.weight)
                                linkTag!.startText = markdownText.index(linkTag!.startPosition!, offsetBy: marker.weight)
                                linkTag!.endText = checkMarker.position
                                linkTag!.flags = addFlags
                                addTags.append(linkTag!)
                                adjustedStart = i + 1
                                if adjustedStart < end {
                                    extraMarker = markers[adjustedStart]
                                    if extraMarker!.chr != "(" || extraMarker!.position != markdownText.index(checkMarker.position, offsetBy: checkMarker.weight) {
                                        processing = true
                                        break
                                    }
                                }
                            } else if extraMarker != nil {
                                linkTag!.startExtra = markdownText.index(extraMarker!.position, offsetBy: extraMarker!.weight)
                                linkTag!.endExtra = checkMarker.position
                                linkTag!.endPosition = markdownText.index(checkMarker.position, offsetBy: checkMarker.weight)
                                adjustedStart = i + 1
                                processing = true
                                break
                            }
                        }
                    }
                }
            } else {
                for i in adjustedStart + 1..<end {
                    let checkMarker = markers[i]
                    if checkMarker.chr == marker.chr && checkMarker.weight >= marker.weight {
                        let tag = MarkdownTag()
                        tag.type = checkMarker.chr == "~" ? .alternativeTextStyle : .textStyle
                        tag.weight = marker.weight
                        tag.startPosition = marker.position
                        tag.endPosition = markdownText.index(checkMarker.position, offsetBy: marker.weight)
                        tag.startText = markdownText.index(tag.startPosition!, offsetBy: marker.weight)
                        tag.endText = checkMarker.position
                        tag.flags = addFlags
                        addTags.append(tag)
                        processMarkers(markdownText: markdownText, addTags: &addTags, markers: &markers, start: adjustedStart + 1, end: i, addFlags: addFlags)
                        if checkMarker.weight > marker.weight {
                            checkMarker.weight -= marker.weight
                            adjustedStart = i
                        } else {
                            adjustedStart = i + 1
                        }
                        processing = true
                        break
                    }
                }
            }
            if !processing {
                if marker.weight > 1 {
                    marker.weight -= 1
                    processing = true
                } else {
                    adjustedStart += 1
                }
            }
        }
    }

}

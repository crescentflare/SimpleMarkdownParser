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
    
    private init(chr: Character, weight: Int, position: String.Index) {
        self.chr = chr
        self.weight = weight
        self.position = position
    }
}

// Parser class
public class SimpleMarkdownParserSwift : SimpleMarkdownParser {
    
    // --
    // MARK: Default initializer
    // --

    public init() {
    }

    
    // --
    // MARK: Finding tags
    // --
    
    public func findTags(markdownText: String) -> [MarkdownTag] {
        var foundTags: [MarkdownTag] = []
        let maxLength = markdownText.endIndex
        var paragraphStartPos: String.Index? = nil
        var curLine: MarkdownTag? = scanLine(markdownText, position: markdownText.startIndex, maxLength: maxLength, sectionType: .Paragraph)
        while curLine != nil {
            // Fetch next line ahead
            let hasNextLine = curLine!.endPosition < maxLength
            let isEmptyLine = curLine!.startPosition?.advancedBy(1) == curLine!.endPosition
            var curType = curLine!.type
            if isEmptyLine {
                curType = .Paragraph
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
                let startNewParagraph = curLine!.type == .Header || nextLine!.type == .Header || nextLine!.startPosition!.advancedBy(1) == nextLine!.endPosition
                let stopParagraph = nextLine!.startPosition!.advancedBy(1) != nextLine!.endPosition
                if startNewParagraph && foundTags.count > 0 && paragraphStartPos == nil {
                    paragraphStartPos = curLine!.endPosition
                }
                if stopParagraph && paragraphStartPos != nil {
                    let paragraphTag = MarkdownTag()
                    paragraphTag.type = .Paragraph
                    paragraphTag.startPosition = paragraphStartPos
                    paragraphTag.endPosition = nextLine!.startPosition
                    paragraphTag.startText = paragraphStartPos
                    paragraphTag.endText = paragraphStartPos
                    paragraphTag.weight = nextLine!.type == .Header ? 2 : 1
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
    
    public func extractText(markdownText: String, tag: MarkdownTag) -> String {
        if (tag.flags & MarkdownTag.FLAG_ESCAPED) > 0 {
            return escapedSubstring(markdownText, startPosition: tag.startText!, endPosition: tag.endText!)
        }
        return markdownText.substringWithRange(tag.startText!..<tag.endText!)
    }
    
    public func extractTextBetween(markdownText: String, startTag: MarkdownTag, endTag: MarkdownTag, mode: ExtractBetweenMode) -> String {
        var startPos = markdownText.startIndex
        var endPos = markdownText.startIndex
        switch mode {
        case .StartToNext:
            startPos = startTag.startText!
            endPos = endTag.startPosition!
            break
        case .IntermediateToNext:
            startPos = startTag.endPosition!
            endPos = endTag.startPosition!
            break
        case .IntermediateToEnd:
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
        return markdownText.substringWithRange(startPos..<endPos)
    }
    
    public func extractFull(markdownText: String, tag: MarkdownTag) -> String {
        if (tag.flags & MarkdownTag.FLAG_ESCAPED) > 0 {
            return escapedSubstring(markdownText, startPosition: tag.startPosition!, endPosition: tag.endPosition!)
        }
        return markdownText.substringWithRange(tag.startPosition!..<tag.endPosition!)
    }
    
    public func extractFullBetween(markdownText: String, startTag: MarkdownTag, endTag: MarkdownTag, mode: ExtractBetweenMode) -> String {
        var startPos = markdownText.startIndex
        var endPos = markdownText.startIndex
        switch mode {
        case .StartToNext:
            startPos = startTag.startPosition!
            endPos = endTag.startPosition!
            break
        case .IntermediateToNext:
            startPos = startTag.endPosition!
            endPos = endTag.startPosition!
            break
        case .IntermediateToEnd:
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
        return markdownText.substringWithRange(startPos..<endPos)
    }
    
    public func extractExtra(markdownText: String, tag: MarkdownTag) -> String {
        if tag.startExtra == nil || tag.endExtra == nil || tag.endExtra <= tag.startExtra {
            return ""
        }
        if (tag.flags & MarkdownTag.FLAG_ESCAPED) > 0 {
            return escapedSubstring(markdownText, startPosition: tag.startExtra!, endPosition: tag.endExtra!)
        }
        return markdownText.substringWithRange(tag.startExtra!..<tag.endExtra!)
    }
    
    private func escapedSubstring(text: String, startPosition: String.Index, endPosition: String.Index) -> String {
        var filteredText = ""
        for i in startPosition..<endPosition {
            let chr = text.characters[i]
            if chr == "\\" && text.characters[i.advancedBy(1)] != "\n" {
                continue
            }
            filteredText.append(chr)
        }
        return filteredText
    }
    

    // --
    // MARK: Markdown line scanning
    // --
    
    private func scanLine(markdownText: String, position: String.Index, maxLength: String.Index, sectionType: MarkdownTagType) -> MarkdownTag {
        let styledTag = MarkdownTag()
        let normalTag = MarkdownTag()
        var skipChars = 0
        var chr: Character = "\0", nextChr = markdownText.characters[position], secondNextChr: Character = "\0"
        var styleTagDefined = false, escaped = false
        var headerTokenSequence = false
        if position.distanceTo(maxLength) > 1 {
            secondNextChr = markdownText.characters[position.advancedBy(1)]
        }
        normalTag.startPosition = position
        styledTag.startPosition = position
        for i in position..<maxLength {
            chr = nextChr
            nextChr = secondNextChr
            if i.distanceTo(maxLength) > 2 {
                secondNextChr = markdownText.characters[i.advancedBy(2)]
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
                normalTag.endText = i.advancedBy(1)
                styledTag.endText = i.advancedBy(1)
            } else {
                if chr == "\n" {
                    normalTag.endPosition = i.advancedBy(1)
                    styledTag.endPosition = i.advancedBy(1)
                    break
                }
                if chr != " " {
                    if normalTag.startText == nil {
                        normalTag.startText = i
                    }
                    normalTag.endText = i.advancedBy(1)
                }
                if !styleTagDefined {
                    let allowNewParagraph = sectionType == .Paragraph || sectionType == .Header
                    let continueBulletList = sectionType == .UnorderedList || sectionType == .OrderedList
                    if chr == "#" {
                        styledTag.type = .Header
                        styledTag.weight = 1
                        styleTagDefined = true
                        headerTokenSequence = true
                    } else if (allowNewParagraph || continueBulletList) && (chr == "*" || chr == "-" || chr == "+") && nextChr == " " && position.distanceTo(i) % 2 == 0 {
                        styledTag.type = .UnorderedList
                        styledTag.weight = 1 + position.distanceTo(i) / 2
                        styleTagDefined = true
                        skipChars = 1
                    } else if (allowNewParagraph || continueBulletList) && chr >= "0" && chr <= "9" && nextChr == "." && secondNextChr == " " && position.distanceTo(i) % 2 == 0 {
                        styledTag.type = .OrderedList
                        styledTag.weight = 1 + position.distanceTo(i) / 2
                        styleTagDefined = true
                        skipChars = 2
                    } else if chr != " " {
                        styledTag.type = .Normal
                        styleTagDefined = true
                    }
                } else if styledTag.type != .Normal {
                    if styledTag.type == .Header {
                        if chr == "#" && headerTokenSequence {
                            styledTag.weight += 1
                        } else {
                            headerTokenSequence = false
                        }
                        if chr != "#" && chr != " " && styledTag.startText == nil {
                            styledTag.startText = i
                            styledTag.endText = i.advancedBy(1)
                        } else if (chr != "#" || (nextChr != "#" && nextChr != "\n" && nextChr != " " && nextChr != "\0")) && chr != " " && styledTag.startText != nil {
                            styledTag.endText = i.advancedBy(1)
                        }
                    } else {
                        if chr != " " {
                            if styledTag.startText == nil {
                                styledTag.startText = i
                            }
                            styledTag.endText = i.advancedBy(1)
                        }
                    }
                }
            }
            escaped = false
        }
        if styleTagDefined && styledTag.type != .Normal && styledTag.startText != nil && styledTag.endText > styledTag.startText {
            if styledTag.endPosition == nil {
                styledTag.endPosition = maxLength
            }
            return styledTag
        }
        if normalTag.endPosition == nil {
            normalTag.endPosition = maxLength
        }
        normalTag.type = .Normal
        return normalTag
    }


    // --
    // MARK: Markdown style tag scanning
    // --

    private func addStyleTags(inout foundTags: [MarkdownTag], markdownText: String, inout sectionTag: MarkdownTag) {
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
        for i in sectionTag.startText!..<maxLength {
            if skipCharacters > 0 {
                skipCharacters -= 1
                continue
            }
            let chr = markdownText.characters[i]
            if curMarkerChar != "\0" {
                if chr == curMarkerChar {
                    curMarkerWeight += 1
                } else {
                    tagMarkers.append(MarkdownMarker(chr: curMarkerChar, weight: curMarkerWeight, position: i.advancedBy(-curMarkerWeight)))
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
            tagMarkers.append(MarkdownMarker(chr: curMarkerChar, weight: curMarkerWeight, position: maxLength.advancedBy(-curMarkerWeight)))
        }
        
        //Sort tags to add and finally add them
        processMarkers(&addTags, markers: &tagMarkers, start: 0, end: tagMarkers.count, addFlags: sectionTag.flags)
        addTags.sortInPlace({ (lhs, rhs) -> Bool in
            let diff = lhs.startPosition < rhs.startPosition ? lhs.startPosition!.distanceTo(rhs.startPosition!) : -rhs.startPosition!.distanceTo(lhs.startPosition!)
            return diff > 0
        })
        foundTags.appendContentsOf(addTags)
    }
    

    // --
    // MARK: Markdown marker conversion (resursive)
    // --
    
    private func processMarkers(inout addTags: [MarkdownTag], inout markers: [MarkdownMarker], start: Int, end: Int, addFlags: Int) {
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
                                linkTag!.type = .Link
                                linkTag!.startPosition = marker.position
                                linkTag!.endPosition = checkMarker.position.advancedBy(checkMarker.weight)
                                linkTag!.startText = linkTag!.startPosition!.advancedBy(marker.weight)
                                linkTag!.endText = checkMarker.position
                                linkTag!.flags = addFlags
                                addTags.append(linkTag!)
                                adjustedStart = i + 1
                                if adjustedStart < end {
                                    extraMarker = markers[adjustedStart]
                                    if extraMarker!.chr != "(" || extraMarker!.position != checkMarker.position.advancedBy(checkMarker.weight) {
                                        processing = true
                                        break
                                    }
                                }
                            } else if extraMarker != nil {
                                linkTag!.startExtra = extraMarker!.position.advancedBy(extraMarker!.weight)
                                linkTag!.endExtra = checkMarker.position
                                linkTag!.endPosition = checkMarker.position.advancedBy(checkMarker.weight)
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
                        tag.type = checkMarker.chr == "~" ? .AlternativeTextStyle : .TextStyle
                        tag.weight = marker.weight
                        tag.startPosition = marker.position
                        tag.endPosition = checkMarker.position.advancedBy(marker.weight)
                        tag.startText = tag.startPosition?.advancedBy(marker.weight)
                        tag.endText = checkMarker.position
                        tag.flags = addFlags
                        addTags.append(tag)
                        processMarkers(&addTags, markers: &markers, start: adjustedStart + 1, end: i, addFlags: addFlags)
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

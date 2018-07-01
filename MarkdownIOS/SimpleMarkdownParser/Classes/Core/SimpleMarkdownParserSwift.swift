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
    let position: Int
    
    fileprivate init(chr: Character, weight: Int, position: Int) {
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
    
    public func findTags(onMarkdownText: String) -> [MarkdownTag] {
        // Scan for markdown tags
        var foundTags: [MarkdownTag] = []
        let markdownArray = ArraySlice(onMarkdownText)
        let maxLength = markdownArray.count
        var paragraphStartPos: Int? = nil
        var curLine: MarkdownTag? = scanLine(onMarkdownTextArray: markdownArray, position: 0, maxLength: maxLength, sectionType: .paragraph)
        while curLine != nil {
            // Fetch next line ahead
            let hasNextLine = curLine!.endPosition! < maxLength
            let isEmptyLine = curLine!.startPosition! + 1 == curLine!.endPosition
            var curType = curLine!.type
            if isEmptyLine {
                curType = .paragraph
            }
            let nextLine: MarkdownTag? = hasNextLine ? scanLine(onMarkdownTextArray: markdownArray, position: curLine!.endPosition!, maxLength: maxLength, sectionType: curType) : nil
            
            // Insert section tag
            if curLine!.startTextPosition != nil {
                addStyleTags(foundTags: &foundTags, markdownTextArray: markdownArray, sectionTag: &curLine!)
            } else if !isEmptyLine {
                let spacedLineTag = MarkdownTag()
                spacedLineTag.type = curLine!.type
                spacedLineTag.startPosition = curLine!.startPosition
                spacedLineTag.endPosition = curLine!.endPosition
                spacedLineTag.startTextPosition = curLine!.startPosition
                spacedLineTag.endTextPosition = curLine!.startPosition
                spacedLineTag.weight = curLine!.weight
                spacedLineTag.flags = curLine!.flags
                foundTags.append(spacedLineTag)
            }
            
            // Insert paragraphs when needed
            if nextLine != nil {
                let startNewParagraph = curLine!.type == .header || nextLine!.type == .header || nextLine!.startPosition! + 1 == nextLine!.endPosition
                let stopParagraph = nextLine!.startPosition! + 1 != nextLine!.endPosition
                if startNewParagraph && foundTags.count > 0 && paragraphStartPos == nil {
                    paragraphStartPos = curLine!.endPosition
                }
                if stopParagraph && paragraphStartPos != nil {
                    let paragraphTag = MarkdownTag()
                    paragraphTag.type = .paragraph
                    paragraphTag.startPosition = paragraphStartPos
                    paragraphTag.endPosition = nextLine!.startPosition
                    paragraphTag.startTextPosition = paragraphStartPos
                    paragraphTag.endTextPosition = paragraphStartPos
                    paragraphTag.weight = nextLine!.type == .header ? 2 : 1
                    foundTags.append(paragraphTag)
                    paragraphStartPos = nil
                }
            }
            
            //Set pointer to next line and continue
            curLine = nextLine
        }
        
        // Convert positions within found tags to indices and return result
        for foundTag in foundTags {
            if let startPosition = foundTag.startPosition {
                foundTag.startIndex = onMarkdownText.index(onMarkdownText.startIndex, offsetBy: startPosition)
            }
            if let endPosition = foundTag.endPosition {
                foundTag.endIndex = onMarkdownText.index(onMarkdownText.startIndex, offsetBy: endPosition)
            }
            if let startTextPosition = foundTag.startTextPosition {
                foundTag.startTextIndex = onMarkdownText.index(onMarkdownText.startIndex, offsetBy: startTextPosition)
            }
            if let endTextPosition = foundTag.endTextPosition {
                foundTag.endTextIndex = onMarkdownText.index(onMarkdownText.startIndex, offsetBy: endTextPosition)
            }
            if let startExtraPosition = foundTag.startExtraPosition {
                foundTag.startExtraIndex = onMarkdownText.index(onMarkdownText.startIndex, offsetBy: startExtraPosition)
            }
            if let endExtraPosition = foundTag.endExtraPosition {
                foundTag.endExtraIndex = onMarkdownText.index(onMarkdownText.startIndex, offsetBy: endExtraPosition)
            }
        }
        return foundTags
    }
    
    
    // --
    // MARK: Extracting text
    // --
    
    public func extract(textFromMarkdownText: String, tag: MarkdownTag) -> String {
        if (tag.flags & MarkdownTag.FLAG_ESCAPED) > 0 {
            return escapedSubstring(fromText: textFromMarkdownText, startPosition: tag.startTextIndex!, endPosition: tag.endTextIndex!)
        }
        return String(textFromMarkdownText[tag.startTextIndex!..<tag.endTextIndex!])
    }
    
    public func extract(textBetweenMarkdownText: String, startTag: MarkdownTag, endTag: MarkdownTag, mode: ExtractBetweenMode) -> String {
        var startPos = textBetweenMarkdownText.startIndex
        var endPos = textBetweenMarkdownText.startIndex
        switch mode {
        case .startToNext:
            startPos = startTag.startTextIndex!
            endPos = endTag.startIndex!
            break
        case .intermediateToNext:
            startPos = startTag.endIndex!
            endPos = endTag.startIndex!
            break
        case .intermediateToEnd:
            startPos = startTag.endIndex!
            endPos = endTag.endTextIndex!
            break
        }
        if startPos >= endPos {
            return ""
        }
        if (startTag.flags & MarkdownTag.FLAG_ESCAPED) > 0 {
            return escapedSubstring(fromText: textBetweenMarkdownText, startPosition: startPos, endPosition: endPos)
        }
        return String(textBetweenMarkdownText[startPos..<endPos])
    }
    
    public func extract(fullFromMarkdownText: String, tag: MarkdownTag) -> String {
        if (tag.flags & MarkdownTag.FLAG_ESCAPED) > 0 {
            return escapedSubstring(fromText: fullFromMarkdownText, startPosition: tag.startIndex!, endPosition: tag.endIndex!)
        }
        return String(fullFromMarkdownText[tag.startIndex!..<tag.endIndex!])
    }
    
    public func extract(fullBetweenMarkdownText: String, startTag: MarkdownTag, endTag: MarkdownTag, mode: ExtractBetweenMode) -> String {
        var startPos = fullBetweenMarkdownText.startIndex
        var endPos = fullBetweenMarkdownText.startIndex
        switch mode {
        case .startToNext:
            startPos = startTag.startIndex!
            endPos = endTag.startIndex!
            break
        case .intermediateToNext:
            startPos = startTag.endIndex!
            endPos = endTag.startIndex!
            break
        case .intermediateToEnd:
            startPos = startTag.endIndex!
            endPos = endTag.endIndex!
            break
        }
        if startPos >= endPos {
            return ""
        }
        if (startTag.flags & MarkdownTag.FLAG_ESCAPED) > 0 {
            return escapedSubstring(fromText: fullBetweenMarkdownText, startPosition: startPos, endPosition: endPos)
        }
        return String(fullBetweenMarkdownText[startPos..<endPos])
    }
    
    public func extract(extraFromMarkdownText: String, tag: MarkdownTag) -> String {
        if tag.startExtraIndex == nil || tag.endExtraIndex == nil || tag.endExtraIndex! <= tag.startExtraIndex! {
            return ""
        }
        if (tag.flags & MarkdownTag.FLAG_ESCAPED) > 0 {
            return escapedSubstring(fromText: extraFromMarkdownText, startPosition: tag.startExtraIndex!, endPosition: tag.endExtraIndex!)
        }
        return String(extraFromMarkdownText[tag.startExtraIndex!..<tag.endExtraIndex!])
    }
    
    private func escapedSubstring(fromText: String, startPosition: String.Index, endPosition: String.Index) -> String {
        var filteredText = ""
        for i in fromText.indices[startPosition..<endPosition] {
            let chr = fromText[i]
            if chr == "\\" && fromText[fromText.index(i, offsetBy: 1)] != "\n" {
                continue
            }
            filteredText.append(chr)
        }
        return filteredText
    }
    

    // --
    // MARK: Markdown line scanning
    // --
    
    private func scanLine(onMarkdownTextArray: ArraySlice<Character>, position: Int, maxLength: Int, sectionType: MarkdownTagType) -> MarkdownTag? {
        if position >= maxLength {
            return nil
        }
        let styledTag = MarkdownTag()
        let normalTag = MarkdownTag()
        var skipChars = 0
        var chr: Character = "\0", nextChr = onMarkdownTextArray[position], secondNextChr: Character = "\0"
        var styleTagDefined = false, escaped = false
        var headerTokenSequence = false
        if position + 1 < maxLength {
            secondNextChr = onMarkdownTextArray[position + 1]
        }
        normalTag.startPosition = position
        styledTag.startPosition = position
        for i in position..<maxLength {
            chr = nextChr
            nextChr = secondNextChr
            if i + 2 < maxLength {
                secondNextChr = onMarkdownTextArray[i + 2]
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
                    if normalTag.startTextPosition == nil {
                        normalTag.startTextPosition = i
                    }
                    if styledTag.startTextPosition == nil {
                        styledTag.startTextPosition = i
                    }
                }
                normalTag.endTextPosition = i + 1
                styledTag.endTextPosition = i + 1
            } else {
                if chr == "\n" {
                    normalTag.endPosition = i + 1
                    styledTag.endPosition = i + 1
                    break
                }
                if chr != " " {
                    if normalTag.startTextPosition == nil {
                        normalTag.startTextPosition = i
                    }
                    normalTag.endTextPosition = i + 1
                }
                if !styleTagDefined {
                    let allowNewParagraph = sectionType == .paragraph || sectionType == .header
                    let continueBulletList = sectionType == .unorderedList || sectionType == .orderedList
                    if chr == "#" {
                        styledTag.type = .header
                        styledTag.weight = 1
                        styleTagDefined = true
                        headerTokenSequence = true
                    } else if (allowNewParagraph || continueBulletList) && (chr == "*" || chr == "-" || chr == "+") && nextChr == " " && (i - position) % 2 == 0 {
                        styledTag.type = .unorderedList
                        styledTag.weight = 1 + (i - position) / 2
                        styleTagDefined = true
                        skipChars = 1
                    } else if (allowNewParagraph || continueBulletList) && chr >= "0" && chr <= "9" && nextChr == "." && secondNextChr == " " && (i - position) % 2 == 0 {
                        styledTag.type = .orderedList
                        styledTag.weight = 1 + (i - position) / 2
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
                        if chr != "#" && chr != " " && styledTag.startTextPosition == nil {
                            styledTag.startTextPosition = i
                            styledTag.endTextPosition = i + 1
                        } else if (chr != "#" || (nextChr != "#" && nextChr != "\n" && nextChr != " " && nextChr != "\0")) && chr != " " && styledTag.startTextPosition != nil {
                            styledTag.endTextPosition = i + 1
                        }
                    } else {
                        if chr != " " {
                            if styledTag.startTextPosition == nil {
                                styledTag.startTextPosition = i
                            }
                            styledTag.endTextPosition = i + 1
                        }
                    }
                }
            }
            escaped = false
        }
        if styleTagDefined && styledTag.type != .normal && styledTag.startTextPosition != nil && styledTag.endTextPosition! > styledTag.startTextPosition! {
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

    private func addStyleTags(foundTags: inout [MarkdownTag], markdownTextArray: ArraySlice<Character>, sectionTag: inout MarkdownTag) {
        // First add the main section tag
        let mainTag = MarkdownTag()
        mainTag.type = sectionTag.type
        mainTag.startPosition = sectionTag.startPosition
        mainTag.endPosition = sectionTag.endPosition
        mainTag.startTextPosition = sectionTag.startTextPosition
        mainTag.endTextPosition = sectionTag.endTextPosition
        mainTag.weight = sectionTag.weight
        mainTag.flags = sectionTag.flags
        foundTags.append(mainTag)
        
        //Traverse string and find tag markers
        var tagMarkers: [MarkdownMarker] = []
        var addTags: [MarkdownTag] = []
        let maxLength = sectionTag.endTextPosition!
        var curMarkerWeight = 0
        var curMarkerChar: Character = "\0"
        var skipCharacters = 0
        for i in sectionTag.startTextPosition!..<maxLength {
            if skipCharacters > 0 {
                skipCharacters -= 1
                continue
            }
            let chr = markdownTextArray[i]
            if curMarkerChar != "\0" {
                if chr == curMarkerChar {
                    curMarkerWeight += 1
                } else {
                    tagMarkers.append(MarkdownMarker(chr: curMarkerChar, weight: curMarkerWeight, position: i - curMarkerWeight))
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
            tagMarkers.append(MarkdownMarker(chr: curMarkerChar, weight: curMarkerWeight, position: maxLength - curMarkerWeight))
        }
        
        //Sort tags to add and finally add them
        processMarkers(onMarkdownTextArray: markdownTextArray, addTags: &addTags, markers: &tagMarkers, start: 0, end: tagMarkers.count, addFlags: sectionTag.flags)
        addTags.sort(by: { (lhs, rhs) -> Bool in
            return rhs.startPosition! - lhs.startPosition! > 0
        })
        foundTags.append(contentsOf: addTags)
    }
    

    // --
    // MARK: Markdown marker conversion (resursive)
    // --
    
    private func processMarkers(onMarkdownTextArray: ArraySlice<Character>, addTags: inout [MarkdownTag], markers: inout [MarkdownMarker], start: Int, end: Int, addFlags: Int) {
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
                                linkTag!.endPosition = checkMarker.position + checkMarker.weight
                                linkTag!.startTextPosition = linkTag!.startPosition! + marker.weight
                                linkTag!.endTextPosition = checkMarker.position
                                linkTag!.flags = addFlags
                                addTags.append(linkTag!)
                                adjustedStart = i + 1
                                if adjustedStart < end {
                                    extraMarker = markers[adjustedStart]
                                    if extraMarker!.chr != "(" || extraMarker!.position != checkMarker.position + checkMarker.weight {
                                        processing = true
                                        break
                                    }
                                }
                            } else if extraMarker != nil {
                                linkTag!.startExtraPosition = extraMarker!.position + extraMarker!.weight
                                linkTag!.endExtraPosition = checkMarker.position
                                linkTag!.endPosition = checkMarker.position + checkMarker.weight
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
                        tag.endPosition = checkMarker.position + marker.weight
                        tag.startTextPosition = tag.startPosition! + marker.weight
                        tag.endTextPosition = checkMarker.position
                        tag.flags = addFlags
                        addTags.append(tag)
                        processMarkers(onMarkdownTextArray: onMarkdownTextArray, addTags: &addTags, markers: &markers, start: adjustedStart + 1, end: i, addFlags: addFlags)
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

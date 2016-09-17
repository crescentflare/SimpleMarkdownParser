//
//  SimpleMarkdownConverter.swift
//  SimpleMarkdownParser Pod
//
//  Conversion library: utility class to convert markdown to HTML or attributed string
//

public let NSClickableTextAttributeName = "NSClickableTextAttributeName"

open class SimpleMarkdownConverter {
    
    // --
    // MARK: HTML conversion handling
    // --
    
    open static func toHtmlString(_ markdownText: String) -> String {
        let parser = obtainParser(markdownText)
        let foundTags = parser.findTags(onMarkdownText: markdownText)
        var htmlString = ""
        var listCount: [Int] = []
        var prevSectionType = MarkdownTagType.paragraph
        var addedParagraph = true
        var skipTags = 0
        for i in 0..<foundTags.count {
            if skipTags > 0 {
                skipTags -= 1
                continue
            }
            let sectionTag = foundTags[i]
            if !addedParagraph && sectionTag.type == .normal {
                htmlString += "<br/>"
            }
            if sectionTag.type == .orderedList || sectionTag.type == .unorderedList {
                let matchedType = sectionTag.type == .orderedList ? 0 : 1
                if listCount.count == sectionTag.weight && listCount.count > 0 && listCount[listCount.count - 1] != matchedType {
                    htmlString += listCount[listCount.count - 1] == 0 ? "</ol>" : "</ul>"
                    listCount.remove(at: listCount.count - 1)
                }
                for _ in listCount.count..<sectionTag.weight {
                    listCount.append(sectionTag.type == .orderedList ? 0 : 1)
                    htmlString += sectionTag.type == .orderedList ? "<ol>" : "<ul>"
                }
                for _ in stride(from: listCount.count, to: sectionTag.weight, by: -1) {
                    htmlString += listCount[listCount.count - 1] == 0 ? "</ol>" : "</ul>"
                    listCount.remove(at: listCount.count - 1)
                }
            }
            if sectionTag.type == .header || sectionTag.type == .orderedList || sectionTag.type == .unorderedList || sectionTag.type == .normal {
                var handledTags: [MarkdownTag] = []
                htmlString += getHtmlTag(parser, markdownText: markdownText, tag: sectionTag, closingTag: false)
                htmlString = appendHtmlString(parser, handledTags: &handledTags, htmlString: htmlString, markdownText: markdownText, foundTags: foundTags, start: i)
                htmlString += getHtmlTag(parser, markdownText: markdownText, tag: sectionTag, closingTag: true)
                skipTags += handledTags.count - 1
                addedParagraph = sectionTag.type != .normal
            } else if sectionTag.type == .paragraph {
                let nextNormal = i + 1 < foundTags.count && foundTags[i + 1].type == .normal
                if prevSectionType == .normal && nextNormal {
                    for _ in 0..<sectionTag.weight + 1 {
                        htmlString += "<br/>"
                    }
                }
                addedParagraph = true
                for _ in stride(from: listCount.count, to: 0, by: -1) {
                    htmlString += listCount[listCount.count - 1] == 0 ? "</ol>" : "</ul>"
                    listCount.remove(at: listCount.count - 1)
                }
            }
            prevSectionType = sectionTag.type
        }
        for _ in stride(from: listCount.count, to: 0, by: -1) {
            htmlString += listCount[listCount.count - 1] == 0 ? "</ol>" : "</ul>"
            listCount.remove(at: listCount.count - 1)
        }
        return htmlString;
    }
    
    fileprivate static func appendHtmlString(_ parser: SimpleMarkdownParser, handledTags: inout [MarkdownTag], htmlString: String, markdownText: String, foundTags: [MarkdownTag], start: Int) -> String {
        var adjustedHtmlString = htmlString
        let curTag = foundTags[start]
        var intermediateTag: MarkdownTag? = nil
        var processingTag: MarkdownTag? = nil
        var checkPosition = start + 1
        var processing = true
        while processing {
            let nextTag: MarkdownTag? = checkPosition < foundTags.count ? foundTags[checkPosition] : nil
            processing = false
            if nextTag != nil && nextTag!.startPosition! < curTag.endPosition! {
                if processingTag == nil {
                    processingTag = MarkdownTag()
                    handledTags.append(processingTag!)
                    processingTag!.type = curTag.type
                    processingTag!.weight = curTag.weight
                    processingTag!.startExtra = curTag.startExtra
                    processingTag!.endExtra = curTag.endExtra
                    processingTag!.startText = adjustedHtmlString.endIndex
                    adjustedHtmlString += parser.extract(textBetweenMarkdownText: markdownText, startTag: curTag, endTag: nextTag!, mode: .startToNext)
                    processingTag!.endText = adjustedHtmlString.endIndex
                } else {
                    adjustedHtmlString += parser.extract(textBetweenMarkdownText: markdownText, startTag: intermediateTag!, endTag: nextTag!, mode: .intermediateToNext)
                    processingTag!.endText = adjustedHtmlString.endIndex
                }
                let prevHandledTagSize = handledTags.count
                adjustedHtmlString += getHtmlTag(parser, markdownText: markdownText, tag: nextTag!, closingTag: false)
                adjustedHtmlString = appendHtmlString(parser, handledTags: &handledTags, htmlString: adjustedHtmlString, markdownText: markdownText, foundTags: foundTags, start: checkPosition)
                adjustedHtmlString += getHtmlTag(parser, markdownText: markdownText, tag: nextTag!, closingTag: true)
                intermediateTag = foundTags[checkPosition]
                checkPosition += handledTags.count - prevHandledTagSize
                processing = true
            } else {
                if processingTag == nil {
                    processingTag = MarkdownTag()
                    handledTags.append(processingTag!)
                    processingTag!.type = curTag.type
                    processingTag!.weight = curTag.weight
                    processingTag!.startExtra = curTag.startExtra
                    processingTag!.endExtra = curTag.endExtra
                    processingTag!.startText = adjustedHtmlString.endIndex
                    adjustedHtmlString += parser.extract(textFromMarkdownText: markdownText, tag: curTag)
                    processingTag!.endText = adjustedHtmlString.endIndex
                } else {
                    adjustedHtmlString += parser.extract(textBetweenMarkdownText: markdownText, startTag: intermediateTag!, endTag: curTag, mode: .intermediateToEnd)
                    processingTag!.endText = adjustedHtmlString.endIndex
                }
            }
        }
        return adjustedHtmlString
    }

    fileprivate static func getHtmlTag(_ parser: SimpleMarkdownParser, markdownText: String, tag: MarkdownTag, closingTag: Bool) -> String {
        var start = closingTag ? "</" : "<"
        if tag.type == .textStyle {
            switch tag.weight {
            case 1:
                start += "i"
                break
            case 2:
                start += "b"
                break
            case 3:
                if (closingTag) {
                    start += "b>" + start + "i"
                } else {
                    start += "i>" + start + "b"
                }
                break
            default:
                break // Nothing
            }
        } else if tag.type == .alternativeTextStyle {
            start += "strike"
        } else if tag.type == .header {
            var headerSize = 6
            if tag.weight >= 1 && tag.weight < 7 {
                headerSize = tag.weight
            }
            start += "h\(headerSize)"
        } else if tag.type == .orderedList || tag.type == .unorderedList {
            start += "li"
        } else if tag.type == .link {
            start += "a"
            if !closingTag {
                var linkLocation = parser.extract(extraFromMarkdownText: markdownText, tag: tag)
                if linkLocation.characters.count == 0 {
                    linkLocation = parser.extract(textFromMarkdownText: markdownText, tag: tag)
                }
                start += " href=" + linkLocation
            }
        } else {
            return ""
        }
        return start + ">"
    }

    
    // --
    // MARK: Attributed string conversion handling
    // --
    
    open static func toAttributedString(_ defaultFont: UIFont, markdownText: String) -> NSAttributedString {
        return toAttributedString(defaultFont, markdownText: markdownText, attributedStringGenerator: DefaultMarkdownAttributedStringGenerator())
    }
    
    open static func toAttributedString(_ defaultFont: UIFont, markdownText: String, attributedStringGenerator: MarkdownAttributedStringGenerator) -> NSAttributedString {
        // Handle tags and do the conversion
        let parser = obtainParser(markdownText)
        let foundTags = parser.findTags(onMarkdownText: markdownText)
        let attributedString = NSMutableAttributedString()
        var listCount: [Int] = []
        var addedParagraph = true
        var skipTags = 0
        for i in 0..<foundTags.count {
            if skipTags > 0 {
                skipTags -= 1
                continue
            }
            let sectionTag = foundTags[i]
            if !addedParagraph {
                attributedString.append(NSAttributedString(string: "\n"))
            }
            if sectionTag.type == .orderedList || sectionTag.type == .unorderedList {
                for _ in listCount.count..<sectionTag.weight {
                    listCount.append(0)
                }
                for _ in stride(from: listCount.count, to: sectionTag.weight, by: -1) {
                    listCount.remove(at: listCount.count - 1)
                }
                if sectionTag.type == .orderedList {
                    listCount[listCount.count - 1] += 1
                }
            }
            if sectionTag.type == .header || sectionTag.type == .orderedList || sectionTag.type == .unorderedList || sectionTag.type == .normal {
                var convertedTags: [MarkdownTag] = []
                var addDistance = 0
                appendAttributedString(parser, convertedTags: &convertedTags, attributedString: attributedString, markdownText: markdownText, foundTags: foundTags, start: i);
                skipTags += convertedTags.count - 1
                if sectionTag.type == .orderedList || sectionTag.type == .unorderedList {
                    var token: String? = attributedStringGenerator.getListToken(sectionTag.type, weight: sectionTag.weight, index: listCount[listCount.count - 1])
                    let start = markdownText.characters.distance(from: markdownText.startIndex, to: convertedTags[0].startText!)
                    let end = markdownText.characters.distance(from: markdownText.startIndex, to: convertedTags[0].endText!)
                    if token == nil {
                        token = ""
                    }
                    attributedString.insert(NSAttributedString(string: token!), at: markdownText.characters.distance(from: markdownText.startIndex, to: convertedTags[0].startText!))
                    addDistance = token!.characters.count
                    attributedStringGenerator.applyAttribute(defaultFont, attributedString: attributedString, type: sectionTag.type, weight: sectionTag.weight, start: start, length: end - start + addDistance, extra: token!)
                }
                for tag in convertedTags {
                    if tag.type == .orderedList || tag.type == .unorderedList {
                        continue
                    }
                    var extra = ""
                    let start = markdownText.characters.distance(from: markdownText.startIndex, to: tag.startText!)
                    let end = markdownText.characters.distance(from: markdownText.startIndex, to: tag.endText!)
                    if tag.type == .link {
                        extra = parser.extract(extraFromMarkdownText: markdownText, tag: tag)
                        if extra == "" {
                            extra = parser.extract(textFromMarkdownText: markdownText, tag: tag)
                        }
                    }
                    attributedStringGenerator.applyAttribute(defaultFont, attributedString: attributedString, type: tag.type, weight: tag.weight, start: start + addDistance, length: end - start, extra: extra);
                }
                addedParagraph = false
            } else if sectionTag.type == .paragraph {
                if sectionTag.weight > 0 {
                    let pos = attributedString.string.characters.distance(from: attributedString.string.startIndex, to: attributedString.string.endIndex)
                    attributedString.append(NSAttributedString(string: "\n"))
                    attributedStringGenerator.applyAttribute(defaultFont, attributedString: attributedString, type: .paragraph, weight: sectionTag.weight, start: pos, length: 1, extra: "")
                }
                addedParagraph = true
                listCount.removeAll()
            }
        }
        
        // Fix the attributed string by using the default font in places without a font definition (needed for clickable links for example)
        let result = NSMutableAttributedString(attributedString: attributedString)
        result.addAttribute(NSFontAttributeName, value: defaultFont, range: NSMakeRange(0, result.length))
        attributedString.enumerateAttributes(in: NSMakeRange(0, attributedString.length), options: .longestEffectiveRangeNotRequired, using: { (attributes: [String: Any], range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            result.addAttributes(attributes, range: range)
        })
        return result
    }

    fileprivate static func appendAttributedString(_ parser: SimpleMarkdownParser, convertedTags: inout [MarkdownTag], attributedString: NSMutableAttributedString, markdownText: String, foundTags: [MarkdownTag], start: Int) {
        let curTag = foundTags[start]
        var intermediateTag: MarkdownTag? = nil
        var processingTag: MarkdownTag? = nil
        var checkPosition = start + 1
        var processing = true
        while processing {
            let nextTag: MarkdownTag? = checkPosition < foundTags.count ? foundTags[checkPosition] : nil
            processing = false
            if nextTag != nil && nextTag!.startPosition! < curTag.endPosition! {
                if processingTag == nil {
                    processingTag = MarkdownTag()
                    convertedTags.append(processingTag!)
                    processingTag!.type = curTag.type
                    processingTag!.weight = curTag.weight
                    processingTag!.startExtra = curTag.startExtra
                    processingTag!.endExtra = curTag.endExtra
                    processingTag!.startText = attributedString.string.endIndex
                    attributedString.append(NSAttributedString(string: parser.extract(textBetweenMarkdownText: markdownText, startTag: curTag, endTag: nextTag!, mode: .startToNext)))
                    processingTag!.endText = attributedString.string.endIndex
                } else {
                    attributedString.append(NSAttributedString(string: parser.extract(textBetweenMarkdownText: markdownText, startTag: intermediateTag!, endTag: nextTag!, mode: .intermediateToNext)))
                    processingTag!.endText = attributedString.string.endIndex
                }
                let prevConvertedTagSize = convertedTags.count
                appendAttributedString(parser, convertedTags: &convertedTags, attributedString: attributedString, markdownText: markdownText, foundTags: foundTags, start: checkPosition)
                intermediateTag = foundTags[checkPosition]
                checkPosition += convertedTags.count - prevConvertedTagSize
                processing = true
            } else {
                if processingTag == nil {
                    processingTag = MarkdownTag()
                    convertedTags.append(processingTag!)
                    processingTag!.type = curTag.type
                    processingTag!.weight = curTag.weight
                    processingTag!.startExtra = curTag.startExtra
                    processingTag!.endExtra = curTag.endExtra
                    processingTag!.startText = attributedString.string.endIndex
                    attributedString.append(NSAttributedString(string: parser.extract(textFromMarkdownText: markdownText, tag: curTag)))
                    processingTag!.endText = attributedString.string.endIndex
                } else {
                    attributedString.append(NSAttributedString(string: parser.extract(textBetweenMarkdownText: markdownText, startTag: intermediateTag!, endTag: curTag, mode: .intermediateToEnd)))
                    processingTag!.endText = attributedString.string.endIndex
                }
            }
        }
    }
    
    
    // --
    // MARK: Obtain parser instance
    // --
    
    fileprivate static func obtainParser(_ markdownText: String) -> SimpleMarkdownParser {
        return SimpleMarkdownParserSwift()
    }

}

//
//  SimpleMarkdownConverter.swift
//  SimpleMarkdownParser Pod
//
//  Conversion library: utility class to convert markdown to HTML or attributed string
//

public class SimpleMarkdownConverter {
    
    // --
    // MARK: HTML conversion handling
    // --
    
    public static func toHtmlString(markdownText: String) -> String {
        let parser = obtainParser(markdownText)
        let foundTags = parser.findTags(markdownText)
        var htmlString = ""
        var listCount: [Int] = []
        var prevSectionType = MarkdownTagType.Paragraph
        var addedParagraph = true
        var skipTags = 0
        for i in 0..<foundTags.count {
            if skipTags > 0 {
                skipTags -= 1
                continue
            }
            let sectionTag = foundTags[i]
            if !addedParagraph && sectionTag.type == .Normal {
                htmlString += "<br/>"
            }
            if sectionTag.type == .OrderedList || sectionTag.type == .UnorderedList {
                let matchedType = sectionTag.type == .OrderedList ? 0 : 1
                if listCount.count == sectionTag.weight && listCount.count > 0 && listCount[listCount.count - 1] != matchedType {
                    htmlString += listCount[listCount.count - 1] == 0 ? "</ol>" : "</ul>"
                    listCount.removeAtIndex(listCount.count - 1)
                }
                for _ in listCount.count..<sectionTag.weight {
                    listCount.append(sectionTag.type == .OrderedList ? 0 : 1)
                    htmlString += sectionTag.type == .OrderedList ? "<ol>" : "<ul>"
                }
                for _ in listCount.count.stride(to: sectionTag.weight, by: -1) {
                    htmlString += listCount[listCount.count - 1] == 0 ? "</ol>" : "</ul>"
                    listCount.removeAtIndex(listCount.count - 1)
                }
            }
            if sectionTag.type == .Header || sectionTag.type == .OrderedList || sectionTag.type == .UnorderedList || sectionTag.type == .Normal {
                var handledTags: [MarkdownTag] = []
                htmlString += getHtmlTag(parser, markdownText: markdownText, tag: sectionTag, closingTag: false)
                htmlString = appendHtmlString(parser, handledTags: &handledTags, htmlString: htmlString, markdownText: markdownText, foundTags: foundTags, start: i)
                htmlString += getHtmlTag(parser, markdownText: markdownText, tag: sectionTag, closingTag: true)
                skipTags += handledTags.count - 1
                addedParagraph = sectionTag.type != .Normal
            } else if sectionTag.type == .Paragraph {
                let nextNormal = i + 1 < foundTags.count && foundTags[i + 1].type == .Normal
                if prevSectionType == .Normal && nextNormal {
                    for _ in 0..<sectionTag.weight + 1 {
                        htmlString += "<br/>"
                    }
                }
                addedParagraph = true
                for _ in listCount.count.stride(to: 0, by: -1) {
                    htmlString += listCount[listCount.count - 1] == 0 ? "</ol>" : "</ul>"
                    listCount.removeAtIndex(listCount.count - 1)
                }
            }
            prevSectionType = sectionTag.type
        }
        for _ in listCount.count.stride(to: 0, by: -1) {
            htmlString += listCount[listCount.count - 1] == 0 ? "</ol>" : "</ul>"
            listCount.removeAtIndex(listCount.count - 1)
        }
        return htmlString;
    }
    
    private static func appendHtmlString(parser: SimpleMarkdownParser, inout handledTags: [MarkdownTag], htmlString: String, markdownText: String, foundTags: [MarkdownTag], start: Int) -> String {
        var adjustedHtmlString = htmlString
        let curTag = foundTags[start]
        var intermediateTag: MarkdownTag? = nil
        var processingTag: MarkdownTag? = nil
        var checkPosition = start + 1
        var processing = true
        while processing {
            let nextTag: MarkdownTag? = checkPosition < foundTags.count ? foundTags[checkPosition] : nil
            processing = false
            if nextTag != nil && nextTag!.startPosition < curTag.endPosition {
                if processingTag == nil {
                    processingTag = MarkdownTag()
                    handledTags.append(processingTag!)
                    processingTag!.type = curTag.type
                    processingTag!.weight = curTag.weight
                    processingTag!.startExtra = curTag.startExtra
                    processingTag!.endExtra = curTag.endExtra
                    processingTag!.startText = adjustedHtmlString.endIndex
                    adjustedHtmlString += parser.extractTextBetween(markdownText, startTag: curTag, endTag: nextTag!, mode: .StartToNext)
                    processingTag!.endText = adjustedHtmlString.endIndex
                } else {
                    adjustedHtmlString += parser.extractTextBetween(markdownText, startTag: intermediateTag!, endTag: nextTag!, mode: .IntermediateToNext)
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
                    adjustedHtmlString += parser.extractText(markdownText, tag: curTag)
                    processingTag!.endText = adjustedHtmlString.endIndex
                } else {
                    adjustedHtmlString += parser.extractTextBetween(markdownText, startTag: intermediateTag!, endTag: curTag, mode: .IntermediateToEnd)
                    processingTag!.endText = adjustedHtmlString.endIndex
                }
            }
        }
        return adjustedHtmlString
    }

    private static func getHtmlTag(parser: SimpleMarkdownParser, markdownText: String, tag: MarkdownTag, closingTag: Bool) -> String {
        var start = closingTag ? "</" : "<"
        if tag.type == .TextStyle {
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
        } else if tag.type == .AlternativeTextStyle {
            start += "strike"
        } else if tag.type == .Header {
            var headerSize = 6
            if tag.weight >= 1 && tag.weight < 7 {
                headerSize = tag.weight
            }
            start += "h\(headerSize)"
        } else if tag.type == .OrderedList || tag.type == .UnorderedList {
            start += "li"
        } else if tag.type == .Link {
            start += "a"
            if !closingTag {
                var linkLocation = parser.extractExtra(markdownText, tag: tag)
                if linkLocation.characters.count == 0 {
                    linkLocation = parser.extractText(markdownText, tag: tag)
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
    
    public static func toAttributedString(defaultFont: UIFont, markdownText: String) -> NSAttributedString {
        return toAttributedString(defaultFont, markdownText: markdownText, attributedStringGenerator: DefaultMarkdownAttributedStringGenerator())
    }
    
    public static func toAttributedString(defaultFont: UIFont, markdownText: String, attributedStringGenerator: MarkdownAttributedStringGenerator) -> NSAttributedString {
        // Handle tags and do the conversion
        let parser = obtainParser(markdownText)
        let foundTags = parser.findTags(markdownText)
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
                attributedString.appendAttributedString(NSAttributedString(string: "\n"))
            }
            if sectionTag.type == .OrderedList || sectionTag.type == .UnorderedList {
                for _ in listCount.count..<sectionTag.weight {
                    listCount.append(0)
                }
                for _ in listCount.count.stride(to: sectionTag.weight, by: -1) {
                    listCount.removeAtIndex(listCount.count - 1)
                }
                if sectionTag.type == .OrderedList {
                    listCount[listCount.count - 1] += 1
                }
            }
            if sectionTag.type == .Header || sectionTag.type == .OrderedList || sectionTag.type == .UnorderedList || sectionTag.type == .Normal {
                var convertedTags: [MarkdownTag] = []
                var addDistance = 0
                appendAttributedString(parser, convertedTags: &convertedTags, attributedString: attributedString, markdownText: markdownText, foundTags: foundTags, start: i);
                skipTags += convertedTags.count - 1
                if sectionTag.type == .OrderedList || sectionTag.type == .UnorderedList {
                    var token: String? = attributedStringGenerator.getListToken(sectionTag.type, weight: sectionTag.weight, index: listCount[listCount.count - 1])
                    let start = markdownText.startIndex.distanceTo(convertedTags[0].startText!)
                    let end = markdownText.startIndex.distanceTo(convertedTags[0].endText!)
                    if token == nil {
                        token = ""
                    }
                    attributedString.insertAttributedString(NSAttributedString(string: token!), atIndex: markdownText.startIndex.distanceTo(convertedTags[0].startText!))
                    addDistance = token!.characters.count
                    attributedStringGenerator.applyAttribute(defaultFont, attributedString: attributedString, type: sectionTag.type, weight: sectionTag.weight, start: start, length: end - start + addDistance, extra: token!)
                }
                for tag in convertedTags {
                    if tag.type == .OrderedList || tag.type == .UnorderedList {
                        continue
                    }
                    var extra = ""
                    let start = markdownText.startIndex.distanceTo(tag.startText!)
                    let end = markdownText.startIndex.distanceTo(tag.endText!)
                    if tag.type == .Link {
                        extra = parser.extractExtra(markdownText, tag: tag)
                        if extra == "" {
                            extra = parser.extractText(markdownText, tag: tag)
                        }
                    }
                    attributedStringGenerator.applyAttribute(defaultFont, attributedString: attributedString, type: tag.type, weight: tag.weight, start: start + addDistance, length: end - start, extra: extra);
                }
                addedParagraph = false
            } else if sectionTag.type == .Paragraph {
                if sectionTag.weight > 0 {
                    let pos = attributedString.string.startIndex.distanceTo(attributedString.string.endIndex)
                    attributedString.appendAttributedString(NSAttributedString(string: "\n"))
                    attributedStringGenerator.applyAttribute(defaultFont, attributedString: attributedString, type: .Paragraph, weight: sectionTag.weight, start: pos, length: 1, extra: "")
                }
                addedParagraph = true
                listCount.removeAll()
            }
        }
        
        // Fix the attributed string by using the default font in places without a font definition (needed for clickable links for example)
        let result = NSMutableAttributedString(attributedString: attributedString)
        result.addAttribute(NSFontAttributeName, value: defaultFont, range: NSMakeRange(0, result.length))
        attributedString.enumerateAttributesInRange(NSMakeRange(0, attributedString.length), options: .LongestEffectiveRangeNotRequired, usingBlock: { (attributes: [String: AnyObject], range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            result.addAttributes(attributes, range: range)
        })
        return result
    }

    private static func appendAttributedString(parser: SimpleMarkdownParser, inout convertedTags: [MarkdownTag], attributedString: NSMutableAttributedString, markdownText: String, foundTags: [MarkdownTag], start: Int) {
        let curTag = foundTags[start]
        var intermediateTag: MarkdownTag? = nil
        var processingTag: MarkdownTag? = nil
        var checkPosition = start + 1
        var processing = true
        while processing {
            let nextTag: MarkdownTag? = checkPosition < foundTags.count ? foundTags[checkPosition] : nil
            processing = false
            if nextTag != nil && nextTag!.startPosition < curTag.endPosition {
                if processingTag == nil {
                    processingTag = MarkdownTag()
                    convertedTags.append(processingTag!)
                    processingTag!.type = curTag.type
                    processingTag!.weight = curTag.weight
                    processingTag!.startExtra = curTag.startExtra
                    processingTag!.endExtra = curTag.endExtra
                    processingTag!.startText = attributedString.string.endIndex
                    attributedString.appendAttributedString(NSAttributedString(string: parser.extractTextBetween(markdownText, startTag: curTag, endTag: nextTag!, mode: .StartToNext)))
                    processingTag!.endText = attributedString.string.endIndex
                } else {
                    attributedString.appendAttributedString(NSAttributedString(string: parser.extractTextBetween(markdownText, startTag: intermediateTag!, endTag: nextTag!, mode: .IntermediateToNext)))
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
                    attributedString.appendAttributedString(NSAttributedString(string: parser.extractText(markdownText, tag: curTag)))
                    processingTag!.endText = attributedString.string.endIndex
                } else {
                    attributedString.appendAttributedString(NSAttributedString(string: parser.extractTextBetween(markdownText, startTag: intermediateTag!, endTag: curTag, mode: .IntermediateToEnd)))
                    processingTag!.endText = attributedString.string.endIndex
                }
            }
        }
    }
    
    
    // --
    // MARK: Obtain parser instance
    // --
    
    private static func obtainParser(markdownText: String) -> SimpleMarkdownParser {
        return SimpleMarkdownParserSwift()
    }

}

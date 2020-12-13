//
//  MarkdownLinkTouchAreaFinder.swift
//  SimpleMarkdownParser Pod
//
//  Library clickable link support: find and stores all clickable links in an attributed string of a label
//

public class MarkdownLinkTouchAreaFinder {
    
    // --
    // MARK: Members
    // --
    
    public var touchAreas = [MarkdownLinkTouchArea]()
    private(set) weak var label: UILabel?
    private weak var storedForAttributedString: NSAttributedString?
    private var storedForTextAlignment = NSTextAlignment.left
    private var storedForLineBreakMode = NSLineBreakMode.byWordWrapping
    private var storedForNumberOfLines = 0
    private var storedForSize = CGSize.zero
    

    // --
    // MARK: Initialization
    // --

    public init(label: UILabel) {
        self.label = label
    }
    

    // --
    // MARK: Touch area checking
    // --
    
    public func getClosestTouchArea(point: CGPoint, extendRange: CGFloat = 0) -> MarkdownLinkTouchArea? {
        // First try to find an exact match
        for touchArea in touchAreas {
            for rect in touchArea.touchRects {
                if rect.contains(point) {
                    return touchArea
                }
            }
        }
        
        // Find closest match if the range is extended
        var closestMatch: MarkdownLinkTouchArea?
        var closestMatchDistance = CGFloat.infinity
        if extendRange > 0 {
            for touchArea in touchAreas {
                for rect in touchArea.touchRects {
                    let enlargedRect = rect.insetBy(dx: -extendRange, dy: -extendRange)
                    if enlargedRect.contains(point) {
                        let largestDistance = max(max(rect.minX - point.x, point.x - rect.maxX), max(rect.minY - point.y, point.y - rect.maxY))
                        if largestDistance < closestMatchDistance {
                            closestMatch = touchArea
                            closestMatchDistance = largestDistance
                        }
                    }
                }
            }
        }
        return closestMatch
    }
    
    public func inTouchArea(touchArea: MarkdownLinkTouchArea, point: CGPoint, extendRange: CGFloat = 0) -> Bool {
        for rect in touchArea.touchRects {
            let checkRect = extendRange > 0 ? rect.insetBy(dx: -extendRange, dy: -extendRange) : rect
            if checkRect.contains(point) {
                return true
            }
        }
        return false
    }
    

    // --
    // MARK: Touch area finder
    // --
    
    public func findTouchAreas(overrideAttributedText: NSAttributedString? = nil) {
        let useAttributedText = overrideAttributedText ?? label?.attributedText
        touchAreas = []
        if let label = label, let attributedText = useAttributedText {
            // First re-initialize state for checking validity
            storedForAttributedString = attributedText
            storedForTextAlignment = label.textAlignment
            storedForLineBreakMode = label.lineBreakMode
            storedForNumberOfLines = label.numberOfLines
            storedForSize = label.bounds.size

            // Set up text storage and apply text alignment if needed
            let textStorage = NSTextStorage(attributedString: attributedText)
            if label.textAlignment != .left {
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = label.textAlignment
                textStorage.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, attributedText.length))
            }
            
            // Create instances of NSLayoutManager and NSTextContainer, then link them
            let labelSize = label.bounds.size
            let layoutManager = NSLayoutManager()
            let textContainer = NSTextContainer(size: labelSize)
            layoutManager.addTextContainer(textContainer)
            textStorage.addLayoutManager(layoutManager)
            
            // Configure textContainer
            textContainer.lineFragmentPadding = 0.0
            textContainer.lineBreakMode = label.lineBreakMode
            textContainer.maximumNumberOfLines = label.numberOfLines
            
            // Calculate offset
            let textBoundingBox = layoutManager.usedRect(for: textContainer)
            let textVerticalOffset = (labelSize.height - textBoundingBox.size.height) * 0.5
            
            // Find link attributes and create touch areas
            attributedText.enumerateAttributes(in: NSMakeRange(0, attributedText.length), options: .longestEffectiveRangeNotRequired, using: { (attributes: [NSAttributedString.Key: Any], range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
                // Find properties
                var url: URL?
                var highlightColor: UIColor?
                var foregroundColor: UIColor?
                for (key, value) in attributes {
                    if key.rawValue == NSClickableTextAttributeName || key == .link {
                        if value is URL {
                            url = value as? URL
                        } else {
                            url = URL(string: value as? String ?? "")
                        }
                    } else if key.rawValue == NSHighlightColorAttributeName {
                        highlightColor = value as? UIColor
                    } else if key == .foregroundColor {
                        foregroundColor = value as? UIColor
                    }
                }
                
                // Create touch area
                if let url = url, let highlightColor = highlightColor ?? foregroundColor?.withAlphaComponent(0.25) {
                    // Determine glyph rectangles (combine if possible)
                    var glyphRects = [CGRect]()
                    for i in range.lowerBound..<range.upperBound {
                        let glyphsForIndex = layoutManager.glyphRange(forCharacterRange: NSMakeRange(i, 1), actualCharacterRange: nil)
                        let characterBounds = layoutManager.boundingRect(forGlyphRange: glyphsForIndex, in: textContainer)
                        var foundRect = false
                        for j in glyphRects.indices {
                            if glyphRects[j].minY == characterBounds.minY {
                                glyphRects[j] = glyphRects[j].union(characterBounds)
                                foundRect = true
                                break
                            }
                        }
                        if !foundRect {
                            glyphRects.append(characterBounds)
                        }
                    }
                    
                    // Append touch area
                    if glyphRects.count > 0 {
                        let touchRects = glyphRects.map { $0.offsetBy(dx: 0, dy: textVerticalOffset) }
                        let string = attributedText.string
                        let linkText = string[string.index(string.startIndex, offsetBy: range.location)..<string.index(string.startIndex, offsetBy: range.location + range.length)]
                        touchAreas.append(MarkdownLinkTouchArea(touchRects: touchRects, attributeRange: range, highlightColor: highlightColor, url: url, linkText: String(linkText)))
                    }
                }
            })
        }
    }
    
    public func touchAreasValid(skipAttributedTextCheck: Bool = false) -> Bool {
        if let label = label {
            return label.textAlignment == storedForTextAlignment && label.lineBreakMode == storedForLineBreakMode && label.numberOfLines == storedForNumberOfLines && label.bounds.size == storedForSize && (skipAttributedTextCheck || label.attributedText == storedForAttributedString)
        }
        return false
    }

}

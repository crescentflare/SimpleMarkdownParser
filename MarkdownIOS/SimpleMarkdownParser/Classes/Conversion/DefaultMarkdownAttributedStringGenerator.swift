//
//  DefaultMarkdownAttributedStringGenerator.swift
//  SimpleMarkdownParser Pod
//
//  Conversion library: default implementation of the attributed string generator
//

// Parser class
open class DefaultMarkdownAttributedStringGenerator : MarkdownAttributedStringGenerator {
    
    // --
    // MARK: Default initializer
    // --

    public init() {
    }

    
    // --
    // MARK: Implementation
    // --
    
    open func applyAttribute(defaultFont: UIFont, attributedString: NSMutableAttributedString, type: MarkdownTagType, weight: Int, start: Int, length: Int, extra: String) {
        switch type {
        case .header:
            if let descriptor = defaultFont.fontDescriptor.withSymbolicTraits(.traitBold) {
                attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.init(descriptor: descriptor, size: defaultFont.pointSize * DefaultMarkdownAttributedStringGenerator.sizeForHeader(weight)), range: NSMakeRange(start, length))
            }
        case .orderedList, .unorderedList:
            let bulletParagraph = NSMutableParagraphStyle()
            let tokenTabStop = NSTextTab(textAlignment: .right, location: 25 + CGFloat(weight - 1) * 15, options: [:])
            let textTabStop = NSTextTab(textAlignment: .left, location: tokenTabStop.location + 5, options: [:])
            bulletParagraph.tabStops = [ tokenTabStop, textTabStop ]
            bulletParagraph.firstLineHeadIndent = 0
            bulletParagraph.headIndent = textTabStop.location
            attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value: bulletParagraph, range: NSMakeRange(start, length))
        case .textStyle:
            var deriveFont = defaultFont
            attributedString.enumerateAttributes(in: NSMakeRange(start, length), options: .longestEffectiveRangeNotRequired, using: { (attributes: [NSAttributedString.Key: Any], range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
                if let font = attributes[NSAttributedString.Key.font] as? UIFont {
                    deriveFont = font
                }
            })
            if let font = DefaultMarkdownAttributedStringGenerator.fontForWeight(deriveFont, weight: weight) {
                attributedString.addAttribute(NSAttributedString.Key.font, value: font, range: NSMakeRange(start, length))
            }
        case .alternativeTextStyle:
            attributedString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: true, range: NSMakeRange(start, length))
        case .link:
            if let url = URL(string: extra) {
                attributedString.addAttribute(NSAttributedString.Key(rawValue: NSClickableTextAttributeName), value: url, range: NSMakeRange(start, length))
                attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.blue, range: NSMakeRange(start, length))
                attributedString.addAttribute(NSAttributedString.Key(rawValue: NSHighlightColorAttributeName), value: UIColor.red, range: NSMakeRange(start, length))
                attributedString.addAttribute(NSAttributedString.Key.underlineStyle, value: 1, range: NSMakeRange(start, length))
            }
        default:
            break //No implementation for unknown tags
        }
    }
    
    open func applySectionSpacerAttribute(defaultFont: UIFont, attributedString: NSMutableAttributedString, previousSectionType: MarkdownTagType, previousSectionWeight: Int, nextSectionType: MarkdownTagType, nextSectionWeight: Int, start: Int, length: Int) {
        let spacing: CGFloat = nextSectionType == .header && previousSectionType != .header ? 16 : 8
        attributedString.addAttribute(NSAttributedString.Key.font, value: defaultFont.withSize(spacing), range: NSMakeRange(start, length))
    }
    
    open func getListToken(fromType: MarkdownTagType, weight: Int, index: Int) -> String {
        if fromType == .line {
            return "\t\t"
        }
        let token = fromType == .orderedList ? "\(index)." : DefaultMarkdownAttributedStringGenerator.bulletTokenForWeight(weight)
        return "\t\(token)\t"
    }


    // --
    // MARK: Helper
    // --

    private static func sizeForHeader(_ weight: Int) -> CGFloat {
        if weight >= 1 && weight < 6 {
            return 1.5 - CGFloat(weight - 1) * 0.1
        }
        return 1
    }

    private static func fontForWeight(_ defaultFont: UIFont, weight: Int) -> UIFont? {
        var traits: UIFontDescriptor.SymbolicTraits = UIFontDescriptor.SymbolicTraits()
        traits.insert(defaultFont.fontDescriptor.symbolicTraits)
        switch (weight) {
        case 1:
            traits.insert(.traitItalic)
        case 2:
            traits.insert(.traitBold)
        case 3:
            traits.insert(.traitItalic)
            traits.insert(.traitBold)
        default:
            break // Will return the default value below
        }
        if let descriptor = defaultFont.fontDescriptor.withSymbolicTraits(traits) {
            return UIFont.init(descriptor: descriptor, size: defaultFont.pointSize)
        }
        return nil
    }

    private static func bulletTokenForWeight(_ weight: Int) -> String {
        if (weight == 2) {
            return "◦"
        } else if (weight >= 3) {
            return "▪"
        }
        return "•"
    }

}

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
    // MARK: Implementations
    // --
    
    open func applyAttribute(defaultFont: UIFont, attributedString: NSMutableAttributedString, type: MarkdownTagType, weight: Int, start: Int, length: Int, extra: String) {
        switch type {
        case .paragraph:
            attributedString.addAttribute(NSAttributedString.Key.font, value: defaultFont.withSize(defaultFont.pointSize * CGFloat(weight)), range: NSMakeRange(start, length))
            break
        case .header:
            attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.init(descriptor: defaultFont.fontDescriptor.withSymbolicTraits(.traitBold)!, size: defaultFont.pointSize * DefaultMarkdownAttributedStringGenerator.sizeForHeader(weight)), range: NSMakeRange(start, length))
            break
        case .orderedList, .unorderedList:
            let bulletParagraph = NSMutableParagraphStyle()
            let tokenTabStop = NSTextTab(textAlignment: .right, location: 25 + CGFloat(weight - 1) * 15, options: [:])
            let textTabStop = NSTextTab(textAlignment: .left, location: tokenTabStop.location + 5, options: [:])
            bulletParagraph.tabStops = [ tokenTabStop, textTabStop ]
            bulletParagraph.firstLineHeadIndent = 0
            bulletParagraph.headIndent = textTabStop.location
            attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value: bulletParagraph, range: NSMakeRange(start, length))
            break
        case .textStyle:
            var deriveFont = defaultFont
            attributedString.enumerateAttributes(in: NSMakeRange(start, length), options: .longestEffectiveRangeNotRequired, using: { (attributes: [NSAttributedString.Key: Any], range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
                if let font = attributes[NSAttributedString.Key.font] as? UIFont {
                    deriveFont = font
                }
            })
            attributedString.addAttribute(NSAttributedString.Key.font, value: DefaultMarkdownAttributedStringGenerator.fontForWeight(deriveFont, weight: weight), range: NSMakeRange(start, length))
            break
        case .alternativeTextStyle:
            attributedString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: true, range: NSMakeRange(start, length))
            break
        case .link:
            attributedString.addAttribute(NSAttributedString.Key(rawValue: NSClickableTextAttributeName), value: URL(string: extra)!, range: NSMakeRange(start, length))
            attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.blue, range: NSMakeRange(start, length))
            attributedString.addAttribute(NSAttributedString.Key.underlineStyle, value: 1, range: NSMakeRange(start, length))
            break
        default:
            break //No implementation for unknown tags
        }
    }
    
    open func getListToken(fromType: MarkdownTagType, weight: Int, index: Int) -> String {
        let token = fromType == .orderedList ? "\(index)." : DefaultMarkdownAttributedStringGenerator.bulletTokenForWeight(weight)
        return "\t\(token)\t"
    }

    private static func sizeForHeader(_ weight: Int) -> CGFloat {
        if weight >= 1 && weight < 6 {
            return 1.5 - CGFloat(weight - 1) * 0.1
        }
        return 1
    }

    private static func fontForWeight(_ defaultFont: UIFont, weight: Int) -> UIFont {
        var traits: UIFontDescriptor.SymbolicTraits = UIFontDescriptor.SymbolicTraits()
        traits.insert(defaultFont.fontDescriptor.symbolicTraits)
        switch (weight) {
        case 1:
            traits.insert(.traitItalic)
            break
        case 2:
            traits.insert(.traitBold)
            break
        case 3:
            traits.insert(.traitItalic)
            traits.insert(.traitBold)
            break
        default:
            break // Will return the default value below
        }
        return UIFont.init(descriptor: defaultFont.fontDescriptor.withSymbolicTraits(traits)!, size: defaultFont.pointSize)
    }

    private static func bulletTokenForWeight(_ weight: Int) -> String {
        if (weight == 2) {
            return "◦ "
        } else if (weight >= 3) {
            return "▪ "
        }
        return "• "
    }

}

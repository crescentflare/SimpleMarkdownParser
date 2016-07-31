//
//  DefaultMarkdownAttributedStringGenerator.swift
//  SimpleMarkdownParser Pod
//
//  Conversion library: default implementation of the attributed string generator
//

// Parser class
public class DefaultMarkdownAttributedStringGenerator : MarkdownAttributedStringGenerator {
    
    // --
    // MARK: Default initializer
    // --

    public init() {
    }

    
    // --
    // MARK: Implementations
    // --
    
    public func applyAttribute(defaultFont: UIFont, attributedString: NSMutableAttributedString, type: MarkdownTagType, weight: Int, start: Int, length: Int, extra: String) {
        switch type {
        case .Paragraph:
            attributedString.addAttribute(NSFontAttributeName, value: defaultFont.fontWithSize(defaultFont.pointSize * CGFloat(weight)), range: NSMakeRange(start, length))
            break
        case .Header:
            attributedString.addAttribute(NSFontAttributeName, value: UIFont.init(descriptor: defaultFont.fontDescriptor().fontDescriptorWithSymbolicTraits(.TraitBold), size: defaultFont.pointSize * DefaultMarkdownAttributedStringGenerator.sizeForHeader(weight)), range: NSMakeRange(start, length))
            break
        case .OrderedList, .UnorderedList:
            let bulletParagraph = NSMutableParagraphStyle()
            let tokenTabStop = NSTextTab(textAlignment: .Right, location: 25 + CGFloat(weight - 1) * 15, options: [:])
            let textTabStop = NSTextTab(textAlignment: .Left, location: tokenTabStop.location + 5, options: [:])
            bulletParagraph.tabStops = [ tokenTabStop, textTabStop ]
            bulletParagraph.firstLineHeadIndent = 0
            bulletParagraph.headIndent = textTabStop.location
            attributedString.addAttribute(NSParagraphStyleAttributeName, value: bulletParagraph, range: NSMakeRange(start, length))
            break
        case .TextStyle:
            var deriveFont = defaultFont
            attributedString.enumerateAttributesInRange(NSMakeRange(start, length), options: .LongestEffectiveRangeNotRequired, usingBlock: { (attributes: [String: AnyObject], range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
                if let font = attributes["NSFont"] as? UIFont {
                    deriveFont = font
                }
            })
            attributedString.addAttribute(NSFontAttributeName, value: DefaultMarkdownAttributedStringGenerator.fontForWeight(deriveFont, weight: weight), range: NSMakeRange(start, length))
            break
        case .AlternativeTextStyle:
            attributedString.addAttribute(NSStrikethroughStyleAttributeName, value: true, range: NSMakeRange(start, length))
            break
        case .Link:
            attributedString.addAttribute(NSLinkAttributeName, value: NSURL(string: extra)!, range: NSMakeRange(start, length))
            break
        default:
            break //No implementation for unknown tags
        }
    }
    
    public func getListToken(type: MarkdownTagType, weight: Int, index: Int) -> String {
        let token = type == .OrderedList ? "\(index)." : DefaultMarkdownAttributedStringGenerator.bulletTokenForWeight(weight)
        return "\t\(token)\t"
    }

    private static func sizeForHeader(weight: Int) -> CGFloat {
        if weight >= 1 && weight < 6 {
            return 1.5 - CGFloat(weight - 1) * 0.1
        }
        return 1
    }

    private static func fontForWeight(defaultFont: UIFont, weight: Int) -> UIFont {
        var traits: UIFontDescriptorSymbolicTraits = UIFontDescriptorSymbolicTraits()
        traits.insert(defaultFont.fontDescriptor().symbolicTraits)
        switch (weight) {
        case 1:
            traits.insert(.TraitItalic)
            break
        case 2:
            traits.insert(.TraitBold)
            break
        case 3:
            traits.insert(.TraitItalic)
            traits.insert(.TraitBold)
            break
        default:
            break // Will return the default value below
        }
        return UIFont.init(descriptor: defaultFont.fontDescriptor().fontDescriptorWithSymbolicTraits(traits), size: defaultFont.pointSize)
    }

    private static func bulletTokenForWeight(weight: Int) -> String {
        if (weight == 2) {
            return "◦ "
        } else if (weight >= 3) {
            return "▪ "
        }
        return "• "
    }

}
